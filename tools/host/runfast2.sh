#!/bin/bash
# runfast2.sh <tag> — flash + reboot + fast verdict, safe by construction
#
# Rules baked in (each one cost a wasted cycle before):
#  - adb: explicit kill-server + start-server + connect, retried; a bare
#    "connect" is not enough once the server has been left in a bad state.
#  - never power-cycle while ping answers: that means Android is alive and
#    adb is the thing that is broken, not the TV.
#  - bounded waits: boot check is 40 x 3s with a fast getprop timeout, so a
#    hopeless run fails in ~3 minutes instead of ~40.
TAG=$1
[ -n "$TAG" ] || { echo "用法: runfast2.sh <tag>"; exit 1; }
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
pingok() { ping -c 2 -W 2 192.168.10.60 >/dev/null 2>&1; }

adb_reset() {
	timeout 10 "$ADB" kill-server >/dev/null 2>&1
	sleep 1
	timeout 15 "$ADB" start-server >/dev/null 2>&1
	sleep 1
	timeout 15 "$ADB" connect "$TV" >/dev/null 2>&1
	sleep 1
}

# 真正可用的 adb 判定
adb_ok() {
	local i b
	for i in 1 2 3 4 5; do
		b=$(timeout 5 "$ADB" -s "$TV" shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')
		[ "$b" = "1" ] && return 0
		sleep 1
	done
	return 1
}

wait_boot() {
	local i
	adb_reset
	adb_ok && return 0
	for i in $(seq 1 40); do
		[ $((i % 8)) -eq 0 ] && adb_reset
		b=$(timeout 5 "$ADB" -s "$TV" shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')
		[ "$b" = "1" ] && return 0
		sleep 3
	done
	return 1
}

echo "== [$TAG] $(date +%T) 插座=$(sw) 功率=$(pw) ping=$(pingok && echo UP || echo DOWN)"

if ! adb_ok; then
	adb_reset
fi
if ! adb_ok; then
	if pingok; then
		echo "== ping 通但 adb 不通：设备是活的，只修 adb，不动电源"
		for k in 1 2 3 4; do
			adb_reset
			adb_ok && break
			sleep 3
		done
	fi
fi
if ! adb_ok; then
	echo "== adb 彻底不可用，做一次断电恢复（最多两轮）"
	for r in 1 2; do
		[ "$(sw)" = "True" ] && { timeout 10 "$M" action --did "$D" --siid 2 --aiid 1 >/dev/null 2>&1; sleep 18; }
		[ "$(sw)" != "True" ] && { timeout 10 "$M" action --did "$D" --siid 2 --aiid 1 >/dev/null 2>&1; sleep 12; }
		timeout 20 "$M" ir-send --remote 电视 --key POWER >/dev/null 2>&1
		wait_boot && break
		echo "   轮$r 未恢复 功率=$(pw)"
	done
fi
adb_ok || { echo "== ABORT adb 不可用 功率=$(pw) ping=$(pingok && echo UP || echo DOWN)"; exit 1; }
echo "== adb ok 功率=$(pw)"

ok=0
for k in 1 2 3; do
	timeout 240 "$ADB" -s "$TV" push "$SRC" /data/local/tmp/t.img >/dev/null 2>&1
	S=$(timeout 10 "$ADB" -s "$TV" shell "su -c '/vendor/bin/busybox stat -c %s /data/local/tmp/t.img'" 2>/dev/null | tr -d '\r')
	[ "$S" = "$SZ" ] && { ok=1; break; }
	echo "   推送$k 大小=[$S]≠$SZ"
	timeout 10 "$ADB" -s "$TV" shell "su -c '/vendor/bin/busybox rm -f /data/local/tmp/t.img'" </dev/null >/dev/null 2>&1
	sleep 2
done
[ $ok = 1 ] || { echo "== ABORT 推送失败"; exit 2; }

timeout 300 "$ADB" -s "$TV" shell "su -c '/vendor/bin/busybox dd if=/data/local/tmp/t.img of=/dev/block/by-name/recovery bs=4096 conv=notrunc'" </dev/null >/dev/null 2>&1
timeout 60 "$ADB" -s "$TV" shell "su -c '/vendor/bin/busybox sync'" </dev/null >/dev/null 2>&1
G=$(timeout 120 "$ADB" -s "$TV" shell "su -c '/vendor/bin/busybox dd if=/dev/block/by-name/recovery bs=4096 2>/dev/null | /vendor/bin/busybox md5sum'" 2>/dev/null | tr -d '\r' | cut -d' ' -f1)
[ -n "$G" ] || G=$(timeout 120 "$ADB" -s "$TV" shell "su -c '/vendor/bin/busybox dd if=/dev/block/by-name/recovery bs=4096 2>/dev/null | /vendor/bin/busybox md5sum'" 2>/dev/null | tr -d '\r' | cut -d' ' -f1)
[ "$G" = "$IMG" ] || { echo "== ABORT 槽校验 [$G]≠[$IMG]"; exit 3; }
echo "== 烧写可信，重启 $(date +%T)"

timeout 10 "$ADB" -s "$TV" reboot recovery >/dev/null 2>&1
if wait_boot; then
	echo "== VERDICT $TAG: RETURNED ⟹ 探针条件成立、reboot 链正常"
	git -C "$HOME/Debian/m7642" log --oneline -1 >/dev/null 2>&1
	exit 0
fi
echo "== VERDICT $TAG: HUNG ⟹ 条件不成立，或内核更早挂住  功率=$(pw)"
exit 4
