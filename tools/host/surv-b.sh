#!/bin/bash
set -u
ADB=/home/emfox/Debian/tv/adb/platform-tools/adb
TV=192.168.10.60:5555
dev() { $ADB -s $TV shell "$@"; }
root() { $ADB -s $TV exec-out su -c "$1"; }
for i in $(seq 1 24); do
  sleep 5
  $ADB connect $TV >/dev/null 2>&1
  s=$(dev getprop sys.boot_completed 2>/dev/null | tr -d '\r')
  [ "$s" = 1 ] && { echo "=== Android at $(date +%H:%M:%S) uptime $(dev cut -d. -f1 /proc/uptime | tr -d '\r')s"; break; }
done
[ "${s:-}" = 1 ] || { echo "=== no adb"; exit 2; }
echo "--- pstore"
root 'ls -l /sys/fs/pstore/' | tr -d '\r'
echo "--- pmsg file content"
root 'od -A d -t c /sys/fs/pstore/pmsg-ramoops-0 2>&1 | head -4' | tr -d '\r'
echo "--- zone raw"
root '/vendor/bin/busybox rmmod probeRW 2>/dev/null; /vendor/bin/busybox insmod /data/local/tmp/probeRW.ko addr=0x419c0000 len=32 op=r; rmmod probeRW; cat /data/local/tmp/probeRW.out' | tr -d '\r' | tail -3
