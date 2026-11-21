#!/bin/bash
set -u
ADB=/home/emfox/Debian/tv/adb/platform-tools/adb
TV=192.168.10.60:5555
IMD5=a70ae4082ebe17bf363a362d5fd56af9
root(){ $ADB -s $TV exec-out su -c "$1"; }
$ADB connect $TV >/dev/null 2>&1
[ "$(root 'getprop sys.boot_completed' | tr -d '\r')" = 1 ] || { echo "not in Android"; exit 1; }
$ADB -s $TV push $HOME/kbuild/m7642-out/m7642-rec-419-abort.img /data/local/tmp/419abort.img >/dev/null
o=$(root "dd if=/data/local/tmp/419abort.img of=/dev/block/by-name/recovery bs=4096 2>/dev/null; sync; md5sum /dev/block/by-name/recovery" | tr -d '\r' | cut -d' ' -f1)
echo "-- slot $o"; [ "$o" = "$IMD5" ] || exit 1
echo "=== reboot recovery at $(date +%H:%M:%S)  (4.19 Image + abort stub at entry)"
$ADB -s $TV reboot recovery
sleep 14
for i in $(seq 1 18); do
  $ADB connect $TV >/dev/null 2>&1
  s=$(root 'getprop sys.boot_completed' 2>/dev/null | tr -d '\r')
  if [ "$s" = 1 ]; then echo "=== ANDROID UP at $(date +%H:%M:%S) uptime $(root 'cut -d. -f1 /proc/uptime' | tr -d '\r')s"; break; fi
  sleep 5
done
echo "--- stash: M764|STEP|rung|x0..x5"
root "/vendor/bin/busybox rmmod probeRW 2>/dev/null; /vendor/bin/busybox insmod /data/local/tmp/probeRW.ko addr=0x23080000 len=64 op=r; rmmod probeRW; /vendor/bin/busybox cat /data/local/tmp/probeRW.out" | tr -d '\r' | tail -4
