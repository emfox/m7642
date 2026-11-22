#!/bin/bash
# Run the CMD24 write probe.  This is the first code in the project that writes
# to eMMC, so every step is gated.
#
#   ./run-write.sh            # derive the target from the dtb partition
#   ./run-write.sh <lba>      # explicit (you had better be sure)
#
# Layers of protection:
#   1. the target lives in the `dtb` partition at +0x80000 (512 KiB past the
#      real 23 KiB blob); the partition's own size is checked before we agree
#      to it, so a short partition cannot silently point at the next one;
#   2. the probe reads that block and REFUSES unless it is uniformly 0x00/0xFF
#      (E_NOT_EMPTY) -- a wrong LBA cannot clobber real data;
#   3. after writing, the block is read back with the already-proven CMD17 path
#      and only a byte-for-byte match counts as success;
#   4. the controller state is saved/restored, so the handover still sees what
#      mboot left behind.
set -u
D=$(cd "$(dirname "$0")" && pwd)
ADB=/home/emfox/Debian/tv/adb/platform-tools/adb
TV=192.168.10.60:5555
root(){ $ADB -s $TV exec-out su -c "$1" | tr -d '\r'; }
ready(){ $ADB connect $TV >/dev/null 2>&1; [ "$(root 'getprop sys.boot_completed' 2>/dev/null)" = 1 ]; }

for w in $(seq 1 60); do ready && break; sleep 5; done
ready || { echo "SKIP: android not ready"; exit 9; }

LBA=${1:-}
if [ -z "$LBA" ]; then
	part=$(root 'readlink -f /dev/block/by-name/dtb')
	base=$(basename "$part" 2>/dev/null)
	start=$(root "cat /sys/class/block/$base/start" 2>/dev/null)
	size=$(root  "cat /sys/class/block/$base/size"  2>/dev/null)
	case "$start$size" in ''|*[!0-9]*) echo "SKIP: cannot read dtb start/size ('$start'/'$size')"; exit 9;; esac
	LBA=$(( start + 0x80000 / 512 ))
	# We must stay strictly inside the partition: one block at LBA, and the
	# partition must really reach 0x80000 + 512 bytes.
	if [ $(( LBA + 1 )) -gt $(( start + size )) ] || [ "$size" -le 1024 ]; then
		echo "SKIP: dtb partition too small (size=$size sectors) for a +0x80000 target"
		exit 9
	fi
	echo "=== dtb: start LBA $start, $size sectors; target LBA $LBA (+0x80000)"
fi

IMG=$HOME/Debian/m7642-build/out/m7642-rec-73-write.img
LBA=$LBA "$D/build-write.sh" | tail -3 || { echo "SKIP: build failed"; exit 9; }
IMD5=$(md5sum "$IMG" | cut -d' ' -f1)

$ADB -s $TV push "$IMG" /data/local/tmp/w.img >/dev/null || exit 9
o=$(root "dd if=/data/local/tmp/w.img of=/dev/block/by-name/recovery bs=4096 2>/dev/null; sync; md5sum /dev/block/by-name/recovery" | cut -d' ' -f1)
[ "$o" = "$IMD5" ] || { echo "SKIP: slot mismatch (got $o, want $IMD5)"; exit 9; }

$ADB -s $TV exec-out su -c "dd if=/data/local/tmp/mark.bin of=/dev/block/by-name/misc bs=512 seek=16376 count=8 2>/dev/null; sync" >/dev/null 2>&1
echo "=== $(date +%H:%M:%S) rebooting into recovery, LBA=$LBA"
$ADB -s $TV reboot recovery >/dev/null 2>&1
sleep 12

if ! "$D/../../tools/host/tv-wait.sh" 300; then echo "  NO_RETURN (hang -- see wdt-beacon.md §二)"; exit 8; fi

echo "=== record:"
rec=$(root "/vendor/bin/busybox rmmod probeRW 2>/dev/null; /vendor/bin/busybox insmod /data/local/tmp/probeRW.ko addr=0x23090000 len=48 op=r; rmmod probeRW; /vendor/bin/busybox cat /data/local/tmp/probeRW.out" | grep '^0000')
echo "$rec"
python3 - "$rec" <<'PY'
import sys, re
txt = sys.argv[1] if len(sys.argv) > 1 else ""
b = bytearray()
for line in txt.splitlines():
    m = re.match(r"^0000[0-9a-fA-F]*:\s*(.*)$", line.strip())
    if not m: continue
    for tok in m.group(1).split():
        if re.fullmatch(r"[0-9a-fA-F]{2}", tok): b.append(int(tok, 16))
if len(b) < 48:
    print("  !! record missing or short (%d B)" % len(b)); sys.exit(1)
if b[0:4] != b"M764" or b[4:8] != b"EECW":
    print("  !! bad magic/tag %r %r -- this is not our write record" % (bytes(b[0:4]), bytes(b[4:8])))
    sys.exit(1)
rc = int.from_bytes(b[8:12], "little")
diag = [int.from_bytes(b[16+8*i:24+8*i], "little") for i in range(4)]
names = {0:"OK", 0xE1:"E_DEST", 0xE2:"E_NC", 0xE3:"E_D0", 0xE4:"E_CMD_TMO",
         0xE5:"E_CMD_STS", 0xE6:"E_DMA_TMO", 0xE7:"E_DMA_STS", 0xE8:"E_R1",
         0xE9:"E_EV_CLR", 0xEA:"E_NOT_EMPTY", 0xEB:"E_VERIFY"}
print("  rc     = %#x %s" % (rc, names.get(rc, "?")))
print("  diag   = r1=%#x sd_status=%#x event=%#x miu=%#x" % tuple(diag))
if rc == 0:
    print("  ==> WRITE WORKS: two-stage CMD24 accepted, read-back identical")
elif rc == 0xEA:
    print("  ==> refused: that block was not empty. LBA is wrong; NOTHING was written.")
elif rc == 0xEB:
    print("  ==> command accepted but read-back differs. NOTE: the block now holds")
    print("      our 0xA5 pattern, so pick a DIFFERENT LBA for the next attempt.")
elif rc in (0xE4, 0xE6):
    print("  ==> timed out waiting for CMD_END/DMA_END: sequence or timing wrong.")
PY
