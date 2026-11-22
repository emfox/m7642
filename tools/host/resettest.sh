#!/bin/bash
set -u
ADB=/home/emfox/Debian/tv/adb/platform-tools/adb
TV=192.168.10.60:5555
dev() { $ADB -s $TV shell "$@"; }
root() { $ADB -s $TV exec-out su -c "$1"; }
$ADB connect $TV >/dev/null 2>&1
[ "$(dev getprop sys.boot_completed 2>/dev/null | tr -d '\r')" = 1 ] || { echo "not in Android"; exit 1; }
u0=$(dev cut -d. -f1 /proc/uptime | tr -d '\r'); echo "uptime before $u0 s"
root 'echo M7642RST1 > /dev/pmsg0' >/dev/null
echo "--- zone before"
root '/vendor/bin/busybox rmmod probeRW 2>/dev/null; /vendor/bin/busybox insmod /data/local/tmp/probeRW.ko addr=0x419c0000 len=16 op=r; rmmod probeRW; /vendor/bin/busybox cat /data/local/tmp/probeRW.out' | tr -d '\r' | tail -2
echo "=== write 1 to 0x1f201fcc at $(date +%H:%M:%S)"
root '/vendor/bin/busybox rmmod probeRW 2>/dev/null; /vendor/bin/busybox insmod /data/local/tmp/probeRW.ko addr=0x1f201fcc len=4 op=w val=1; rmmod probeRW; /vendor/bin/busybox cat /data/local/tmp/probeRW.out' | tr -d '\r' | tail -2
for i in $(seq 1 20); do
  sleep 5
  $ADB connect $TV >/dev/null 2>&1
  u=$(dev cut -d. -f1 /proc/uptime 2>/dev/null | tr -d '\r')
  if [ -n "${u:-}" ] && [ "${u:-9999}" -lt "${u0:-0}" ]; then echo "=== RESET at $(date +%H:%M:%S) (uptime ${u}s)"; break; fi
  echo "t+$((i*5))s uptime=${u:-DEAD}"
done
for j in $(seq 1 12); do
  sleep 5; $ADB connect $TV >/dev/null 2>&1
  s=$(dev getprop sys.boot_completed 2>/dev/null | tr -d '\r')
  [ "$s" = 1 ] && { echo "=== Android at $(date +%H:%M:%S) uptime $(dev cut -d. -f1 /proc/uptime | tr -d '\r')s"; break; }
done
echo "--- pstore"
root 'ls -l /sys/fs/pstore/' | tr -d '\r'
root 'od -A d -t c /sys/fs/pstore/pmsg-ramoops-0 2>&1 | head -3' | tr -d '\r'
