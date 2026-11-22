#!/bin/bash
# Run the single-write test (emmc_wr1.S) and decode it.
# Usage: run-wr1.sh <img> <md5>
set -u
ADB=/home/emfox/Debian/tv/adb/platform-tools/adb
TV=192.168.10.60:5555
IMG=$1; IMD5=$2
root(){ $ADB -s $TV exec-out su -c "$1"; }
ready(){ $ADB connect $TV >/dev/null 2>&1; [ "$(root 'getprop sys.boot_completed' 2>/dev/null | tr -d '\r')" = 1 ]; }
for w in $(seq 1 60); do ready && break; sleep 5; done
ready || { echo "SKIP: android not ready"; exit 9; }
$ADB -s $TV push "$IMG" /data/local/tmp/w.img >/dev/null || { echo "SKIP: push failed"; exit 9; }
o=$(root "dd if=/data/local/tmp/w.img of=/dev/block/by-name/recovery bs=4096 2>/dev/null; sync; md5sum /dev/block/by-name/recovery" | tr -d '\r' | cut -d' ' -f1)
[ "$o" = "$IMD5" ] || { echo "SKIP: slot mismatch ($o)"; exit 9; }
t0=$(date +%s); echo "=== wr1 $(date +%H:%M:%S) slot ok"
$ADB -s $TV reboot recovery; sleep 12
"$(dirname "$0")/../../tools/host/tv-wait.sh" 300 || { echo "  NO_RETURN"; exit 8; }

probe(){ root "/vendor/bin/busybox rmmod probeRW 2>/dev/null; /vendor/bin/busybox insmod /data/local/tmp/probeRW.ko addr=$1 len=$2 op=r; rmmod probeRW; /vendor/bin/busybox cat /data/local/tmp/probeRW.out" | tr -d '\r'; }
probe 0x23090000 16 > /tmp/wr1-vals.txt
probe 0x23090800 16 > /tmp/wr1-mark.txt
python3 - /tmp/wr1-vals.txt /tmp/wr1-mark.txt <<'PY'
import struct, sys
def rec(path):
    out=[]
    for line in open(path,"rb").read().decode("ascii","ignore").splitlines():
        if ":" in line:
            a,b=line.split(":",1)
            if len(a.strip())==16: out.append(b.replace(" ","").strip())
    return bytes.fromhex("".join(out)) if out else b""
v=rec(sys.argv[1]); m=rec(sys.argv[2])
print("  marker: %r %r count=%d" % (m[0:4], m[4:8], struct.unpack("<I", m[8:12])[0]) if len(m)>=12 else "  marker: none")
if len(v)>=16:
    before, same, two, restored = struct.unpack("<IIII", v[0:16])
    print("  JOB_BL_CNT: before=%d after_same_write=%d after_write2=%d after_restore=%d" %
          (before, same, two, restored))
    ok = same == before and two == 2 and restored == before
    print("  VERDICT: %s" % ("WRITES WORK" if ok else "WRITE VISIBILITY WRONG"))
else:
    print("  no values")
PY
