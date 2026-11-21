#!/bin/bash
# Run one post-MMU checkpoint image and decode both stash records.
# Usage: run-postmmu.sh <img> <md5> <tag>
#
#  0x23090000  code1 shim: the bootloader's entry registers ("M764"/"FDT ")
#  0x23080000  handover:   the checkpoint record ("M764"/"MMMU")
#
# Waits 300 s for Android (discipline: a slow /data repair once produced a
# false "not reached") and verifies the slot md5 before rebooting.
set -u
ADB=/home/emfox/Debian/tv/adb/platform-tools/adb
TV=192.168.10.60:5555
IMG=$1; IMD5=$2; TAG=$3
root(){ $ADB -s $TV exec-out su -c "$1"; }
ready(){ $ADB connect $TV >/dev/null 2>&1; [ "$(root 'getprop sys.boot_completed' 2>/dev/null | tr -d '\r')" = 1 ]; }

for w in $(seq 1 60); do ready && break; sleep 5; done
ready || { echo "SKIP $TAG: android not ready"; exit 9; }

$ADB -s $TV push "$IMG" /data/local/tmp/f.img >/dev/null || { echo "SKIP $TAG: push failed"; exit 9; }
o=$(root "dd if=/data/local/tmp/f.img of=/dev/block/by-name/recovery bs=4096 2>/dev/null; sync; md5sum /dev/block/by-name/recovery" | tr -d '\r' | cut -d' ' -f1)
[ "$o" = "$IMD5" ] || { echo "SKIP $TAG: slot mismatch ($o)"; exit 9; }

t0=$(date +%s); echo "=== $TAG $(date +%H:%M:%S) slot ok"
$ADB -s $TV reboot recovery; sleep 12
ok=""
for i in $(seq 1 60); do ready && { ok=1; break; }; sleep 5; done
echo "  android_up=${ok:-no} ($(( $(date +%s) - t0 ))s)"
[ -n "$ok" ] || { echo "  NO_RETURN: checkpoint not reached, or the handover failed"; exit 8; }

page(){  # $1 addr, $2 outfile
	root "/vendor/bin/busybox rmmod probeRW 2>/dev/null; /vendor/bin/busybox insmod /data/local/tmp/probeRW.ko addr=$1 len=64 op=r; rmmod probeRW; /vendor/bin/busybox cat /data/local/tmp/probeRW.out" | tr -d '\r' > "$2"
}

page 0x23090000 "/tmp/stf-$TAG.txt"
page 0x23080000 "/tmp/stm-$TAG.txt"
python3 - "/tmp/stf-$TAG.txt" "/tmp/stm-$TAG.txt" <<'PY'
import sys, struct
def rec(path):
    out = []
    for line in open(path):
        if ":" in line:
            a, b = line.split(":", 1)
            if len(a.strip()) == 16:
                out.append(b.replace(" ", "").strip())
    return bytes.fromhex("".join(out)) if out else b""
def show(title, h):
    u = lambda o: struct.unpack("<Q", h[o:o+8])[0]
    if len(h) < 0x48:
        print("  %s: no record" % title); return
    print("  %s: magic=%r tag=%r size=%#x x30=%#x" %
          (title, h[0:4], h[4:8], struct.unpack("<I", h[8:12])[0], u(0x10)))
    print("    x0=%#x x1=%#x x2=%#x x3=%#x x4=%#x x5=%#x" %
          (u(0x18), u(0x20), u(0x28), u(0x30), u(0x38), u(0x40)))
shim = rec(sys.argv[1]); hand = rec(sys.argv[2])
show("shim  @23090000", shim)
show("hand  @23080000", hand)
fdt_ok = len(shim) >= 8 and shim[0:4] == b"M764" and shim[4:8] == b"FDT "
mmmu_ok = len(hand) >= 8 and hand[0:4] == b"M764" and hand[4:8] == b"MMMU"
print("  VERDICT shim=%s handover=%s" % ("OK" if fdt_ok else "MISSING",
                                         "OK" if mmmu_ok else "MISSING"))
PY
