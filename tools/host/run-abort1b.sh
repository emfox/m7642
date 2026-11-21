#!/bin/bash
set -u
ADB=/home/emfox/Debian/tv/adb/platform-tools/adb
TV=192.168.10.60:5555
IMG=/home/emfox/kbuild/m7642-out/m7642-rec-abort1b.img
IMD5=d6012ab138fb4a33a3015ac103f4d478
root(){ $ADB -s $TV exec-out su -c "$1"; }
$ADB connect $TV >/dev/null 2>&1
[ "$(root 'getprop sys.boot_completed' | tr -d '\r')" = 1 ] || { echo "not in Android"; exit 1; }
echo "-- recoverycmd now: $(root '/vendor/bin/busybox cat /dev/null'; true)"
$ADB -s $TV push "$IMG" /data/local/tmp/abort1b.img >/dev/null
o=$(root "dd if=/data/local/tmp/abort1b.img of=/dev/block/by-name/recovery bs=4096 2>/dev/null; sync; md5sum /dev/block/by-name/recovery" | tr -d '\r' | cut -d' ' -f1)
echo "-- slot $o"; [ "$o" = "$IMD5" ] || exit 1
echo "=== reboot recovery at $(date +%H:%M:%S)"
$ADB -s $TV reboot recovery
sleep 12
for i in $(seq 1 18); do
  $ADB connect $TV >/dev/null 2>&1
  s=$(root 'getprop sys.boot_completed' 2>/dev/null | tr -d '\r')
  if [ "$s" = 1 ]; then echo "=== ANDROID UP at $(date +%H:%M:%S) uptime $(root 'cut -d. -f1 /proc/uptime' | tr -d '\r')s"; break; fi
  sleep 5
done
echo "--- stash page0 (M764|STEP|4|stage_hdr|stage_ksize|stage_code0|stage_code1):"
root "/vendor/bin/busybox rmmod probeRW 2>/dev/null; /vendor/bin/busybox insmod /data/local/tmp/probeRW.ko addr=0x23080000 len=32 op=r; rmmod probeRW; /vendor/bin/busybox cat /data/local/tmp/probeRW.out" | tr -d '\r' | tail -3
