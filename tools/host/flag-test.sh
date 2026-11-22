#!/bin/bash
# Same image, same wdt_enable 10 -- only MstarUpgrade_complete differs (0 -> 1).
# If the self-return comes back, that flag is the state variable, not chance.
set -u
ADB=/home/emfox/Debian/tv/adb/platform-tools/adb
TV=192.168.10.60:5555
T=/home/emfox/Debian/m7642/tools/host/envtool.py
IMG=/home/emfox/Debian/m7642-build/out/m7642-rec-handoff1-hang.img
IMD5=4cdbc794195c44bf964639d0eaf0c9fd
RC='mmc erase.p misc; mmc read.p 0x23000000 dtb 0x00100000; mmc read.p 0x25000000 recovery 0x02000000; wdt_enable 10; bootm 0x25000000'
dev() { $ADB -s $TV shell "$@"; }
root() { $ADB -s $TV exec-out su -c "$1"; }
$ADB connect $TV >/dev/null 2>&1
[ "$(dev getprop sys.boot_completed 2>/dev/null | tr -d '\r')" = 1 ] || { echo "not in Android"; exit 1; }
root "dd if=/dev/block/mmcblk0 bs=4096 skip=2528 count=32 2>/dev/null" > /tmp/e.bin
python3 - /tmp/e.bin "$RC" "$T" <<'PY'
import subprocess, sys, hashlib
src, rc, tool = sys.argv[1:4]
d = open(src,'rb').read(); a,b = d[:65536], d[65536:]
assert a == b
parts=[]
for i,h in enumerate((a,b)):
    p='/tmp/f%d.bin'%i; open(p,'wb').write(h)
    subprocess.check_call(['python3',tool,'set',p,'recoverycmd='+rc,'MstarUpgrade_complete=1'])
    parts.append(open(p,'rb').read())
open('/tmp/envflag.bin','wb').write(parts[0]+parts[1])
print("md5", hashlib.md5(parts[0]+parts[1]).hexdigest())
for k in ("recoverycmd","MstarUpgrade_complete","WDT_ENABLE"):
    print(k, "=", subprocess.check_output(['python3',tool,'get','/tmp/f0.bin',k]).decode().strip())
PY
for h in /tmp/f0.bin /tmp/f1.bin; do python3 "$T" verify "$h" >/dev/null || { echo "CRC bad"; exit 1; }; done
$ADB -s $TV push /tmp/envflag.bin /data/local/tmp/envflag.bin >/dev/null
$ADB -s $TV push "$IMG" /data/local/tmp/hang1.img >/dev/null
o=$(root "dd if=/data/local/tmp/envflag.bin of=/dev/block/mmcblk0 bs=4096 seek=2528 count=32 2>/dev/null; sync; dd if=/dev/block/mmcblk0 bs=4096 skip=2528 count=32 2>/dev/null | md5sum" | tr -d '\r' | cut -d' ' -f1)
echo "env readback $o"
[ "$o" = "$(md5sum /tmp/envflag.bin | cut -d' ' -f1)" ] || { echo "env readback mismatch"; exit 1; }
o=$(root "dd if=/data/local/tmp/hang1.img of=/dev/block/by-name/recovery bs=4096 2>/dev/null; sync; md5sum /dev/block/by-name/recovery" | tr -d '\r' | cut -d' ' -f1)
echo "slot $o"
[ "$o" = "$IMD5" ] || { echo "slot mismatch"; exit 1; }
echo "=== reboot recovery at $(date +%H:%M:%S)  (flag=1, wdt 10, same hang image)"
$ADB -s $TV reboot recovery
sleep 6
for i in $(seq 1 24); do
  sleep 5
  $ADB connect $TV >/dev/null 2>&1
  s=$(dev getprop sys.boot_completed 2>/dev/null | tr -d '\r')
  if [ "$s" = 1 ]; then
    u=$(dev cut -d. -f1 /proc/uptime | tr -d '\r')
    if [ "${u:-0}" -lt 120 ]; then echo "=== SELF-RETURN at $(date +%H:%M:%S) uptime ${u}s"; exit 0; fi
  fi
done
echo "=== NO self-return within ~130 s"
