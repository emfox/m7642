#!/bin/bash
# Pre-MMU rung runner (abort-rung stub).
# A REACHED verdict requires the stash to prove the stub ran: magic "M764" and
# x30 == 0x20280000 + off + 4.
# Usage: run-rung.sh <img> <md5> <off>
set -u
ADB=/home/emfox/Debian/tv/adb/platform-tools/adb
TV=192.168.10.60:5555
IMG=$1; IMD5=$2; OFF=$3
root(){ $ADB -s $TV exec-out su -c "$1"; }
ready(){ $ADB connect $TV >/dev/null 2>&1; [ "$(root 'getprop sys.boot_completed' 2>/dev/null | tr -d '\r')" = 1 ]; }

for w in $(seq 1 60); do ready && break; sleep 5; done
ready || { echo "SKIP $OFF: android not ready"; exit 9; }
$ADB -s $TV push "$IMG" /data/local/tmp/r.img >/dev/null || { echo "SKIP $OFF: push failed"; exit 9; }
o=$(root "dd if=/data/local/tmp/r.img of=/dev/block/by-name/recovery bs=4096 2>/dev/null; sync; md5sum /dev/block/by-name/recovery" | tr -d '\r' | cut -d' ' -f1)
[ "$o" = "$IMD5" ] || { echo "SKIP $OFF: slot mismatch ($o)"; exit 9; }

t0=$(date +%s); echo "=== rung $OFF $(date +%H:%M:%S) slot ok"
$ADB -s $TV reboot recovery; sleep 14
ok=""
for i in $(seq 1 60); do ready && { ok=1; break; }; sleep 5; done
[ -n "$ok" ] || { echo "RESULT $OFF: NO_RETURN ($(( $(date +%s) - t0 ))s)"; exit 4; }

root "/vendor/bin/busybox rmmod probeRW 2>/dev/null; /vendor/bin/busybox insmod /data/local/tmp/probeRW.ko addr=0x23080000 len=32 op=r; rmmod probeRW; /vendor/bin/busybox cat /data/local/tmp/probeRW.out" | tr -d '\r' > "/tmp/rung-$OFF.txt"
grep -E '^[0-9a-f]{16}:' "/tmp/rung-$OFF.txt" | sed 's/^/  /'
python3 - "/tmp/rung-$OFF.txt" "$OFF" <<'PY'
import sys, struct
chunks = []
for line in open(sys.argv[1]):
    if ":" in line:
        a, b = line.split(":", 1)
        if len(a.strip()) == 16:
            chunks.append(b.replace(" ", "").strip())
h = bytes.fromhex("".join(chunks)) if chunks else b""
off = int(sys.argv[2], 0)
if len(h) < 0x18:
    print("  RESULT %s: INCONCLUSIVE (no record)" % sys.argv[2]); sys.exit(4)
magic, step = h[0:4], h[4:8]
x30 = struct.unpack("<Q", h[0x10:0x18])[0]
want = 0x20280000 + off + 4
print("  magic=%r step=%r x30=%#x want=%#x" % (magic, step, x30, want))
if magic == b"M764" and x30 == want:
    print("  RESULT %s: REACHED (verified)" % sys.argv[2]); sys.exit(0)
if magic == b"M764":
    print("  RESULT %s: INCONCLUSIVE (stub ran but x30 mismatch)" % sys.argv[2]); sys.exit(5)
print("  RESULT %s: INCONCLUSIVE (stash empty)" % sys.argv[2]); sys.exit(4)
PY
