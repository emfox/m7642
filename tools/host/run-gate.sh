#!/bin/bash
# Gate test: can a pre-kernel probe leave a record in the ramoops hole that
# survives the 10 s WDT reset and is readable from the following Android boot?
#
# The blob writes the ramoops pmsg record (as fs/pstore/ram_core.c expects) and
# then hangs.  10 s later the watchdog warm-resets into bootcmd -> Android.  If
# the record is still there, both unknowns are answered at once: EL2 can write
# 0x419c0000, and DRAM survives the reset.
set -u
ADB=${ADB:-/home/emfox/Debian/tv/adb/platform-tools/adb}
TV=${TV:-192.168.10.60:5555}
IMG=${IMG:-/home/emfox/Debian/m7642-build/out/m7642-rec-handoff1-hang.img}
T=/home/emfox/Debian/m7642/tools/host/envtool.py
W=/data/local/tmp
IMG_MD5=4cdbc794195c44bf964639d0eaf0c9fd
FACTORY=7c2f467bbda49053951c0ce547d11a00
RC='mmc erase.p misc; mmc read.p 0x23000000 dtb 0x00100000; mmc read.p 0x25000000 recovery 0x02000000; wdt_enable 10; bootm 0x25000000'

say() { printf '%s\n' "$*"; }
die() { printf 'error: %s\n' "$*" >&2; exit 1; }
dev() { "$ADB" -s "$TV" shell "$@"; }
root() { "$ADB" -s "$TV" exec-out su -c "$1"; }

"$ADB" connect "$TV" >/dev/null 2>&1
[ "$(dev getprop sys.boot_completed 2>/dev/null | tr -d '\r')" = "1" ] || die "device not in Android"
say "device up $(dev cut -d. -f1 /proc/uptime | tr -d '\r')s"

# baseline of the zone, so a stale record cannot be mistaken for a fresh one
say "--- zone BEFORE"
root 'od -A d -t x8 -N 32 /dev/../dev/null 2>/dev/null; /vendor/bin/busybox rmmod probeRW 2>/dev/null; /vendor/bin/busybox insmod /data/local/tmp/probeRW.ko addr=0x419c0000 len=32 op=r; rmmod probeRW; cat /data/local/tmp/probeRW.out' | tr -d '\r' | tail -4

root "dd if=/dev/block/mmcblk0 bs=4096 skip=2528 count=32 2>/dev/null" > /tmp/e128.bin
[ "$(stat -c %s /tmp/e128.bin)" = 131072 ] || die "short env read"
python3 - /tmp/e128.bin "$RC" /tmp/env10.bin "$T" <<'PY'
import subprocess, sys, hashlib
src, rc, out, tool = sys.argv[1:5]
d = open(src, 'rb').read(); a, b = d[:65536], d[65536:]
assert a == b, "primary/backup env differ"
parts = []
for i, h in enumerate((a, b)):
    p = '/tmp/g%d.bin' % i
    open(p, 'wb').write(h)
    subprocess.check_call(['python3', tool, 'set', p, 'recoverycmd=' + rc])
    parts.append(open(p, 'rb').read())
open(out, 'wb').write(parts[0] + parts[1])
print("new env md5", hashlib.md5(parts[0] + parts[1]).hexdigest())
PY
for h in /tmp/g0.bin /tmp/g1.bin; do python3 "$T" verify "$h" >/dev/null || die "env CRC invalid"; done
say "recoverycmd: $(python3 "$T" get /tmp/g0.bin recoverycmd)"

[ "$(root 'md5sum /dev/block/by-name/recovery' | tr -d '\r' | cut -d' ' -f1)" = "$FACTORY" ] || die "slot not factory"
[ "$(md5sum "$IMG" | cut -d' ' -f1)" = "$IMG_MD5" ] || die "local image md5 mismatch"

"$ADB" -s "$TV" push /tmp/env10.bin "$W/env10.bin" >/dev/null || die push
"$ADB" -s "$TV" push "$IMG" "$W/rec-hang1.img" >/dev/null || die push

o=$(root "dd if=$W/env10.bin of=/dev/block/mmcblk0 bs=4096 seek=2528 count=32 2>/dev/null; sync; dd if=/dev/block/mmcblk0 bs=4096 skip=2528 count=32 2>/dev/null | md5sum" | tr -d '\r')
say "env readback $o"
[ "$(printf '%s' "$o" | cut -d' ' -f1)" = "$(md5sum /tmp/env10.bin | cut -d' ' -f1)" ] || die "env readback mismatch"

o=$(root "dd if=$W/rec-hang1.img of=/dev/block/by-name/recovery bs=4096 2>/dev/null; sync; md5sum /dev/block/by-name/recovery" | tr -d '\r')
say "slot readback $o"
[ "$(printf '%s' "$o" | cut -d' ' -f1)" = "$IMG_MD5" ] || die "slot readback mismatch"

say "=== armed, rebooting at $(date +%H:%M:%S)  (probe hangs -> 10 s WDT -> Android)"
"$ADB" -s "$TV" reboot recovery
sleep 8
for i in $(seq 1 30); do
    sleep 5
    "$ADB" connect "$TV" >/dev/null 2>&1
    s=$(dev getprop sys.boot_completed 2>/dev/null | tr -d '\r')
    [ "$s" = "1" ] && { say "=== Android at $(date +%H:%M:%S) uptime $(dev cut -d. -f1 /proc/uptime | tr -d '\r')s"; break; }
done
[ "${s:-}" = "1" ] || { say "=== no adb"; exit 2; }

say "--- pstore"
root 'ls -l /sys/fs/pstore/' | tr -d '\r'
say "--- pmsg file"
root 'od -A d -t x8 /sys/fs/pstore/pmsg-ramoops-0 2>&1 | head -8' | tr -d '\r'
say "--- zone raw AFTER"
root '/vendor/bin/busybox rmmod probeRW 2>/dev/null; /vendor/bin/busybox insmod /data/local/tmp/probeRW.ko addr=0x419c0000 len=96 op=r; rmmod probeRW; cat /data/local/tmp/probeRW.out' | tr -d '\r' | tail -6
