#!/bin/bash
# One full cycle: arm `wdt_enable 120` + the return probe in the recovery slot,
# reboot into it, poll, and read the pstore export as soon as Android answers.
#
# 120 s, not 10: the vendor kernel's ramoops init exports the record ~8 s into
# the boot, but adb only answers ~35 s in.  A 10 s watchdog therefore destroys
# the export (kmalloc lives in DRAM) before it can ever be read, and the reset
# also makes "probe hung" and "probe returned" look identical.  120 s keeps the
# reset as a safety net without eating the readout window.
set -u
ADB=${ADB:-/home/emfox/Debian/tv/adb/platform-tools/adb}
TV=${TV:-192.168.10.60:5555}
IMG=${IMG:-/home/emfox/kbuild/m7642-out/m7642-rec-handoff1-ret.img}
T=/home/emfox/Debian/m7642/tools/host/envtool.py
W=/data/local/tmp
IMG_MD5=3a950d5064b4569f47df1d4337faa2f6
FACTORY=7c2f467bbda49053951c0ce547d11a00
RC='mmc erase.p misc; mmc read.p 0x23000000 dtb 0x00100000; mmc read.p 0x25000000 recovery 0x02000000; wdt_enable 120; bootm 0x25000000'

say() { printf '%s\n' "$*"; }
die() { printf 'error: %s\n' "$*" >&2; exit 1; }
dev() { "$ADB" -s "$TV" shell "$@"; }
root() { "$ADB" -s "$TV" exec-out su -c "$1"; }

"$ADB" connect "$TV" >/dev/null 2>&1
[ "$(dev getprop sys.boot_completed 2>/dev/null | tr -d '\r')" = "1" ] || die "device not in Android"
say "device up $(dev cut -d. -f1 /proc/uptime | tr -d '\r')s"

# --- build the env locally from what is on the device right now
root "dd if=/dev/block/mmcblk0 bs=4096 skip=2528 count=32 2>/dev/null" > /tmp/e128.bin
[ "$(stat -c %s /tmp/e128.bin)" = 131072 ] || die "short env read"
python3 - /tmp/e128.bin "$RC" /tmp/env120.bin "$T" <<'PY'
import subprocess, sys, hashlib
src, rc, out, tool = sys.argv[1:5]
d = open(src, 'rb').read()
a, b = d[:65536], d[65536:]
assert a == b, "primary/backup env differ; stop and look"
parts = []
for i, h in enumerate((a, b)):
    p = '/tmp/h%d.bin' % i
    open(p, 'wb').write(h)
    subprocess.check_call(['python3', tool, 'set', p, 'recoverycmd=' + rc])
    parts.append(open(p, 'rb').read())
open(out, 'wb').write(parts[0] + parts[1])
print("new env md5", hashlib.md5(parts[0] + parts[1]).hexdigest())
PY
for h in /tmp/h0.bin /tmp/h1.bin; do
    python3 "$T" verify "$h" >/dev/null || die "new env CRC invalid ($h)"
done
say "recoverycmd: $(python3 "$T" get /tmp/h0.bin recoverycmd)"

# --- slot must be factory before we overwrite it
[ "$(root 'md5sum /dev/block/by-name/recovery' | tr -d '\r' | cut -d' ' -f1)" = "$FACTORY" ] \
    || die "recovery slot is not factory"
[ "$(md5sum "$IMG" | cut -d' ' -f1)" = "$IMG_MD5" ] || die "local image md5 mismatch"

"$ADB" -s "$TV" push /tmp/env120.bin "$W/env120.bin" >/dev/null || die "push env"
"$ADB" -s "$TV" push "$IMG" "$W/rec-ret.img" >/dev/null || die "push image"

out=$(root "dd if=$W/env120.bin of=/dev/block/mmcblk0 bs=4096 seek=2528 count=32 2>/dev/null; sync; dd if=/dev/block/mmcblk0 bs=4096 skip=2528 count=32 2>/dev/null | md5sum" | tr -d '\r')
say "env readback $out"
[ "$(printf '%s' "$out" | cut -d' ' -f1)" = "$(md5sum /tmp/env120.bin | cut -d' ' -f1)" ] || die "env readback mismatch"

out=$(root "dd if=$W/rec-ret.img of=/dev/block/by-name/recovery bs=4096 2>/dev/null; sync; md5sum /dev/block/by-name/recovery" | tr -d '\r')
say "slot readback $out"
[ "$(printf '%s' "$out" | cut -d' ' -f1)" = "$IMG_MD5" ] || die "slot readback mismatch"

say "=== armed, rebooting at $(date +%H:%M:%S)"
"$ADB" -s "$TV" reboot recovery
sleep 5

# --- poll; report the first moment Android answers
for i in $(seq 1 45); do
    sleep 4
    "$ADB" connect "$TV" >/dev/null 2>&1
    s=$(dev getprop sys.boot_completed 2>/dev/null | tr -d '\r')
    if [ "$s" = "1" ]; then
        say "=== Android at $(date +%H:%M:%S)  uptime $(dev cut -d. -f1 /proc/uptime | tr -d '\r')s"
        break
    fi
    [ $((i % 5)) -eq 0 ] && say "  ... $(date +%H:%M:%S) no adb yet"
done
[ "${s:-}" = "1" ] || { say "=== no adb after ~185 s"; exit 2; }

say "--- pstore"
root 'ls -l /sys/fs/pstore/ 2>&1' | tr -d '\r'
say "--- pmsg record (hex words)"
root 'od -A d -t x8 /sys/fs/pstore/pmsg-ramoops-0 2>&1' | tr -d '\r'
say "--- bootreason / uptime"
root 'getprop ro.boot.bootreason; cut -d. -f1 /proc/uptime' | tr -d '\r'
