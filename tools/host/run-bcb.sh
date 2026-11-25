#!/bin/bash
# run-bcb.sh <tag>
#
# The ONLY reliable way to run one of our images on this box.
#
# Why: `adb reboot recovery` makes Android shut down, and during that shutdown
# (or the following boot) Android writes /system/etc/recovery.img over the
# recovery partition.  So by the time mboot loads "recovery" it is the factory
# image, not ours - which is why so many earlier experiments appeared to do
# nothing.  Verified: flashing works (full-image md5 matches right after the
# dd and stays correct for 35s while Android runs), but after a reboot the
# slot is back to 7c2f467bbda49053951c0ce547d11a00.
#
# The working route is the bootloader control block: write "boot-recovery" into
# misc, then cut the power at the socket.  mboot then runs its recoverycmd,
# whose first command is `mmc erase.p misc` (so the BCB is consumed and there
# is no loop), and boots OUR image with Android never running.
set -u
TAG=${1:?用法: run-bcb.sh <tag>}
ADB=/home/emfox/Debian/tv/adb/platform-tools/adb
TV=192.168.10.60:5555
M=$HOME/.local/bin/mihome-ctl
DID=2188570626
SRC=$HOME/Debian/m7642-build/out/m7642-$TAG.img
R=/data/local/tmp/$TAG.img

have() { [ "$(timeout 5 $ADB -s $TV shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')" = "1" ]; }
slot_md5() { timeout 120 $ADB -s $TV shell "su -c '/vendor/bin/busybox dd if=/dev/block/by-name/recovery bs=4096 2>/dev/null | /vendor/bin/busybox md5sum'" </dev/null 2>/dev/null | tr -d '\r' | cut -d' ' -f1; }

[ -f "$SRC" ] || { echo "  ✗ 镜像不存在: $SRC"; exit 1; }
timeout 6 $ADB connect $TV >/dev/null 2>&1
have || { echo "  ✗ 设备未就绪"; exit 1; }

# 1) 推 + 校验
timeout 180 $ADB -s $TV push "$SRC" "$R" >/dev/null 2>&1
P=$(timeout 40 $ADB -s $TV shell "su -c '/vendor/bin/busybox md5sum $R'" </dev/null 2>/dev/null | tr -d '\r' | cut -d' ' -f1)
IMG=$(md5sum "$SRC" | cut -d' ' -f1)
echo "  推送 md5: $P"
[ "$P" = "$IMG" ] || { echo "  ✗ 推送校验失败"; exit 1; }

# 2) 烧写 + 全镜像校验（不是只验前 4K）
timeout 300 $ADB -s $TV shell "su -c '/vendor/bin/busybox dd if=$R of=/dev/block/by-name/recovery bs=4096 conv=notrunc'" </dev/null >/dev/null 2>&1
timeout 60 $ADB -s $TV shell "su -c '/vendor/bin/busybox sync'" </dev/null >/dev/null 2>&1
G=$(slot_md5)
echo "  槽全 md5: $G"
[ "$G" = "$IMG" ] || { echo "  ✗ 全镜像校验失败 —— 不产生任何结论"; exit 1; }

# 3) 写 BCB
timeout 40 $ADB -s $TV shell "su -c '/vendor/bin/busybox sh -c \"printf boot-recovery | /vendor/bin/busybox dd of=/dev/block/by-name/misc bs=1 seek=0 conv=notrunc\"'" </dev/null >/dev/null 2>&1
timeout 40 $ADB -s $TV shell "su -c '/vendor/bin/busybox sync'" </dev/null >/dev/null 2>&1
B=$(timeout 40 $ADB -s $TV shell "su -c '/vendor/bin/busybox dd if=/dev/block/by-name/misc bs=13 count=1 2>/dev/null'" </dev/null 2>/dev/null | tr -d '\r' | tr -d '\0')
echo "  BCB: [$B]"
[ "$B" = "boot-recovery" ] || { echo "  ✗ BCB 写入失败"; exit 1; }

# 4) 插座断电冷启（不走 adb reboot）
echo "  ✓ 烧写与 BCB 均校验通过，插座断电冷启"
timeout 20 $M action --did $DID --siid 2 --aiid 1 >/dev/null 2>&1
sleep 15
timeout 20 $M action --did $DID --siid 2 --aiid 1 >/dev/null 2>&1
sleep 5
timeout 25 $M ir-send --remote 电视 --key POWER >/dev/null 2>&1

# 5) 等它回来（回来 = 我们的内核完成了；不回来 = 按探针的条件为假/挂住）
for i in $(seq 1 40); do
  sleep 5
  timeout 6 $ADB connect $TV >/dev/null 2>&1
  if have; then
    echo "  ✓ 回到 Android (+$((i*5))s) —— 探针条件为 TRUE"
    exit 0
  fi
done
echo "  ✗ 200 秒内没回来 —— 探针条件为 FALSE 或内核挂住"
exit 3
