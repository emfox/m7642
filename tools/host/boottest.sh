#!/bin/bash
# Arm or disarm the mainline boot test on the m7642 TV.
#
#   boottest.sh show      what is in the recovery slot right now
#   boottest.sh arm       write our image into recovery, set BCB=boot-recovery
#   boottest.sh disarm    restore the factory recovery head and the misc sector
#   boottest.sh reboot    reboot into recovery (the test itself)
#
# The image goes into the *recovery* slot, never into boot: a failed boot
# leaves Android untouched, and the slot can be restored from Android as long
# as Android still runs.
#
# Privileges: /factory/su gives uid 0 but CapEff=0 and cannot open block
# devices, so every block operation runs through the tvroot service.
#
# That service is fire-and-forget: it polls /data/local/tmp/tvroot.cmd and
# writes its output to a fixed path.  A naive "wait for the output file" can
# read a previous run's output, so every job starts with a unique token line
# that the host verifies before trusting anything.
set -u

ADB=${ADB:-/home/emfox/Debian/tv/adb/platform-tools/adb}
TV=${TV:-192.168.10.60:5555}
IMG=${IMG:-/home/emfox/kbuild/m7642-out/m7642-boot.img}
W=/data/local/tmp
MISC=/dev/block/by-name/misc
REC=/dev/block/by-name/recovery
JOB=$W/boottest.job
OUT=$W/boottest.out
CMD=$W/tvroot.cmd

say() { printf '%s\n' "$*"; }
die() { printf 'error: %s\n' "$*" >&2; exit 1; }
dev() { "$ADB" -s "$TV" shell "$@"; }

check_device() {
    "$ADB" connect "$TV" >/dev/null 2>&1
    [ "$(dev getprop sys.boot_completed 2>/dev/null | tr -d '\r')" = 1 ] || die "device not booted"
    say "device up $(dev 'cut -d. -f1 /proc/uptime' | tr -d '\r')s"
}

# Rewrite the command channel to a no-op so a stale command cannot fire later.
quiesce() {
    dev "echo true > $CMD" >/dev/null 2>&1
    sleep 1
}

# Run one privileged script body (read from stdin) and print its output.
# The body must not print binary data: a NUL would truncate the capture.
run_root() {
    local token n i body
    # Read the body first: adb shell inherits stdin and would swallow a heredoc
    # that is still attached to it.
    body=$(cat)
    [ -n "$body" ] || die "empty job body"
    token="tok$(date +%s)$$"
    quiesce
    dev "rm -f $OUT" >/dev/null 2>&1
    if dev "test -f $OUT" >/dev/null 2>&1; then
        die "cannot clear $OUT -- refusing to guess which run produced it"
    fi

    printf 'echo %s\n%s\necho EXIT=$?\n' "$token" "$body" > /tmp/boottest.job
    "$ADB" -s "$TV" push /tmp/boottest.job "$JOB" >/dev/null 2>&1 || die "push job"
    dev "echo \"sh $JOB > $OUT 2>&1; chmod 644 $OUT\" > $CMD" >/dev/null 2>&1 || die "cannot trigger job"

    for i in $(seq 1 90); do
        sleep 1
        n=$(dev "grep -c '^EXIT=' $OUT 2>/dev/null" | tr -d '\r')
        [ "${n:-0}" = 1 ] || continue
        dev "cat $OUT" > /tmp/boottest.out
        quiesce
        if ! head -1 /tmp/boottest.out | grep -qx "$token"; then
            die "output is not from this run (token mismatch) -- inspect $OUT on the device"
        fi
        tail -n +2 /tmp/boottest.out
        return 0
    done
    die "job did not finish in 90 s"
}

cmd_show() {
    check_device
    run_root <<'EOF'
echo "recovery slot, first 32 bytes:"
dd if=/dev/block/by-name/recovery bs=4096 count=1 2>/dev/null | head -c 32 | od -A d -t x1
n=$(wc -c < /data/local/tmp/rec.head.bin 2>/dev/null || echo 0)
if [ "$n" -gt 0 ]; then
    echo "rollback file on device: $n bytes"
    md5sum /data/local/tmp/rec.head.bin
else
    echo "no rollback file: the slot is factory content"
fi
echo "BCB:"
dd if=/dev/block/by-name/misc bs=1 count=16 2>/dev/null | od -A n -t c
echo
EOF
}

cmd_arm() {
    check_device
    [ -f "$IMG" ] || die "image missing: $IMG"
    local sz want got blocks
    sz=$(stat -c %s "$IMG")
    want=$(md5sum "$IMG" | cut -d' ' -f1)
    blocks=$(( (sz + 4095) / 4096 ))
    say "image $IMG  $sz bytes  md5 $want"

    "$ADB" -s "$TV" push "$IMG" "$W/k564.img" >/dev/null 2>&1 || die "push image"
    got=$(dev "md5sum $W/k564.img" | cut -d' ' -f1 | tr -d '\r')
    [ "$want" = "$got" ] || die "image on device is $got, expected $want"

    run_root <<EOF || die "arm failed"
dd if=$REC of=$W/rec.head.bin bs=4096 count=$blocks 2>/dev/null
dd if=$MISC of=$W/misc.head.bin bs=4096 count=1 2>/dev/null
echo -n "rollback recovery md5  "; md5sum $W/rec.head.bin
echo -n "rollback misc     md5  "; md5sum $W/misc.head.bin
dd if=$W/k564.img of=$REC bs=4096 2>/dev/null
sync
echo -n "slot now          md5  "
dd if=$REC bs=4096 count=$blocks 2>/dev/null | head -c $sz | md5sum
printf 'boot-recovery' > $W/bcb.new
dd if=$W/bcb.new of=$MISC bs=512 count=1 2>/dev/null
sync
echo -n "BCB now                "
dd if=$MISC bs=1 count=16 2>/dev/null | od -A n -t c
echo
EOF
    say "armed: 'boottest.sh reboot' to try it, 'boottest.sh disarm' to back out"
}

cmd_disarm() {
    check_device
    run_root <<'EOF' || die "disarm failed"
if [ -f /data/local/tmp/rec.head.bin ]; then
    dd if=/data/local/tmp/rec.head.bin of=/dev/block/by-name/recovery bs=4096 2>/dev/null
    sync
    echo -n "restored recovery md5  "; md5sum /data/local/tmp/rec.head.bin
    echo -n "slot now          md5  "
    n=$(wc -c < /data/local/tmp/rec.head.bin)
    dd if=/dev/block/by-name/recovery bs=4096 count=$((n / 4096)) 2>/dev/null | md5sum
else
    echo "no rollback file: recovery slot left alone"
fi
if [ -f /data/local/tmp/misc.head.bin ]; then
    dd if=/data/local/tmp/misc.head.bin of=/dev/block/by-name/misc bs=4096 count=1 2>/dev/null
    sync
    echo -n "restored misc     md5  "; md5sum /data/local/tmp/misc.head.bin
    echo
fi
echo -n "BCB now                "
dd if=/dev/block/by-name/misc bs=1 count=16 2>/dev/null | od -A n -t c
echo
EOF
}

cmd_reboot() {
    check_device
    say "rebooting into recovery"
    "$ADB" -s "$TV" reboot recovery
}

case "${1:-}" in
show)   cmd_show ;;
arm)    cmd_arm ;;
disarm) cmd_disarm ;;
reboot) cmd_reboot ;;
*)      say "usage: $0 {show|arm|disarm|reboot}"; exit 1 ;;
esac
