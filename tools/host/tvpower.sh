#!/bin/bash
# Press the TV's IR power key through the Mi Home cloud (Xiao AI speaker blaster).
#
# A POWER press while Android is running is a PM51 standby = hard power cut, so
# this refuses by default and only presses when the set is NOT running (#data
# safety).  Must run on the host: mihome-ctl keeps its 0600 session there.
#
#   tvpower.sh status        adb / ping state, never presses
#   tvpower.sh on            press, only if Android is NOT up
#   tvpower.sh on --force    press regardless (deliberate standby)
#   tvpower.sh off           same as `on --force`
set -u
ADB=${ADB:-/home/emfox/Debian/tv/adb/platform-tools/adb}
TV=${TV:-192.168.10.60:5555}
MIHOME=${MIHOME:-/home/emfox/.local/bin/mihome-ctl}
REMOTE=${REMOTE:-电视}
KEY=${KEY:-POWER}

up() {
    "$ADB" connect "$TV" >/dev/null 2>&1
    [ "$("$ADB" -s "$TV" shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')" = "1" ]
}
ut() { "$ADB" -s "$TV" shell cut -d. -f1 /proc/uptime 2>/dev/null | tr -d '\r'; }

case "${1:-status}" in
status)
    if up; then echo "android: up (uptime $(ut)s)"; else echo "android: not reachable (standby / hung / booting)"; fi
    if ping -c1 -W1 192.168.10.60 >/dev/null 2>&1; then echo "ping: ok"; else echo "ping: fail"; fi
    ;;
on)
    force=0; [ "${2:-}" = "--force" ] && force=1
    if up; then
        if [ "$force" != 1 ]; then
            echo "refusing: Android is running, a POWER press would be a hard power cut" >&2
            echo "(pass --force if a standby is really what you want)" >&2
            exit 2
        fi
        echo "warning: pressing POWER while Android is up (deliberate standby)"
    fi
    echo "press $REMOTE/$KEY at $(date +%H:%M:%S)"
    "$MIHOME" ir-send --remote "$REMOTE" --key "$KEY" || exit 1
    for i in $(seq 1 24); do
        sleep 5
        if up; then echo "android up at $(date +%H:%M:%S) (uptime $(ut)s)"; exit 0; fi
    done
    echo "still no adb after 120 s"; exit 3
    ;;
off) exec "$0" on --force ;;
*) echo "usage: $0 {status|on [--force]|off}" >&2; exit 1 ;;
esac
