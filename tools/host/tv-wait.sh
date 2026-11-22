#!/bin/bash
# Wait for Android, and if it does not come up, press the IR power key and wait
# again -- no human, no unplugging.
#
# A hung image leaves this TV in standby (measured repeatedly on 2026-11-22).
# Recovery is a single IR POWER press: standby -> Android in ~25 s.  That is
# fully scriptable, so every runner can recover itself.
#
#   tv-wait.sh [timeout_s] [--no-ir] [--probe-first]
#
# Exit 0 = Android is up; 1 = still not up after the recovery attempt.
# Prints one line saying how it went, so the caller can record "this run hung".
set -u
ADB=/home/emfox/Debian/tv/adb/platform-tools/adb
TV=192.168.10.60:5555
HERE=$(cd "$(dirname "$0")" && pwd)

TIMEOUT=300
IR=1
PROBE_FIRST=0
for a in "$@"; do
	case "$a" in
	--no-ir) IR=0 ;;
	--probe-first) PROBE_FIRST=1 ;;
	''|*[!0-9]*) ;;
	*) TIMEOUT=$a ;;
	esac
done

ready(){ $ADB connect $TV >/dev/null 2>&1; \
	[ "$($ADB -s $TV exec-out su -c 'getprop sys.boot_completed' 2>/dev/null | tr -d '\r')" = 1 ]; }
pingable(){ ping -c1 -W1 "${TV%%:*}" >/dev/null 2>&1; }

# A recovering device may be reachable for adb long before boot_completed.
wait_up(){	# wait_up <seconds>; 0 if up
	local n=$(( $1 / 3 ))
	while [ $n -gt 0 ]; do
		ready && return 0
		sleep 3
		n=$(( n - 1 ))
	done
	return 1
}

T0=$(date +%s)
if wait_up "$TIMEOUT"; then
	echo "  android_up=yes ($(( $(date +%s) - T0 ))s)"
	exit 0
fi

# not up: either the image hung (device in standby) or the boot is just slow
if [ "$IR" = 1 ]; then
	if pingable && ! $ADB connect $TV >/dev/null 2>&1; then
		echo "  not up, but the box answers ping -- waiting a bit longer before IR"
		wait_up 120 && { echo "  android_up=yes ($(( $(date +%s) - T0 ))s, late)"; exit 0; }
	fi
	echo "  HUNG (no Android after $(( $(date +%s) - T0 ))s) -> IR power key"
	"$HERE/tvpower.sh" on >/dev/null 2>&1 || echo "  !! IR send failed"
	if wait_up 240; then
		echo "  android_up=yes after IR ($(( $(date +%s) - T0 ))s total)  [this run hung]"
		exit 0
	fi
	echo "  STILL DOWN after IR ($(( $(date +%s) - T0 ))s) -- needs a physical power cycle"
	exit 1
fi

echo "  NO_RETURN ($(( $(date +%s) - T0 ))s, IR recovery disabled)"
exit 1
