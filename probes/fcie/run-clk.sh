#!/bin/bash
# Run the read-only generic-timer check (emmc_clk.S).
# Usage: run-clk.sh <img> <md5>
set -u
ADB=/home/emfox/Debian/tv/adb/platform-tools/adb
TV=192.168.10.60:5555
IMG=$1; IMD5=$2
root(){ $ADB -s $TV exec-out su -c "$1"; }
ready(){ $ADB connect $TV >/dev/null 2>&1; [ "$(root 'getprop sys.boot_completed' 2>/dev/null | tr -d '\r')" = 1 ]; }
for w in $(seq 1 60); do ready && break; sleep 5; done
ready || { echo "SKIP: android not ready"; exit 9; }
$ADB -s $TV push "$IMG" /data/local/tmp/c.img >/dev/null || { echo "SKIP: push failed"; exit 9; }
o=$(root "dd if=/data/local/tmp/c.img of=/dev/block/by-name/recovery bs=4096 2>/dev/null; sync; md5sum /dev/block/by-name/recovery" | tr -d '\r' | cut -d' ' -f1)
[ "$o" = "$IMD5" ] || { echo "SKIP: slot mismatch ($o)"; exit 9; }
t0=$(date +%s); echo "=== clk $(date +%H:%M:%S) slot ok"
$ADB -s $TV reboot recovery; sleep 12
"$(dirname "$0")/../../tools/host/tv-wait.sh" 300 || { echo "  NO_RETURN"; exit 8; }

probe(){ root "/vendor/bin/busybox rmmod probeRW 2>/dev/null; /vendor/bin/busybox insmod /data/local/tmp/probeRW.ko addr=$1 len=$2 op=r; rmmod probeRW; /vendor/bin/busybox cat /data/local/tmp/probeRW.out" | tr -d '\r'; }
probe 0x23090000 40 > /tmp/clk-vals.txt
probe 0x23090800 16 > /tmp/clk-mark.txt
python3 - /tmp/clk-vals.txt /tmp/clk-mark.txt <<'PY'
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
if len(v)>=40:
    frq, t0, t1, el, sctlr = struct.unpack("<QQQQQ", v[0:40])
    d = t1 - t0 if t1 >= t0 else 0
    print("  CNTFRQ_EL0=%d  t0=%d  t1=%d  delta=%d" % (frq, t0, t1, d))
    print("  CurrentEL=%#x  SCTLR_EL1=%#x" % (el, sctlr))
    print("  VERDICT: counter %s" % ("RUNS" if d > 0 else "DOES NOT ADVANCE"))
    if frq and d:
        print("  elapsed = %.3f ms (assuming 1e6 iterations)" % (d * 1000.0 / frq))
PY
