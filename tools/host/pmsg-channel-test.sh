#!/bin/bash
# ⚠️ DO NOT RUN AGAIN.  Already done once on 2026-11-21 and it worked:
#
#     pmsg-ramoops-0  35 B  "M7642PROBE\nM7642PMSG1M7642PMSGCHANn"
#     console-ramoops 57554 B of panic log
#
# It ends with `echo c > /proc/sysrq-trigger`, which discipline.md §2 forbids:
# ro.boot.bootreason came back as "kernel_panic,sysrq", i.e. panic -> panic=0
# hang -> wdt_enable 10 hard reset, another unclean shutdown for /data.  The
# device survived (ext4 errors_count=0) but the 2026-11-20 sysrq run did not.
#
# The pmsg channel needs none of this anyway: the factory kernel does ramoops
# init during its own boot, so a record written by a probe is exported in the
# same boot.  Kept only as the record of what produced §十三 in
# Documentation/mstar/m7642/wdt-beacon.md.
#
# End-to-end test of the pstore/pmsg export channel, without touching the boot
# slot.
#
# The planned early-boot probe writes a valid persistent_ram header into the
# pmsg zone (0x419c0000) and then lets the kernel crash; the *next* boot's
# ramoops init calls save_old() on that zone and pstore exports it as
# /sys/fs/pstore/pmsg-ramoops-0.  This script reproduces exactly that sequence
# using the running kernel's own /dev/pmsg0 (which builds the same header) plus
# a sysrq crash, so the whole chain is validated with zero risk to the boot
# slot.
#
#   before : zone holds whatever earlier writes left, ring header sig = DBGC
#   test   : append a marker through /dev/pmsg0, crash with sysrq c
#   after  : console-ramoops should hold the crash log (proves DDR survived the
#            reset), pmsg-ramoops-0 should hold our marker (proves the pmsg
#            zone is exported at all)
set -u

if [ "${I_KNOW_THE_RISK:-}" != 1 ]; then
    echo "refusing to run: this script crashes the device with sysrq;" >&2
    echo "read the header first, and see discipline.md section 2" >&2
    exit 1
fi

ADB=${ADB:-/home/emfox/Debian/tv/adb/platform-tools/adb}
TV=${TV:-192.168.10.60:5555}
KO=${KO:-/home/emfox/Debian/m7642/probes/probeRW/probeRW.ko}
W=/data/local/tmp
MARK=M7642PMSGCHAN

say() { printf '%s\n' "$*"; }
die() { printf 'error: %s\n' "$*" >&2; exit 1; }

adbsh() { "$ADB" -s "$TV" shell "$@" 2>/dev/null | tr -d '\r'; }

# Read raw DDR through the running kernel (ioremap, uncached).
raw() {
    adbsh "su -c 'rm -f $W/probeRW.out; rmmod probeRW 2>/dev/null; insmod $W/probeRW.ko addr=$1 len=$2 op=r; rmmod probeRW'" >/dev/null
    adbsh "su -c 'cat $W/probeRW.out'"
}

wait_boot() {
    local i
    for i in $(seq 1 60); do
        "$ADB" connect "$TV" >/dev/null 2>&1
        if [ "$(adbsh getprop sys.boot_completed)" = 1 ]; then
            return 0
        fi
        sleep 3
    done
    return 1
}

say "== connect"
"$ADB" connect "$TV" >/dev/null 2>&1
[ "$(adbsh getprop sys.boot_completed)" = 1 ] || die "device not booted"

say "== push probeRW"
"$ADB" -s "$TV" push "$KO" "$W/probeRW.ko" >/dev/null || die "push failed"

say "== pmsg zone before"
raw 0x419c0000 32

say "== append marker through /dev/pmsg0"
adbsh "su -c 'printf $MARK\\n > /dev/pmsg0; echo write_rc=\$?'"

say "== pmsg zone after write"
raw 0x419c0000 48

say "== pstore before crash"
adbsh "su -c 'ls -l /sys/fs/pstore/'"

say "== crash (sysrq c) -- device will reboot"
adbsh "su -c 'sync; echo c > /proc/sysrq-trigger'" >/dev/null
sleep 5

say "== waiting for boot (up to 180 s)"
wait_boot || die "device did not come back"

say "== pstore after crash"
adbsh "su -c 'ls -l /sys/fs/pstore/'"

for f in console-ramoops pmsg-ramoops-0; do
    say ""
    say "---- $f (first 400 bytes)"
    adbsh "su -c 'head -c 400 /sys/fs/pstore/$f 2>&1'" | tr -c '[:print:]\n' '.'
done

say ""
say "---- marker search"
adbsh "su -c 'grep -l $MARK /sys/fs/pstore/* 2>/dev/null'"
say "---- pmsg zone after reboot"
raw 0x419c0000 48
