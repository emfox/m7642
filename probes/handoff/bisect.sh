#!/bin/bash
# bisect.sh -- run a list of checkpoint images back to back, stop at the first hang.
#
#   bisect.sh <<LIST
#   0x463958 d0 ea3cb11cf33de93100120f70f8405700
#   0x463a04 c1 8ce80b0f82fe4d2be56802834e02a61d
#   LIST
#
# Each line: <image offset> <tag> <md5>.  Prints one row per checkpoint and
# exits non-zero at the first one that does not come back (that is the new
# upper bound of the bracket).
set -u
D=$(cd "$(dirname "$0")" && pwd)
ADB=/home/emfox/Debian/tv/adb/platform-tools/adb
TV=192.168.10.60:5555
OUT=$HOME/Debian/m7642-build/out
rc_all=0

while read -r off tag md5; do
	[ -n "${off:-}" ] || continue
	img=$OUT/m7642-rec-73-$tag.img
	[ -f "$img" ] || { echo "MISSING $img"; rc_all=1; break; }

	# device must be up before we can push
	for i in $(seq 1 40); do
		$ADB connect $TV >/dev/null 2>&1
		[ "$($ADB -s $TV shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')" = 1 ] && break
		sleep 2
	done

	$ADB -s $TV push "$img" /data/local/tmp/t.img >/dev/null 2>&1 || { echo "PUSH_FAIL $tag"; rc_all=1; break; }
	got=$($ADB -s $TV exec-out su -c "dd if=/data/local/tmp/t.img of=/dev/block/by-name/recovery bs=4096 2>/dev/null; sync; md5sum /dev/block/by-name/recovery" | tr -d '\r' | cut -d' ' -f1)
	[ "$got" = "$md5" ] || { echo "SLOT_MISMATCH $tag ($got)"; rc_all=1; break; }
	$ADB -s $TV exec-out su -c "dd if=/data/local/tmp/mark.bin of=/dev/block/by-name/misc bs=512 seek=16376 count=8 2>/dev/null; sync" >/dev/null 2>&1

	$ADB -s $TV reboot recovery >/dev/null 2>&1
	sleep 10
	line=$(timeout 300 "$D/../../tools/host/tv-wait.sh" 35 2>&1 | tr '\n' ' ')
	printf "%-6s %-8s %s\n" "$tag" "$off" "$line"

	case "$line" in
	*"[$]this run HUNG"*|*"this run HUNG"*|*NO_RETURN*|*STILL\ DOWN*)
		# hung: report whatever is in the record and stop
		$ADB -s $TV exec-out su -c "/vendor/bin/busybox rmmod probeRW 2>/dev/null; /vendor/bin/busybox insmod /data/local/tmp/probeRW.ko addr=0x23080000 len=32 op=r; rmmod probeRW; /vendor/bin/busybox cat /data/local/tmp/probeRW.out" 2>/dev/null | tr -d '\r' | grep '^0000' | head -2
		echo "STOP: $tag hung -> upper bound is $off"
		break
		;;
	*)
		# returned: pull the record for the report
		$ADB -s $TV exec-out su -c "/vendor/bin/busybox rmmod probeRW 2>/dev/null; /vendor/bin/busybox insmod /data/local/tmp/probeRW.ko addr=0x23080000 len=32 op=r; rmmod probeRW; /vendor/bin/busybox cat /data/local/tmp/probeRW.out" 2>/dev/null | tr -d '\r' | grep '^0000' | head -2 | sed 's/^/       /'
		;;
	esac
done
exit $rc_all
