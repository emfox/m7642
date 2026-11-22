#!/bin/bash
set -u
ADB=/home/emfox/Debian/tv/adb/platform-tools/adb
TV=192.168.10.60:5555
IMD5=b3b797bd8c50abe03da836de782f7f4a
root(){ $ADB -s $TV exec-out su -c "$1"; }
echo "waiting for device (up to 5 min)..."
ready=""
for i in $(seq 1 50); do
  $ADB connect $TV >/dev/null 2>&1
  if [ "$(root 'getprop sys.boot_completed' 2>/dev/null | tr -d '\r')" = 1 ]; then ready=1; echo "device ready at $(date +%H:%M:%S)"; break; fi
  sleep 6
done
[ -z "$ready" ] && { echo "device never came up"; exit 9; }
$ADB -s $TV push $HOME/Debian/m7642-build/out/m7642-rec-73-fixU-0x465e80.img /data/local/tmp/u1.img >/dev/null
o=$(root "dd if=/data/local/tmp/u1.img of=/dev/block/by-name/recovery bs=4096 2>/dev/null; sync; md5sum /dev/block/by-name/recovery" | tr -d '\r' | cut -d' ' -f1)
[ "$o" = "$IMD5" ] || { echo "slot mismatch $o"; exit 1; }
echo "=== U1 armed (checkpoint right after the ldrb, 0x465e80) at $(date +%H:%M:%S)"
$ADB -s $TV reboot recovery
sleep 14
ok=""
for i in $(seq 1 20); do
  $ADB connect $TV >/dev/null 2>&1
  [ "$(root 'getprop sys.boot_completed' 2>/dev/null | tr -d '\r')" = 1 ] && { ok=1; break; }
  sleep 5
done
[ -z "$ok" ] && { echo "RESULT U1: NO RETURN -> the ldrb at 0x465e7c is the killer"; exit 4; }
echo "RESULT U1: RETURNED -> ldrb fine; the bl map_range at 0x465ec8 is the killer"
