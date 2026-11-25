#!/bin/bash
# runone.sh <tag> — recover, flash with size+md5 proof, reboot, judge by adb with retries
# Verdict channel: the 1-bit channel (probe reboots iff condition true).
# Judged by adb with retries, because adb on this device silently returns empty.
TAG=$1
[ -n "$TAG" ] || { echo "用法: runone.sh <tag>"; exit 1; }

ADB=/home/emfox/Debian/tv/adb/platform-tools/adb
TV=192.168.10.60:5555
M=$HOME/.local/bin/mihome-ctl
D=2188570626
SRC=$HOME/Debian/m7642-build/out/m7642-$TAG.img
[ -f "$SRC" ] || { echo "== 镜像不存在: $SRC"; exit 1; }
IMG=$(md5sum "$SRC" | cut -d' ' -f1)
SZ=$(stat -c %s "$SRC")

pw() { timeout 8 "$M" prop-get --did "$D" --siid 3 --piid 2 2>/dev/null | tail -1 | sed 's/.*= //'; }
sw() { timeout 8 "$M" prop-get --did "$D" --siid 2 --piid 1 2>/dev/null | tail -1 | sed 's/.*= //'; }
pingok() { ping -c 2 -W 2 192.168.10.60 >/dev/null 2>&1; }

sho() {
	local v t
	for t in 1 2 3; do
		v=$(timeout 10 "$ADB" -s "$TV" shell "$1" 2>/dev/null | tr -d '\r')
		[ -n "$v" ] && { echo "$v"; return 0; }
		sleep 2
	done
	return 1
}

adbup() {
	local i
	for i in 1 2 3 4; do
		timeout 8 "$ADB" kill-server >/dev/null 2>&1; sleep 2
		timeout 12 "$ADB" connect "$TV" >/dev/null 2>&1; sleep 2
		[ "$(sho 'getprop sys.boot_completed')" = "1" ] && return 0
	done
	return 1
}

echo "== [$TAG] 初始 插座=$(sw) 功率=$(pw) ping=$(pingok && echo UP || echo DOWN)"

if ! adbup; then
	echo "== 尝试恢复（必须断电：我们的内核卡住时只有切电能救）"
	for r in 1 2 3 4; do
		# 确保插座处于上电状态
		[ "$(sw)" != "True" ] && { timeout 15 "$M" action --did "$D" --siid 2 --aiid 1 >/dev/null 2>&1; sleep 10; }
		# 断电 15 秒
		echo "   轮$r 断电"
		[ "$(sw)" = "True" ] && { timeout 15 "$M" action --did "$D" --siid 2 --aiid 1 >/dev/null 2>&1; }
		sleep 15
		# 上电
		echo "   轮$r 上电"
		[ "$(sw)" != "True" ] && { timeout 15 "$M" action --did "$D" --siid 2 --aiid 1 >/dev/null 2>&1; }
		sleep 12
		timeout 25 "$M" ir-send --remote 电视 --key POWER >/dev/null 2>&1
		for i in $(seq 1 24); do sleep 5; adbup && break; done
		adbup && { echo "== 恢复 ok"; break; }
		echo "   轮$r 未恢复 功率=$(pw) ping=$(pingok && echo UP || echo DOWN)"
	done
fi

adbup || { echo "== ABORT 无法恢复设备 功率=$(pw)"; exit 1; }
echo "== adb ok 功率=$(pw) 镜像 $IMG ($SZ 字节)"

ok=0
for k in 1 2 3; do
	timeout 240 "$ADB" -s "$TV" push "$SRC" /data/local/tmp/t.img >/dev/null 2>&1
	S=$(sho "su -c '/vendor/bin/busybox stat -c %s /data/local/tmp/t.img'")
	if [ "$S" = "$SZ" ]; then ok=1; break; fi
	echo "   推送$k 设备大小=[$S] 期望=$SZ，重试"
	timeout 15 "$ADB" -s "$TV" shell "su -c '/vendor/bin/busybox rm -f /data/local/tmp/t.img'" </dev/null >/dev/null 2>&1
	sleep 3
done
[ $ok = 1 ] || { echo "== ABORT 推送失败"; exit 2; }

P=$(sho "su -c '/vendor/bin/busybox md5sum /data/local/tmp/t.img'")
P=$(echo "$P" | cut -d' ' -f1)
if [ "$P" = "$IMG" ]; then
	echo "== 推送 md5 一致"
else
	echo "== ABORT 推送 md5 [$P] != [$IMG]"; exit 2
fi

timeout 300 "$ADB" -s "$TV" shell "su -c '/vendor/bin/busybox dd if=/data/local/tmp/t.img of=/dev/block/by-name/recovery bs=4096 conv=notrunc'" </dev/null >/dev/null 2>&1
timeout 60 "$ADB" -s "$TV" shell "su -c '/vendor/bin/busybox sync'" </dev/null >/dev/null 2>&1
G=$(sho "su -c '/vendor/bin/busybox dd if=/dev/block/by-name/recovery bs=4096 2>/dev/null | /vendor/bin/busybox md5sum'")
G=$(echo "$G" | cut -d' ' -f1)
if [ "$G" = "$IMG" ]; then
	echo "== 槽 md5 一致 ✓ 烧写可信"
else
	echo "== ABORT 槽 [$G] != [$IMG]"; exit 3
fi

echo "== 重启 $(date +%H:%M:%S)"
timeout 10 "$ADB" -s "$TV" reboot recovery >/dev/null 2>&1
echo "== 判定：adb 多次重试（空读不算）"
for i in $(seq 1 50); do
	sleep 6
	if adbup; then
		echo "== VERDICT $TAG: RETURNED t≈$((i*6))s ⟹ 条件成立、reboot 链正常"
		exit 0
	fi
	if [ $((i % 8)) -eq 0 ]; then
		echo "   t=$((i*6))s 未回 功率=$(pw) ping=$(pingok && echo UP || echo DOWN)"
	fi
done
echo "== VERDICT $TAG: HUNG ⟹ 条件不成立（或内核更早挂住） 功率=$(pw)"
exit 4
