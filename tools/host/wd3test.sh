#!/bin/bash
set -u
ADB=/home/emfox/Debian/tv/adb/platform-tools/adb
TV=192.168.10.60:5555
dev() { $ADB -s $TV shell "$@"; }
root() { $ADB -s $TV exec-out su -c "$1"; }
$ADB connect $TV >/dev/null 2>&1
boot=$(dev getprop sys.boot_completed 2>/dev/null | tr -d '\r'); [ "$boot" = 1 ] || { echo "not in Android"; exit 1; }
u0=$(dev cut -d. -f1 /proc/uptime | tr -d '\r'); echo "uptime before $u0 s"
$ADB -s $TV push "$HOME/Debian/m7642/probes/wdtarm/wdtarm3.ko" /data/local/tmp/wdtarm3.ko >/dev/null
root 'echo M7642WDT3 > /dev/pmsg0' >/dev/null
for ch in 0 3; do
  echo "=== ch=$ch arm at $(date +%H:%M:%S)"
  root "rmmod wdtarm3 2>/dev/null; /vendor/bin/busybox insmod /data/local/tmp/wdtarm3.ko ch=$ch secs=10; rmmod wdtarm3; dmesg | /vendor/bin/busybox grep wdtarm3 | /vendor/bin/busybox tail -4" | tr -d '\r'
  for i in $(seq 1 6); do
    sleep 5
    $ADB connect $TV >/dev/null 2>&1
    u=$(dev cut -d. -f1 /proc/uptime 2>/dev/null | tr -d '\r')
    if [ -n "${u:-}" ] && [ "${u:-9999}" -lt "${u0:-0}" ]; then
      echo "=== DEVICE RESET at $(date +%H:%M:%S) (uptime ${u}s) -- waiting for Android"
      for j in $(seq 1 20); do
        sleep 5; $ADB connect $TV >/dev/null 2>&1
        s=$(dev getprop sys.boot_completed 2>/dev/null | tr -d '\r')
        [ "$s" = 1 ] && { echo "=== Android at $(date +%H:%M:%S) uptime $(dev cut -d. -f1 /proc/uptime | tr -d '\r')s"; break; }
      done
      echo "--- pstore"; root 'ls -l /sys/fs/pstore/' | tr -d '\r'
      root 'od -A d -t c /sys/fs/pstore/pmsg-ramoops-0 2>&1 | head -3' | tr -d '\r'
      echo "--- zone raw"
      root '/vendor/bin/busybox rmmod probeRW 2>/dev/null; /vendor/bin/busybox insmod /data/local/tmp/probeRW.ko addr=0x419c0000 len=32 op=r; rmmod probeRW; /vendor/bin/busybox cat /data/local/tmp/probeRW.out' | tr -d '\r' | tail -3
      exit 0
    fi
  done
  echo "--- no reset with ch=$ch"
done
echo "=== neither channel reset the box"
