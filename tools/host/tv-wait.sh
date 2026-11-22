#!/bin/bash
# tv-wait.sh [timeout_s] [--no-ir]
#
# Wait for Android after pushing a test image, and recover from a hang.
#
# Timing budget, measured rather than guessed: when a checkpoint returns, the
# handover boots Android in 8-12 s; when it hangs, Android never appears and the
# box sits on the boot logo until someone presses POWER.  So waiting minutes
# before the first IR press buys nothing.  The axis is inverted here: we wait
# only ~35 s, then press, then wait 60 s, press again, wait 60 s.
#
# Exit 0 = up (the "returned" or "(after IR)" suffix says which), 1 = down.
HERE=$(cd "$(dirname "$0")" && pwd)
ADB=/home/emfox/Debian/tv/adb/platform-tools/adb
TV=192.168.10.60:5555

TIMEOUT=60; IR=1
for a in "$@"; do
	case "$a" in
	--no-ir) IR=0 ;;
	''|*[!0-9]*) ;;
	*) TIMEOUT=$a ;;
	esac
done

# Cheap probe first: `get-state` is ~50 ms, while `exec-out su -c` is ~1.5 s and
# would dominate a 1 s poll.  No su needed for getprop.
ready(){
	local st
	st=$($ADB -s "$TV" get-state 2>/dev/null)
	if [ "$st" != device ]; then
		$ADB connect "$TV" >/dev/null 2>&1
		st=$($ADB -s "$TV" get-state 2>/dev/null)
	fi
	[ "$st" = device ] || return 1
	[ "$($ADB -s "$TV" shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')" = 1 ]
}

poll(){	# poll <seconds>: 0 as soon as Android answers
	local end=$(( $(date +%s) + $1 ))
	while [ "$(date +%s)" -lt "$end" ]; do
		ready && return 0
		sleep 1
	done
	return 1
}

press(){ "$HERE/tvpower.sh" on >/dev/null 2>&1 || echo "  !! IR send failed"; }

T0=$(date +%s); el(){ echo $(( $(date +%s) - T0 )); }

if [ "$IR" = 1 ] && [ "$TIMEOUT" -gt 35 ]; then PRE=35; else PRE=$TIMEOUT; fi

if poll "$PRE"; then echo "  android_up=yes ($(el)s)"; exit 0; fi

if [ "$IR" = 0 ]; then
	echo "  NO_RETURN ($(el)s, IR recovery disabled)"
	exit 1
fi

echo "  no Android after $(el)s -> POWER"
press
if poll 60; then echo "  android_up=after IR ($(el)s total)  [this run HUNG]"; exit 0; fi

echo "  still down at $(el)s -> POWER again"
press
if poll 60; then echo "  android_up=after 2nd IR ($(el)s total)  [this run HUNG]"; exit 0; fi

echo "  STILL DOWN ($(el)s) -- needs a physical power cycle"
exit 1
