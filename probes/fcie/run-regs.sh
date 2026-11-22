#!/bin/bash
# Run the code1 read-only FCIE0/EMMC_PLL dump and decode it.
# Usage: run-regs.sh <img> <md5>
#
# Readouts: 0x23090000 + idx*4 (FCIE0), 0x23090400 (PLL 0x1a/0x45),
#           0x23090800 ("M764"/"REG ", 34).
set -u
ADB=/home/emfox/Debian/tv/adb/platform-tools/adb
TV=192.168.10.60:5555
IMG=$1; IMD5=$2
root(){ $ADB -s $TV exec-out su -c "$1"; }
ready(){ $ADB connect $TV >/dev/null 2>&1; [ "$(root 'getprop sys.boot_completed' 2>/dev/null | tr -d '\r')" = 1 ]; }

for w in $(seq 1 60); do ready && break; sleep 5; done
ready || { echo "SKIP: android not ready"; exit 9; }
$ADB -s $TV push "$IMG" /data/local/tmp/r.img >/dev/null || { echo "SKIP: push failed"; exit 9; }
o=$(root "dd if=/data/local/tmp/r.img of=/dev/block/by-name/recovery bs=4096 2>/dev/null; sync; md5sum /dev/block/by-name/recovery" | tr -d '\r' | cut -d' ' -f1)
[ "$o" = "$IMD5" ] || { echo "SKIP: slot mismatch ($o)"; exit 9; }

t0=$(date +%s); echo "=== regs $(date +%H:%M:%S) slot ok"
$ADB -s $TV reboot recovery; sleep 12
ok=""
for i in $(seq 1 60); do ready && { ok=1; break; }; sleep 5; done
echo "  android_up=${ok:-no} ($(( $(date +%s) - t0 ))s)"
[ -n "$ok" ] || { echo "  NO_RETURN: an MMIO read hung, or the handover failed"; exit 8; }

probe(){ root "/vendor/bin/busybox rmmod probeRW 2>/dev/null; /vendor/bin/busybox insmod /data/local/tmp/probeRW.ko addr=$1 len=$2 op=r; rmmod probeRW; /vendor/bin/busybox cat /data/local/tmp/probeRW.out" | tr -d '\r'; }
probe 0x23090000 0x190 > /tmp/regs-fcie.txt
probe 0x23090400 8     > /tmp/regs-pll.txt
probe 0x23090800 16    > /tmp/regs-mark.txt

python3 - "/tmp/regs-fcie.txt" "/tmp/regs-pll.txt" "/tmp/regs-mark.txt" "$(dirname "$0")/regs-reference.txt" <<'PY'
import struct, sys
def rec(path):
    out = []
    for line in open(path, "rb").read().decode("ascii", "ignore").splitlines():
        if ":" in line:
            a, b = line.split(":", 1)
            if len(a.strip()) == 16:
                out.append(b.replace(" ", "").strip())
    return bytes.fromhex("".join(out)) if out else b""
fc = rec(sys.argv[1]); pll = rec(sys.argv[2]); mk = rec(sys.argv[3])
ref = {}
for line in open(sys.argv[4]):
    line = line.strip()
    if not line or line.startswith("#"):
        continue
    p = line.split()
    if p[0] == "pll":
        ref["pll " + p[1]] = int(p[2], 16)
    else:
        ref[p[0]] = int(p[1], 16)
if len(mk) >= 8:
    print("  marker: %r %r count=%d" % (mk[0:4], mk[4:8], struct.unpack("<I", mk[8:12])[0]))
else:
    print("  marker: none")
vals = {}
for idx in list(range(0x00, 0x19)) + [0x29] + list(range(0x34, 0x3a)) + [0x3f, 0x63]:
    o = idx * 4
    if len(fc) >= o + 4:
        vals["%02x" % idx] = struct.unpack("<I", fc[o:o + 4])[0]
if len(pll) >= 8:
    vals["pll 0x1a"], vals["pll 0x45"] = struct.unpack("<II", pll[0:8])
diff = 0
for k in sorted(vals):
    r = ref.get(k)
    mark = ""
    if r is not None and r != vals[k]:
        mark = "   (android-idle ref %04x)" % r
        diff += 1
    print("  %-8s %04x%s" % (k, vals[k], mark))
print("  %d values, %d differ from the Android-idle reference" % (len(vals), diff))
PY
