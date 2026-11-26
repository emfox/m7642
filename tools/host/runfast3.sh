#!/bin/bash
# runfast3.sh <tag> — flash + restart + verdict, with the timings we actually need
#
# Power cycle: 10s off, power on, 3s later the IR power key (as the user
# specified - anything longer is just wasted wall-clock).
# Boot wait: 5 minutes with an adb reconnect every ~20s.  Android needs about
# 100-115s after the restart plus WiFi association, so a 3 minute window was
# giving false "hung" verdicts.
TAG=$1
[ -n "$TAG" ] || { echo "用法: runfast3.sh <tag>"; exit 1; }
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

adb_reset() {
	timeout 8 "$ADB" kill-server >/dev/null 2>&1
	timeout 10 "$ADB" start-server >/dev/null 2>&1
	timeout 10 "$ADB" connect "$TV" >/dev/null 2>&1
}
adb_boot() {
	local b
	b=$(timeout 5 "$ADB" -s "$TV" shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')
	[ "$b" = "1" ]
}

# 按用户给的最短时序恢复
power_cycle() {
	echo "   断电 10s"
	[ "$(sw)" = "True" ] && { timeout 8 "$M" action --did "$D" --siid 2 --aiid 1 >/dev/null 2>&1; }
	sleep 10
	echo "   上电 + 3s 后红外"
	[ "$(sw)" != "True" ] && { timeout 8 "$M" action --did "$D" --siid 2 --aiid 1 >/dev/null 2>&1; }
	sleep 3
	timeout 15 "$M" ir-send --remote 电视 --key POWER >/dev/null 2>&1
}

# 等 Android：5 分钟，期间定期重连
wait_boot() {
	local i
	for i in $(seq 1 60); do
		if [ $((i % 5)) -eq 1 ]; then adb_reset; fi
		adb_boot && return 0
		sleep 5
	done
	return 1
}

echo "== [$TAG] $(date +%T) 功率=$(pw) ping=$(ping -c 1 -W 1 192.168.10.60 >/dev/null 2>&1 && echo UP || echo DOWN)"
adb_reset
if ! adb_boot; then
	echo "== 需要恢复"
	power_cycle
	wait_boot || { echo "== ABORT 无法恢复 adb 功率=$(pw)"; exit 1; }
fi
echo "== adb ok $(date +%T) 功率=$(pw)"

ok=0
for k in 1 2 3; do
	timeout 240 "$ADB" -s "$TV" push "$SRC" /data/local/tmp/t.img >/dev/null 2>&1
	S=$(timeout 10 "$ADB" -s "$TV" shell "su -c '/vendor/bin/busybox stat -c %s /data/local/tmp/t.img'" 2>/dev/null | tr -d '\r')
	[ "$S" = "$SZ" ] && { ok=1; break; }
	echo "   推送$k 大小=[$S]≠$SZ"
	sleep 2
done
[ $ok = 1 ] || { echo "== ABORT 推送失败"; exit 2; }

timeout 300 "$ADB" -s "$TV" shell "su -c '/vendor/bin/busybox dd if=/data/local/tmp/t.img of=/dev/block/by-name/recovery bs=4096 conv=notrunc'" </dev/null >/dev/null 2>&1
timeout 60 "$ADB" -s "$TV" shell "su -c '/vendor/bin/busybox sync'" </dev/null >/dev/null 2>&1
G=$(timeout 120 "$ADB" -s "$TV" shell "su -c '/vendor/bin/busybox dd if=/dev/block/by-name/recovery bs=4096 2>/dev/null | /vendor/bin/busybox md5sum'" 2>/dev/null | tr -d '\r' | cut -d' ' -f1)
[ "$G" = "$IMG" ] || { echo "== ABORT 槽校验 [$G]≠[$IMG]"; exit 3; }
echo "== 烧写可信 $(date +%T)，重启"
timeout 10 "$ADB" -s "$TV" reboot recovery >/dev/null 2>&1

if wait_boot; then
	echo "== VERDICT $TAG: RETURNED $(date +%T)"
	exit 0
fi
echo "== VERDICT $TAG: HUNG $(date +%T) 功率=$(pw)"
exit 4
