#!/bin/bash
# Control the TV's smart wall socket (Mi Home: 小米智能墙壁插座 zimi.plug.zncz01,
# named 电视插座 in the app; the cloud cache may still show 墙壁插座).
#
# THIS IS THE LAST RESORT.  The standing rule for this project:
#   1. static analysis first -- shrink to one or two candidate probes before
#      touching the TV at all;
#   2. prefer runs that RETURN -- a hanging run costs a power cycle;
#   3. only then the socket.  Every power cycle is wear on the PSU and storage.
#
# Reading state and switching OFF while Android is already dead is harmless.
# Switching OFF while Android is *running* is an unclean cut, so it is refused
# unless --force is given.
#
# !! CURRENTLY UNUSABLE: this socket is a Bluetooth Mesh 2.0 device.  mihome-ctl
# has no mesh/gateway support, the cloud rejects prop-set with -704220043 and the
# LAN path resolves a bogus public IP.  Toggle it in the Mi Home app, or by voice.
# Kept for when a cloud/gateway route works.  See confirmed-facts.md §34.27.
#
#   socket.sh status          read Switch Status (never switches)
#   socket.sh on              switch ON  (safe: it is already off)
#   socket.sh off             switch OFF, only if Android is NOT up
#   socket.sh off --force     switch OFF regardless
#   socket.sh cycle [secs]    OFF, wait (default 8), ON -- recovery from a hang
set -u
MIHOME=${MIHOME:-$HOME/.local/bin/mihome-ctl}
DID=${DID:-1043054088}
ADB=${ADB:-/home/emfox/Debian/tv/adb/platform-tools/adb}
TV=${TV:-192.168.10.60:5555}

st()   { "$MIHOME" prop-get --did "$DID" --siid 2 --piid 1 2>&1 | tail -1; }
set_() { "$MIHOME" prop-set --did "$DID" --siid 2 --piid 1 --value "$1" 2>&1 | tail -1; }
up()   { "$ADB" connect "$TV" >/dev/null 2>&1; \
	 [ "$("$ADB" -s "$TV" shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')" = 1 ]; }

case "${1:-status}" in
status)
	q=$(st); echo "socket: $q"
	if up; then echo "android: up"; else echo "android: not reachable"; fi
	;;
on)
	echo "socket ON  -> $(set_ true)"
	;;
off)
	if up && [ "${2:-}" != "--force" ]; then
		echo "refusing: Android is running; a socket cut is an unclean power loss" >&2
		echo "(pass --force if that is really what you want)" >&2
		exit 2
	fi
	echo "socket OFF -> $(set_ false)"
	;;
cycle)
	w=${2:-8}
	echo "== LAST RESORT: power cycle ($w s off)"
	echo "socket OFF -> $(set_ false)"
	sleep "$w"
	echo "socket ON  -> $(set_ true)"
	for i in $(seq 1 30); do
		up && { echo "android up at $(date +%H:%M:%S)"; exit 0; }
		sleep 2
	done
	echo "still not up after 60 s"; exit 1
	;;
*) echo "usage: socket.sh status|on|off [--force]|cycle [secs]" >&2; exit 1 ;;
esac
