#!/bin/bash
# TV smart socket (Mi Home "电视插座", model xiaomi.plug.mcn004, did 2188570626).
#
# NOTE: this is NOT did 1043054088 ("墙壁插座", zimi.plug.zncz01) -- that is a
# different socket and controlling it does nothing to the TV.  The device list
# in mihome-ctl is a *cache* (mi-tokens.json); refresh it with
#   python3 tools/host/refresh_tokens.py     (calls the cloud /home/device_list)
#
# Control: the cloud rejects /miotspec/prop/set for this plug (per-item code 1),
# so state is changed with the MIoT action  siid=2 aiid=1  "Switch · Toggle".
# Because the device only toggles, the reliable sequence is:
#     read state -> toggle only if needed -> poll state until it flipped
# The switch state (siid 2 piid 1) is readable and is what we poll; the power
# reading (siid 3 piid 2) is too coarse (0..4 W in standby) to be a signal.
#
# RECOVERY (user's procedure, timings matter):
#     power OFF -> wait 10 s -> power ON -> wait 3 s -> IR POWER
set -u
M=${MIHOME:-$HOME/.local/bin/mihome-ctl}
D=${DID:-2188570626}
ADB=${ADB:-/home/emfox/Debian/tv/adb/platform-tools/adb}
TV=${TV:-192.168.10.60:5555}
export PATH=$HOME/.local/bin:$PATH

sw(){ $M prop-get --did "$D" --siid 2 --piid 1 2>/dev/null | tail -1 | sed 's/.*= //'; }
pw(){ $M prop-get --did "$D" --siid 3 --piid 2 2>/dev/null | tail -1 | sed 's/.*= //'; }
tog(){ $M action --did "$D" --siid 2 --aiid 1 >/dev/null 2>&1; }
up(){ $ADB connect "$TV" >/dev/null 2>&1; [ "$("$ADB" -s "$TV" shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')" = 1 ]; }

setstate(){	# $1 = True|False ; poll up to 25 s
	local want=$1 i
	[ "$(sw)" = "$want" ] && { echo "already $want"; return 0; }
	tog
	for i in $(seq 1 25); do
		[ "$(sw)" = "$want" ] && { echo "-> $want (after ${i}s)"; return 0; }
		sleep 1
	done
	echo "!! state did not become $want (now $(sw))" >&2; return 1
}

case "${1:-status}" in
status) echo "socket sw=$(sw) power=$(pw)"; up && echo "android: up" || echo "android: not reachable" ;;
on)  setstate True ;;
off) setstate False ;;
# power on and press IR 3 s after the switch really closes
wake)
	setstate True && sleep 3 && { echo "== IR POWER"; $HOME/Debian/m7642/tools/host/tvpower.sh on --force 2>&1 | tail -1; } ;;
recover)
	echo "== 1) power OFF"; setstate False
	echo "== 2) wait 10 s"; sleep 10
	echo "== 3) power ON" ; setstate True
	echo "== 4) wait 3 s then IR POWER"; sleep 3
	$HOME/Debian/m7642/tools/host/tvpower.sh on --force 2>&1 | tail -1
	echo "== 5) wait for android"
	for i in $(seq 1 60); do up && { echo "   android up (+$((i*2))s)"; exit 0; }; sleep 2; done
	echo "   NOT up (sw=$(sw) power=$(pw))"; exit 1 ;;
*) echo "usage: socket.sh status|on|off|wake|recover" >&2; exit 1 ;;
esac
