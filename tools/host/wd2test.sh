#!/bin/bash
set -u
ADB=/home/emfox/Debian/tv/adb/platform-tools/adb
TV=192.168.10.60:5555
dev() { $ADB -s $TV shell "$@"; }
root() { $ADB -s $TV exec-out su -c "$1"; }
$ADB connect $TV >/dev/null 2>&1
[ "$(dev getprop sys.boot_completed 2>/dev/null | tr -d '\r')" = 1 ] || { echo "not in Android"; exit 1; }
echo "uptime $(dev cut -d. -f1 /proc/uptime | tr -d '\r')s"
$ADB -s $TV push "$HOME/Debian/m7642/probes/wdtarm/wdtarm2.ko" /data/local/tmp/wdtarm2.ko >/dev/null
root 'echo M7642WDT2 > /dev/pmsg0' >/dev/null
root '/vendor/bin/busybox rmmod probeRW 2>/dev/null; /vendor/bin/busybox insmod /data/local/tmp/probeRW.ko addr=0x419c0000 len=16 op=r; rmmod probeRW; /vendor/bin/busybox cat /data/local/tmp/probeRW.out' | tr -d '\r' | tail -2
echo "=== arm at $(date +%H:%M:%S)"
root 'rmmod wdtarm2 2>/dev/null; /vendor/bin/busybox insmod /data/local/tmp/wdtarm2.ko secs=10; rmmod wdtarm2; dmesg | /vendor/bin/busybox grep wdtarm2 | /vendor/bin/busybox tail -3' | tr -d '\r'
echo "=== waiting up to 120 s for a reset + Android"
for i in $(seq 1 24); do
  sleep 5
  $ADB connect $TV >/dev/null 2>&1
  s=$(dev getprop sys.boot_completed 2>/dev/null | tr -d '\r')
  if [ "$s" = 1 ]; then
    u=$(dev cut -d. -f1 /proc/uptime | tr -d '\r')
    if [ "${u:-999}" -lt 100 ]; then echo "=== RESET + Android at $(date +%H:%M:%S) uptime ${u}s"; break; fi
  fi
done
echo "--- pstore"; root 'ls -l /sys/fs/pstore/' | tr -d '\r'
root 'od -A d -t c /sys/fs/pstore/pmsg-ramoops-0 2>&1 | head -3' | tr -d '\r'
echo "--- zone raw"
root '/vendor/bin/busybox rmmod probeRW 2>/dev/null; /vendor/bin/busybox insmod /data/local/tmp/probeRW.ko addr=0x419c0000 len=32 op=r; rmmod probeRW; /vendor/bin/busybox cat /data/local/tmp/probeRW.out' | tr -d '\r' | tail -3
