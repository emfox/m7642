#!/bin/bash
set -u
ADB=/home/emfox/Debian/tv/adb/platform-tools/adb
TV=192.168.10.60:5555
dev() { $ADB -s $TV shell "$@"; }
root() { $ADB -s $TV exec-out su -c "$1"; }
$ADB connect $TV >/dev/null 2>&1
[ "$(dev getprop sys.boot_completed 2>/dev/null | tr -d '\r')" = 1 ] || { echo "not in Android"; exit 1; }
echo "uptime before: $(dev cut -d. -f1 /proc/uptime | tr -d '\r')s"
$ADB -s $TV push "$HOME/Debian/m7642/probes/wdtarm/wdtarm.ko" /data/local/tmp/wdtarm.ko >/dev/null
root 'echo M7642WDT1 > /dev/pmsg0; echo "pmsg rc=$?"' | tr -d '\r'
echo "--- zone before reset"
root '/vendor/bin/busybox rmmod probeRW 2>/dev/null; /vendor/bin/busybox insmod /data/local/tmp/probeRW.ko addr=0x419c0000 len=32 op=r; rmmod probeRW; cat /data/local/tmp/probeRW.out' | tr -d '\r' | tail -2
echo "=== arming watchdog at $(date +%H:%M:%S)"
root '/vendor/bin/busybox rmmod wdtarm 2>/dev/null; /vendor/bin/busybox insmod /data/local/tmp/wdtarm.ko secs=10; echo "insmod rc=$?"; /vendor/bin/busybox rmmod wdtarm; echo "rmmod rc=$?"' | tr -d '\r'
sleep 2
echo "--- dmesg (wdtarm)"
dev 'dmesg | grep -i wdtarm | tail -5' | tr -d '\r'
echo "--- dmesg (wdt)"
dev 'dmesg | grep -i -E "wdt|watchdog" | tail -5' | tr -d '\r'
