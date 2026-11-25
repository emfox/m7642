#!/bin/bash
# run-tag.sh <tag> [reader.sh]
#
# Trustworthy single-run cycle.  The hard-won lessons baked in:
#   * unique remote filename per tag (a stale /data/local/tmp/t.img used to
#     silently mask a failed adb push, which made dozens of runs meaningless)
#   * mandatory push md5 verification - abort if it does not match
#   * inner single quotes for su -c (double quotes fail silently)
#   * dd with conv=notrunc, then verify the slot content
set -u
TAG=${1:?用法: run-tag.sh <tag> [reader.sh]}
READER=${2:-}
ADB=/home/emfox/Debian/tv/adb/platform-tools/adb
TV=192.168.10.60:5555
SRC=$HOME/Debian/m7642-build/out/m7642-$TAG.img
REMOTE=/data/local/tmp/$TAG.img

have() { [ "$(timeout 5 $ADB -s $TV shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')" = "1" ]; }

[ -f "$SRC" ] || { echo "  ✗ 镜像不存在: $SRC"; exit 1; }
timeout 6 $ADB connect $TV >/dev/null 2>&1
have || { echo "  ✗ 设备未就绪"; exit 1; }

echo "  本地 md5: $(md5sum "$SRC" | cut -d' ' -f1)  ($(stat -c %s "$SRC") 字节)"

timeout 180 $ADB -s $TV push "$SRC" "$REMOTE" >/dev/null 2>&1
R=$(timeout 30 $ADB -s $TV shell "su -c '/vendor/bin/busybox md5sum $REMOTE'" </dev/null 2>/dev/null | tr -d '\r' | cut -d' ' -f1)
echo "  推送 md5: $R"
[ "$R" = "$(md5sum "$SRC" | cut -d' ' -f1)" ] || { echo "  ✗ 推送校验失败 —— 不烧写"; exit 1; }

OUT=$(timeout 240 $ADB -s $TV shell "su -c '/vendor/bin/busybox dd if=$REMOTE of=/dev/block/by-name/recovery bs=4096 conv=notrunc'" </dev/null 2>&1 | tr -d '\r' | tail -1)
echo "  dd: $OUT"
case "$OUT" in *bytes*) ;; *) echo "  ✗ dd 未确认"; exit 1 ;; esac
timeout 60 $ADB -s $TV shell "su -c '/vendor/bin/busybox sync'" </dev/null >/dev/null 2>&1

EXPECT=$(head -c 4096 "$SRC" | md5sum | cut -d' ' -f1)
GOT=$(timeout 40 $ADB -s $TV shell "su -c '/vendor/bin/busybox dd if=/dev/block/by-name/recovery bs=4096 count=1 2>/dev/null | /vendor/bin/busybox md5sum'" </dev/null 2>/dev/null | tr -d '\r' | cut -d' ' -f1)
echo "  槽前4K: $GOT  (期望 $EXPECT)"
[ "$GOT" = "$EXPECT" ] || { echo "  ✗ 槽校验失败 —— 不产生任何结论"; exit 1; }
echo "  ✓ 烧写可信，重启进入我们的内核"

timeout 10 $ADB -s $TV reboot recovery >/dev/null 2>&1
OK=0
for i in $(seq 1 20); do
  sleep 5
  timeout 6 $ADB connect $TV >/dev/null 2>&1
  have && { echo "  ✓ 回到 Android (+$((i*5))s)"; OK=1; break; }
done
[ "$OK" = "1" ] || { echo "  ✗ 100 秒内没回来"; exit 2; }

[ -n "$READER" ] && { echo "=== 数据:"; bash "$READER"; }
exit 0
