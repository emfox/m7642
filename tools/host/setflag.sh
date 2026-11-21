#!/bin/bash
set -u
ADB=/home/emfox/Debian/tv/adb/platform-tools/adb
TV=192.168.10.60:5555
T=/home/emfox/Debian/m7642/tools/host/envtool.py
dev() { $ADB -s $TV shell "$@"; }
root() { $ADB -s $TV exec-out su -c "$1"; }
$ADB connect $TV >/dev/null 2>&1
root "dd if=/dev/block/mmcblk0 bs=4096 skip=2528 count=32 2>/dev/null" > /tmp/e.bin
python3 - /tmp/e.bin "$T" <<'PY'
import subprocess, sys, hashlib
src, tool = sys.argv[1:3]
d = open(src,'rb').read(); a,b = d[:65536], d[65536:]
parts=[]
for i,h in enumerate((a,b)):
    p='/tmp/s%d.bin'%i; open(p,'wb').write(h)
    subprocess.check_call(['python3',tool,'set',p,'MstarUpgrade_complete=1'])
    parts.append(open(p,'rb').read())
open('/tmp/envsafe.bin','wb').write(parts[0]+parts[1])
print("new md5", hashlib.md5(parts[0]+parts[1]).hexdigest())
for k in ("WDT_ENABLE","MstarUpgrade_complete"):
    print(k, "=", subprocess.check_output(['python3',tool,'get','/tmp/s0.bin',k]).decode().strip())
PY
for h in /tmp/s0.bin /tmp/s1.bin; do python3 "$T" verify "$h" >/dev/null || { echo "CRC bad"; exit 1; }; done
$ADB -s $TV push /tmp/envsafe.bin /data/local/tmp/envsafe.bin >/dev/null
o=$(root "dd if=/data/local/tmp/envsafe.bin of=/dev/block/mmcblk0 bs=4096 seek=2528 count=32 2>/dev/null; sync; dd if=/dev/block/mmcblk0 bs=4096 skip=2528 count=32 2>/dev/null | md5sum" | tr -d '\r' | cut -d' ' -f1)
echo "env readback $o  (local $(md5sum /tmp/envsafe.bin | cut -d' ' -f1))"
