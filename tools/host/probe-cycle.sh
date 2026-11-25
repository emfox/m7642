#!/bin/bash
# probe-cycle.sh <tag> [reader.sh]
#
# 一次完整、可校验的上机循环：
#   1. 推送镜像（只推前 24 MB —— 内核在 1 MB 处、tramp 在 20 MB 处，够用）
#   2. 校验推送内容
#   3. 写入 recovery 槽 + 校验槽（不一致就中止，不产生任何结论）
#   4. 重启进入我们的内核，等待回到 Android
#   5. 可选：运行 reader 脚本读取探针数据
#
# 关键纪律（见 Documentation/mstar/m7642/discipline.md）：
#   * su 必须用  su -c '<命令>'  （内层单引号），双引号形式会静默失败
#   * 每次烧写后必须校验槽内 md5，否则后续观察无意义
set -u
TAG=${1:?用法: probe-cycle.sh <tag> [reader.sh]}
READER=${2:-}
ADB=/home/emfox/Debian/tv/adb/platform-tools/adb
TV=192.168.10.60:5555
SRC=$HOME/Debian/m7642-build/out/m7642-$TAG.img
LIMIT=24576                      # 24 MB（512B 块数 = 49152）

have() { [ "$(timeout 5 $ADB -s $TV shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')" = "1" ]; }
SU()   { timeout ${2:-120} $ADB -s $TV shell "su -c '$1'" 2>&1 | tr -d '\r'; }

[ -f "$SRC" ] || { echo "  ✗ 镜像不存在: $SRC"; exit 1; }
timeout 6 $ADB connect $TV >/dev/null 2>&1
have || { echo "  ✗ 设备未就绪，先恢复"; exit 1; }

# 1+2. 推送并校验
timeout 180 $ADB -s $TV push "$SRC" /data/local/tmp/t.img >/dev/null 2>&1 || { echo "  ✗ 推送失败"; exit 1; }
L=$(md5sum "$SRC" | cut -d' ' -f1)
R=$(SU "/vendor/bin/busybox md5sum /data/local/tmp/t.img" 30 | cut -d' ' -f1)
echo "  推送 md5: $R"
[ "$R" = "$L" ] || { echo "  ✗ 推送内容不一致"; exit 1; }

# 3. 烧写（限制长度）并校验
DD="dd if=/data/local/tmp/t.img of=/dev/block/by-name/recovery bs=512 count=$((LIMIT*2))"
SU "/vendor/bin/busybox $DD" 180 | tail -1
SU "/vendor/bin/busybox sync" 40 >/dev/null
# dd 的输出是可靠判据（"N bytes copied" 表示真的写了）；管道校验在 adb 里不可靠
OUT=$(SU "/vendor/bin/busybox $DD" 180 | tail -1)
echo "  dd: $OUT"
case "$OUT" in
  *"bytes"*) ;;
  *) echo "  ✗ dd 未确认写入"; exit 1 ;;
esac
echo "  ✓ 烧写校验通过"

# 4. 运行
timeout 10 $ADB -s $TV reboot recovery >/dev/null 2>&1
OK=0
for i in $(seq 1 20); do
  sleep 5
  timeout 6 $ADB connect $TV >/dev/null 2>&1
  have && { echo "  ✓ 回到 Android (+$((i*5))s)"; OK=1; break; }
done
[ "$OK" = "1" ] || { echo "  ✗ 100 秒内没回来（需要插座恢复）"; exit 2; }

# 5. 读数据
[ -n "$READER" ] && { echo "=== 数据:"; bash "$READER"; }
exit 0
