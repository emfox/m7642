#!/bin/bash
# Arm or disarm the mainline boot test on the m7642 TV.
#
#   boottest.sh show      what is in the recovery slot right now
#   boottest.sh arm       write our image into recovery, set BCB=boot-recovery
#   boottest.sh disarm    restore the factory recovery head and the misc sector
#   boottest.sh reboot    reboot into recovery (the test itself)
#   boottest.sh prep      print the rescue-stick recipe and verify the packages
#
# The image goes into the *recovery* slot, never into boot: a failed boot
# leaves Android untouched, and the slot can be restored from Android as long
# as Android still runs.
#
# ★ But arm also writes BCB=boot-recovery, and mboot treats that as sticky:
# recovery's init is what clears it, so if the kernel never runs, the marker
# stays and every power-on goes back to the dead slot.  Android is intact yet
# unreachable.  There is no software way out of that loop -- only a rescue
# stick.  Hence arm refuses to run unless I_HAVE_RESCUE_STICK=1.
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
# Full rescue (misc + dtb + recovery + boot), and a 20 KB package that only
# wipes misc -- enough to break the BCB loop in about one second.
RESCUE=${RESCUE:-/home/emfox/kbuild/backup/fix/rescue-fast.bin}
UNSTICK=${UNSTICK:-/home/emfox/kbuild/rescue/partial/m7642-misc-stock.bin}
STICK_NAME=V8-T652T03-LF1V147.bin
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

# Refuse to arm without a rescue stick ready.  This is the one gate that has
# already cost a full evening: arm makes the slot unbootable *and* makes the
# BCB sticky in the same step, so a failure needs physical media.
require_rescue_ready() {
    [ -f "$RESCUE" ] || die "rescue package missing: $RESCUE"
    [ "${I_HAVE_RESCUE_STICK:-0}" = 1 ] || die \
"refusing to arm: this writes BCB=boot-recovery, which mboot only clears when
recovery's init runs.  If our kernel never runs, Android becomes unreachable
and only a rescue stick gets it back.

prepare the stick first (boottest.sh prep), then re-run with:

    I_HAVE_RESCUE_STICK=1 $0 arm"
    say "rescue stick: confirmed present by operator"
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
    require_rescue_ready
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
# arming overwrites rec.head.bin unconditionally.  If what is there now is the
# factory image, keep a second copy under a name arm never touches, so a
# mis-timed second arm cannot destroy the only rollback that matters.
if [ -f $W/rec.head.bin ]; then
    cur=\$(md5sum $W/rec.head.bin | cut -d' ' -f1)
    if [ "\$cur" = "0f6e1705f077935e1c3018973e658bfa" ]; then
        cp $W/rec.head.bin $W/rec.head.factory.bin 2>/dev/null
        echo "note: kept the factory rollback as rec.head.factory.bin"
    fi
fi
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
    say "note: if the slot does not come up, adb is gone for good here --"
    say "      recovery only: rescue stick with $STICK_NAME"
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

cmd_prep() {
    local n
    say "rescue packages"
    for n in "$RESCUE" "$UNSTICK"; do
        if [ -f "$n" ]; then
            say "  present $(basename "$n")  $(stat -c %s "$n") bytes  $(md5sum "$n" | cut -d' ' -f1)"
        else
            say "  MISSING $(basename "$n")"
        fi
    done
    say ""
    say "stick recipe (FAT32, root directory, exactly one .bin)"
    say "  1. copy $RESCUE"
    say "  2. rename it to $STICK_NAME   (mboot matches prefix 'V8-' + '.bin';"
    say "     'MstarUpgrade.bin' alone is never read)"
    say "  3. power off the TV, unplug the mains, wait 10 s"
    say "  4. hold the body power button, plug the mains back in, keep holding"
    say "     10-15 s until the progress bar appears, then release"
    say "  5. it stops in standby; press power to boot Android"
    say "  6. restore MstarUpgrade_complete=1 afterwards (rescue does not set it)"
    say ""
    say "the 20 KB $UNSTICK only wipes misc: enough to break the BCB loop"
    say "in about a second, but it leaves our image in the recovery slot."
}

case "${1:-}" in
show)   cmd_show ;;
arm)    cmd_arm ;;
disarm) cmd_disarm ;;
reboot) cmd_reboot ;;
prep)   cmd_prep ;;
*)      say "usage: $0 {show|arm|disarm|reboot|prep}"; exit 1 ;;
esac
