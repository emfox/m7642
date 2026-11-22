#!/bin/bash
# Run the boot-path CMD17 probe (emmc_read.S + fcie_read.c) and verify LBA 0
# against the kernel's own read of the same sector.
#
# Usage: run-cmd17.sh <img> <md5>
#
# Readouts after Android boots:
#   0x23080000  512 B block data
#   0x23080FE0  heartbeat: magic 0x4643494531, rc, R1, SD_STATUS
#   0x23090000  record: "M764"/"EMMC" + return code
set -u
ADB=/home/emfox/Debian/tv/adb/platform-tools/adb
TV=192.168.10.60:5555
IMG=$1; IMD5=$2
root(){ $ADB -s $TV exec-out su -c "$1"; }
ready(){ $ADB connect $TV >/dev/null 2>&1; [ "$(root 'getprop sys.boot_completed' 2>/dev/null | tr -d '\r')" = 1 ]; }

for w in $(seq 1 60); do ready && break; sleep 5; done
ready || { echo "SKIP: android not ready"; exit 9; }
$ADB -s $TV push "$IMG" /data/local/tmp/e.img >/dev/null || { echo "SKIP: push failed"; exit 9; }
o=$(root "dd if=/data/local/tmp/e.img of=/dev/block/by-name/recovery bs=4096 2>/dev/null; sync; md5sum /dev/block/by-name/recovery" | tr -d '\r' | cut -d' ' -f1)
[ "$o" = "$IMD5" ] || { echo "SKIP: slot mismatch ($o)"; exit 9; }

t0=$(date +%s); echo "=== cmd17 $(date +%H:%M:%S) slot ok"
$ADB -s $TV reboot recovery; sleep 12
ok=""
for i in $(seq 1 $(( ${WAITSECS:-300} / 5 ))); do ready && { ok=1; break; }; sleep 5; done
echo "  android_up=${ok:-no} ($(( $(date +%s) - t0 ))s)"
[ -n "$ok" ] || { echo "  NO_RETURN: the probe hung, or the handover failed"; exit 8; }

probe(){
	root "/vendor/bin/busybox rmmod probeRW 2>/dev/null; /vendor/bin/busybox insmod /data/local/tmp/probeRW.ko addr=$1 len=$2 op=r; rmmod probeRW; /vendor/bin/busybox cat /data/local/tmp/probeRW.out" | tr -d '\r'
}
probe 0x23080000 512   > /tmp/cmd17-block.txt
probe 0x23080fe0 32    > /tmp/cmd17-hb.txt
probe 0x23090000 64    > /tmp/cmd17-rec.txt
root "dd if=/dev/block/mmcblk0 bs=512 count=1 2>/dev/null" > /tmp/cmd17-kernel.bin

python3 - <<'PY'
import hashlib, struct
def rec(path):
    out = []
    for line in open(path, "rb").read().decode("ascii", "ignore").splitlines():
        if ":" in line:
            a, b = line.split(":", 1)
            if len(a.strip()) == 16:
                out.append(b.replace(" ", "").strip())
    return bytes.fromhex("".join(out)) if out else b""
blk = rec("/tmp/cmd17-block.txt")
hb  = rec("/tmp/cmd17-hb.txt")
r   = rec("/tmp/cmd17-rec.txt")
ker = open("/tmp/cmd17-kernel.bin", "rb").read()
if len(r) >= 24:
    rc = struct.unpack("<Q", r[16:24])[0]
    print("  record: magic=%r tag=%r rc=%#x" % (r[0:4], r[4:8], rc))
else:
    print("  record: none")
if len(hb) >= 32:
    m, rc2, r1, st = struct.unpack("<QQQQ", hb[0:32])
    print("  heartbeat: magic=%#x (%s) rc=%#x R1=%#x SD_STATUS=%#x" %
          (m, "FCIE1" if m == 0x4643494531 else "?", rc2, r1, st))
    print("  R1: CURRENT_STATE=%d READY_FOR_DATA=%d ERR=%#x" %
          ((r1 >> 9) & 0xF, (r1 >> 8) & 1, r1 & 0xFFF98080))
else:
    print("  heartbeat: none")
print("  probe block: %d B md5=%s head=%s" % (len(blk), hashlib.md5(blk).hexdigest(), blk[:32].hex()))
print("  kernel LBA0: %d B md5=%s" % (len(ker), hashlib.md5(ker).hexdigest()))
print("  MATCH: %s" % (blk == ker))
if len(blk) >= 512:
    print("  signature: %#x  (0xaa55 = MBR, 'EFI PART' at 0x200 is GPT)" % struct.unpack("<H", blk[510:512])[0])
PY
