#!/bin/bash
# runfast.sh <tag> — flash + reboot + fast verdict
# Verdict channel is the 1-bit channel: the probe reboots iff its condition holds.
# Judge quickly: one adb connect, then poll getprop every 3s for up to 4 minutes.
# adb returning empty is normal here, so every read is retried; a timeout means
# the device never came back (our kernel is still running).
TAG=$1
[ -n "$TAG" ] || { echo "用法: runfast.sh <tag>"; exit 1; }
ADB=$HOME/Debian/tv/adb/platform-tools/adb
TV=192.168.10.60:5555
M=$HOME/.local/bin/mihome-ctl
D=2188570626
SRC=$HOME/Debian/m7642-build/out/m7642-$TAG.img
[ -f "$SRC" ] || { echo "== 镜像不存在: $SRC"; exit 1; }
IMG=$(md5sum "$SRC" | cut -d' ' -f1)
SZ=$(stat -c %s "$SRC")

pw() { timeout 6 "$M" prop-get --did "$D" --siid 3 --piid 2 2>/dev/null | tail -1 | sed 's/.*= //'; }
sw() { timeout 6 "$M" prop-get --did "$D" --siid 2 --piid 1 2>/dev/null | tail -1 | sed 's/.*= //'; }

sho() {
	local v t
	for t in 1 2 3; do
		v=$(timeout 8 "$ADB" -s "$TV" shell "$1" 2>/dev/null | tr -d '\r')
		[ -n "$v" ] && { echo "$v"; return 0; }
		sleep 1
	done
	return 1
}

# 快判定：一次 connect，然后密集轮询
wait_android() {
	local i
	timeout 8 "$ADB" kill-server >/dev/null 2>&1; sleep 1
	timeout 10 "$ADB" connect "$TV" >/dev/null 2>&1; sleep 1
	for i in $(seq 1 80); do
		[ "$(timeout 6 "$ADB" -s "$TV" shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')" = "1" ] && return 0
		sleep 3
	done
	return 1
}

echo "== [$TAG] 起始 插座=$(sw) 功率=$(pw)"
if ! wait_android; then
	echo "== 设备不在 Android，断电恢复"
	for r in 1 2 3; do
		[ "$(sw)" = "True" ] && { timeout 10 "$M" action --did "$D" --siid 2 --aiid 1 >/dev/null 2>&1; sleep 15; }
		[ "$(sw)" != "True" ] && { timeout 10 "$M" action --did "$D" --siid 2 --aiid 1 >/dev/null 2>&1; sleep 12; }
		timeout 20 "$M" ir-send --remote 电视 --key POWER >/dev/null 2>&1
		wait_android && { echo "== 恢复 ok"; break; }
		echo "   轮$r 未恢复 功率=$(pw)"
	done
fi
wait_android || { echo "== ABORT 无法恢复设备"; exit 1; }
echo "== adb ok 功率=$(pw) 镜像 $IMG"

ok=0
for k in 1 2 3; do
	timeout 240 "$ADB" -s "$TV" push "$SRC" /data/local/tmp/t.img >/dev/null 2>&1
	S=$(sho "su -c '/vendor/bin/busybox stat -c %s /data/local/tmp/t.img'")
	[ "$S" = "$SZ" ] && { ok=1; break; }
	echo "   推送$k 大小=[$S]≠$SZ 重试"
	timeout 10 "$ADB" -s "$TV" shell "su -c '/vendor/bin/busybox rm -f /data/local/tmp/t.img'" </dev/null >/dev/null 2>&1
	sleep 2
done
[ $ok = 1 ] || { echo "== ABORT 推送失败"; exit 2; }
P=$(sho "su -c '/vendor/bin/busybox md5sum /data/local/tmp/t.img'")
P=$(echo "$P" | cut -d' ' -f1)
[ "$P" = "$IMG" ] || { echo "== ABORT 推送 md5 [$P]≠[$IMG]"; exit 2; }

timeout 300 "$ADB" -s "$TV" shell "su -c '/vendor/bin/busybox dd if=/data/local/tmp/t.img of=/dev/block/by-name/recovery bs=4096 conv=notrunc'" </dev/null >/dev/null 2>&1
timeout 60 "$ADB" -s "$TV" shell "su -c '/vendor/bin/busybox sync'" </dev/null >/dev/null 2>&1
G=$(sho "su -c '/vendor/bin/busybox dd if=/dev/block/by-name/recovery bs=4096 2>/dev/null | /vendor/bin/busybox md5sum'")
G=$(echo "$G" | cut -d' ' -f1)
[ "$G" = "$IMG" ] || { echo "== ABORT 槽校验 [$G]≠[$IMG]"; exit 3; }
echo "== 烧写可信，重启 $(date +%H:%M:%S)"

timeout 10 "$ADB" -s "$TV" reboot recovery >/dev/null 2>&1
if wait_android; then
	echo "== VERDICT $TAG: RETURNED ⟹ 探针条件成立、reboot 链正常"
	exit 0
fi
echo "== VERDICT $TAG: HUNG ⟹ 条件不成立，或内核更早挂住  功率=$(pw)"
exit 4
