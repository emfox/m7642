#!/bin/bash
# Same abort1 image, staging read moved from 0x28000000 to 0x30000000.
set -u
ADB=/home/emfox/Debian/tv/adb/platform-tools/adb
TV=192.168.10.60:5555
T=/home/emfox/Debian/m7642/tools/host/envtool.py
IMG=/home/emfox/kbuild/m7642-out/m7642-rec-abort1.img
IMD5=7aaef778634ddd654da4e802071a6b70
RC='mmc erase.p misc; mmc read.p 0x23000000 dtb 0x00100000; mmc read.p 0x25000000 recovery 0x02000000; mmc read.p 0x30000000 boot 0x02000000; bootm 0x25000000'
root(){ $ADB -s $TV exec-out su -c "$1"; }
$ADB connect $TV >/dev/null 2>&1
[ "$(root 'getprop sys.boot_completed' | tr -d '\r')" = 1 ] || { echo "not in Android"; exit 1; }
root "dd if=/dev/block/mmcblk0 bs=4096 skip=2528 count=32 2>/dev/null" > /tmp/e.bin
python3 - /tmp/e.bin "$RC" "$T" <<'PY'
import subprocess, sys, hashlib
src, rc, tool = sys.argv[1:4]
d=open(src,'rb').read(); a,b=d[:65536],d[65536:]; assert a==b
parts=[]
for i,h in enumerate((a,b)):
    p='/tmp/s%d.bin'%i; open(p,'wb').write(h)
    subprocess.check_call(['python3',tool,'set',p,'recoverycmd='+rc])
    parts.append(open(p,'rb').read())
open('/tmp/env-s.bin','wb').write(parts[0]+parts[1]); print("env md5", hashlib.md5(parts[0]+parts[1]).hexdigest())
PY
for h in /tmp/s0.bin /tmp/s1.bin; do python3 "$T" verify "$h" >/dev/null || exit 1; done
$ADB -s $TV push /tmp/env-s.bin /data/local/tmp/env-s.bin >/dev/null
$ADB -s $TV push "$IMG" /data/local/tmp/abort1.img >/dev/null
o=$(root "dd if=/data/local/tmp/env-s.bin of=/dev/block/mmcblk0 bs=4096 seek=2528 count=32 2>/dev/null; sync; dd if=/dev/block/mmcblk0 bs=4096 skip=2528 count=32 2>/dev/null | md5sum" | tr -d '\r' | cut -d' ' -f1)
echo "-- env $o"; [ "$o" = "$(md5sum /tmp/env-s.bin | cut -d' ' -f1)" ] || exit 1
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
