#!/bin/bash
# 一发探针（最简、少动部件）。
# 到达判据：stash magic "M764" 且 x30 == site+4（不看"设备回来了"）。
# 失败：等 WAIT 秒后仍无 Android ⟹ 插座恢复 + 判 ❌。
# usage: verify.sh <tag> [expected_x30]
ADB=/home/emfox/Debian/tv/adb/platform-tools/adb; TV=192.168.10.60:5555
OUT=$HOME/Debian/m7642-build/out
WAIT=${WAIT:-120}
TAG=$1; X30=${2:--}
SRC=$OUT/m7642-$TAG.img
[ -f "$SRC" ] || { echo "  找不到 $SRC"; exit 1; }
LOCAL=$(md5sum "$SRC" | cut -d' ' -f1)
BYTES=$(stat -c %s "$SRC")
BLOCKS=$(( (BYTES + 4095) / 4096 ))
conn(){ $ADB disconnect $TV >/dev/null 2>&1; $ADB connect $TV >/dev/null 2>&1; }
root(){ conn; $ADB -s $TV exec-out su -c "$1" </dev/null 2>/dev/null | tr -d '\r'; }
up(){ conn; [ "$($ADB -s $TV shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')" = 1 ]; }

up || { echo "  设备不在 Android，恢复中…"; $HOME/Debian/m7642/tools/host/socket.sh recover >/dev/null 2>&1; up || { echo "  恢复失败"; exit 1; }; }
conn
$ADB -s $TV push "$SRC" /data/local/tmp/t.img >/dev/null 2>&1 </dev/null || { echo "  推送失败"; exit 1; }
R=$($ADB -s $TV shell md5sum /data/local/tmp/t.img 2>/dev/null | tr -d '\r' | cut -d' ' -f1)
[ "$R" = "$LOCAL" ] || { echo "  推送校验失败 remote=$R local=$LOCAL"; exit 1; }
echo "  推送校验通过 ($BYTES 字节)"
root "dd if=/data/local/tmp/t.img of=/dev/block/by-name/recovery bs=4096 2>/dev/null; sync"
GOT=$(root "su -c 'dd if=/dev/block/by-name/recovery bs=4096 count=$BLOCKS 2>/dev/null' 2>/dev/null | head -c $BYTES | md5sum" | cut -d' ' -f1)
GOT2=$(root "dd if=/dev/block/by-name/recovery bs=4096 count=$BLOCKS 2>/dev/null | /vendor/bin/busybox head -c $BYTES | /vendor/bin/busybox md5sum" | cut -d' ' -f1)
echo "  槽内校验: $GOT2 (期望 $LOCAL)"
[ "$GOT2" = "$LOCAL" ] || { echo "  槽内不符，放弃"; exit 1; }

conn; $ADB -s $TV reboot recovery >/dev/null 2>&1 </dev/null
t0=$(date +%s)
for i in $(seq 1 $((WAIT/5))); do
	sleep 5
	if up; then
		echo "  $TAG: android up (+$(( $(date +%s) - t0 ))s)"
		root "/vendor/bin/busybox rmmod probeRW 2>/dev/null; /vendor/bin/busybox insmod /data/local/tmp/probeRW.ko addr=0x23080000 len=0xF0 op=r; rmmod probeRW; /vendor/bin/busybox cat /data/local/tmp/probeRW.out" | grep "^0000" > /tmp/rec-$TAG.txt
		python3 - "$TAG" "$X30" <<'PY'
import sys
tag, exp = sys.argv[1], sys.argv[2]
b=[]
for ln in open('/tmp/rec-%s.txt' % tag):
    if ln.startswith('0000'): b += [int(x,16) for x in ln.split(':')[1].split()]
if len(b) < 24: print("  ⟹ ⚠️ 记录读不到 ⟹ INCONCLUSIVE"); raise SystemExit
q=[int.from_bytes(bytes(b[i*8:(i+1)*8]),'little') for i in range(len(b)//8)]
m=q[0].to_bytes(8,"little"); x30=q[2]
ok = m[:4]==b"M764" and (exp=="-" or x30==int(exp,0))
print("  magic=%r x30=%#x 期望=%s" % (m[:6], x30, exp))
print("  ⟹ %s" % ("✅ 到达（stash 验证通过）" if ok else "⚠️ INCONCLUSIVE（stash 不符）"))
PY
		exit 0
	fi
done
echo "  $TAG: ${WAIT}s 内没起来 ⟹ ❌（插座恢复）"
$HOME/Debian/m7642/tools/host/socket.sh recover >/dev/null 2>&1
exit 2
