#!/bin/bash
set -u
ADB=/home/emfox/Debian/tv/adb/platform-tools/adb
TV=192.168.10.60:5555
IMD5=830f37c49668d3a3541ac24d203913cd
root(){ $ADB -s $TV exec-out su -c "$1"; }
echo "waiting for device (up to 5 min)..."
for i in $(seq 1 50); do
  $ADB connect $TV >/dev/null 2>&1
  [ "$(root 'getprop sys.boot_completed' 2>/dev/null | tr -d '\r')" = 1 ] && { echo "ready $(date +%H:%M:%S)"; break; }
  sleep 6
done
[ "$(root 'getprop sys.boot_completed' 2>/dev/null | tr -d '\r')" = 1 ] || { echo "device never came up"; exit 9; }
$ADB -s $TV push $HOME/Debian/m7642-build/out/m7642-rec-73-fixU-0x465ec8.img /data/local/tmp/u2.img >/dev/null
o=$(root "dd if=/data/local/tmp/u2.img of=/dev/block/by-name/recovery bs=4096 2>/dev/null; sync; md5sum /dev/block/by-name/recovery" | tr -d '\r' | cut -d' ' -f1)
[ "$o" = "$IMD5" ] || { echo "slot mismatch $o"; exit 1; }
echo "=== U2 (checkpoint at the bl itself, 0x465ec8) at $(date +%H:%M:%S)"
$ADB -s $TV reboot recovery; sleep 14
ok=""
for i in $(seq 1 20); do
  $ADB connect $TV >/dev/null 2>&1
  [ "$(root 'getprop sys.boot_completed' 2>/dev/null | tr -d '\r')" = 1 ] && { ok=1; break; }
  sleep 5
done
[ -z "$ok" ] && { echo "RESULT U2: NO RETURN -> death between 0x465e80 and 0x465ec8 (the register math / str xzr,[sp])"; exit 4; }
echo "RESULT U2: RETURNED -> the bl is reached; its target 0x465cb8 must be the problem"
