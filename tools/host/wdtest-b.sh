#!/bin/bash
set -u
ADB=/home/emfox/Debian/tv/adb/platform-tools/adb
TV=192.168.10.60:5555
dev() { $ADB -s $TV shell "$@"; }
root() { $ADB -s $TV exec-out su -c "$1"; }
$ADB connect $TV >/dev/null 2>&1
echo "--- loaded modules matching wdtarm: $(dev '/vendor/bin/busybox lsmod | grep -c wdtarm' | tr -d '\r')"
echo "=== rmmod (toybox) at $(date +%H:%M:%S) -- module_exit arms the WDT"
root 'rmmod wdtarm; echo "rmmod rc=$?"' | tr -d '\r'
sleep 3
echo "--- dmesg wdtarm"
dev 'dmesg | grep -i wdtarm | tail -4' | tr -d '\r'
echo "--- uptime now: $(dev cut -d. -f1 /proc/uptime 2>/dev/null | tr -d '\r')"
echo "=== waiting for the reset + Android ($(date +%H:%M:%S))"
for i in $(seq 1 30); do
  sleep 5
  $ADB connect $TV >/dev/null 2>&1
  s=$(dev getprop sys.boot_completed 2>/dev/null | tr -d '\r')
  if [ "$s" = 1 ]; then
    u=$(dev cut -d. -f1 /proc/uptime | tr -d '\r')
    echo "=== Android at $(date +%H:%M:%S) uptime ${u}s"
    [ "${u:-999}" -lt 90 ] && break
  fi
done
echo "--- pstore"
root 'ls -l /sys/fs/pstore/' | tr -d '\r'
echo "--- pmsg file"
root 'od -A d -t c /sys/fs/pstore/pmsg-ramoops-0 2>&1 | head -4' | tr -d '\r'
echo "--- zone after"
root '/vendor/bin/busybox rmmod probeRW 2>/dev/null; /vendor/bin/busybox insmod /data/local/tmp/probeRW.ko addr=0x419c0000 len=32 op=r; rmmod probeRW; /vendor/bin/busybox cat /data/local/tmp/probeRW.out' | tr -d '\r' | tail -3
