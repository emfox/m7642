#!/bin/bash
# Isolate: staging read present in recoverycmd, stub = plain abort1 (no reads).
set -u
ADB=/home/emfox/Debian/tv/adb/platform-tools/adb
TV=192.168.10.60:5555
IMG=/home/emfox/kbuild/m7642-out/m7642-rec-abort1.img
IMD5=7aaef778634ddd654da4e802071a6b70
root(){ $ADB -s $TV exec-out su -c "$1"; }
$ADB connect $TV >/dev/null 2>&1
[ "$(root 'getprop sys.boot_completed' | tr -d '\r')" = 1 ] || { echo "not in Android"; exit 1; }
echo "-- env on device has staging read: (checking via envtool)"
root "dd if=/dev/block/mmcblk0 bs=4096 skip=2528 count=32 2>/dev/null" > /tmp/e.bin
python3 - <<'PY'
import subprocess
d=open('/tmp/e.bin','rb').read(); open('/tmp/e0.bin','wb').write(d[:65536])
print("recoverycmd:", subprocess.check_output(['python3','/home/emfox/Debian/m7642/tools/host/envtool.py','get','/tmp/e0.bin','recoverycmd']).decode().strip())
PY
$ADB -s $TV push "$IMG" /data/local/tmp/abort1.img >/dev/null
o=$(root "dd if=/data/local/tmp/abort1.img of=/dev/block/by-name/recovery bs=4096 2>/dev/null; sync; md5sum /dev/block/by-name/recovery" | tr -d '\r' | cut -d' ' -f1)
echo "-- slot $o"; [ "$o" = "$IMD5" ] || exit 1
echo "=== reboot recovery at $(date +%H:%M:%S)"
$ADB -s $TV reboot recovery
sleep 14
for i in $(seq 1 18); do
  $ADB connect $TV >/dev/null 2>&1
  s=$(root 'getprop sys.boot_completed' 2>/dev/null | tr -d '\r')
  if [ "$s" = 1 ]; then echo "=== ANDROID UP at $(date +%H:%M:%S) uptime $(root 'cut -d. -f1 /proc/uptime' | tr -d '\r')s"; break; fi
  sleep 5
done
root "/vendor/bin/busybox rmmod probeRW 2>/dev/null; /vendor/bin/busybox insmod /data/local/tmp/probeRW.ko addr=0x23080000 len=16 op=r; rmmod probeRW; /vendor/bin/busybox cat /data/local/tmp/probeRW.out" | tr -d '\r' | tail -2
