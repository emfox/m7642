#!/bin/bash
# Run the CMD24 write probe.  THE FIRST WRITE TO eMMC IN THIS PROJECT.
#
#   ./run-write.sh            # derives the target LBA from the device
#   ./run-write.sh <lba>      # or use an explicit one (you had better be sure)
#
# Safety, in layers:
#   1. the target is inside the `dtb` partition at +0x80000, i.e. ~512 KiB past
#      the real 23 KiB blob.  mboot reads the whole 1 MiB into 0x23000000 but
#      only parses up to the DTB header's totalsize, so the tail is dead space.
#   2. the probe reads that block first and REFUSES unless it is uniformly
#      0x00 or 0xFF (E_NOT_EMPTY) -- a wrong LBA cannot clobber real data.
#   3. it verifies by reading the block back with the CMD17 path that is already
#      proven on this device, and only reports success if the 512 bytes match.
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
	part=$(root "readlink -f /dev/block/by-name/dtb")
	start=$(root "cat /sys/class/block/$(basename $part)/start")
	[ -n "$start" ] || { echo "SKIP: cannot read the dtb partition start"; exit 9; }
	LBA=$(( start + 0x80000 / 512 ))
	echo "=== dtb partition starts at LBA $start; target LBA $LBA (+0x80000)"
fi

IMG=$HOME/Debian/m7642-build/out/m7642-rec-73-write.img
LBA=$LBA "$D/build-write.sh" | tail -2
IMD5=$(md5sum "$IMG" | cut -d' ' -f1)

$ADB -s $TV push "$IMG" /data/local/tmp/w.img >/dev/null || exit 9
o=$(root "dd if=/data/local/tmp/w.img of=/dev/block/by-name/recovery bs=4096 2>/dev/null; sync; md5sum /dev/block/by-name/recovery" | cut -d' ' -f1)
[ "$o" = "$IMD5" ] || { echo "SKIP: slot mismatch ($o)"; exit 9; }

echo "=== $(date +%H:%M:%S) LBA=$LBA running (a hang here needs an unplug)"
"$D/../../tools/host/tv-wait.sh" 120 || { echo "  NO_RETURN"; exit 8; }

echo "=== record:"
root "/vendor/bin/busybox rmmod probeRW 2>/dev/null; /vendor/bin/busybox insmod /data/local/tmp/probeRW.ko addr=0x23090000 len=48 op=r; rmmod probeRW; /vendor/bin/busybox cat /data/local/tmp/probeRW.out" | grep '^0000'
cat <<'NOTE'

判读
  rc = 0           写成功且读回逐字节一致 ⟹ diag[0] 就是"写方向"的 SD_CTRL 编码
  rc = 0xEA        E_NOT_EMPTY：那块不是空的 ⟹ LBA 算错了，什么都没写
  rc = 0xEB        E_VERIFY：写命令被接受但读回不一致（方向位不对 / 卡拒绝）
  rc = 0xE4/0xE6   CMD_END / DMA_END 超时：时序或方向位不对
NOTE
