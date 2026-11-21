#!/bin/bash
set -u
ADB=/home/emfox/Debian/tv/adb/platform-tools/adb
TV=192.168.10.60:5555
root(){ $ADB -s $TV exec-out su -c "$1"; }
for i in $(seq 1 24); do
  $ADB connect $TV >/dev/null 2>&1
  [ "$(root 'getprop sys.boot_completed' 2>/dev/null | tr -d '\r')" = 1 ] && break
  sleep 5
done
[ "$(root 'getprop sys.boot_completed' 2>/dev/null | tr -d '\r')" = 1 ] || { echo "device not ready"; exit 9; }
IMD5=b05fcbc26e1aea2da1bfaacc2ed2227a
$ADB -s $TV push $HOME/kbuild/m7642-out/m7642-rec-73-fixT1.img /data/local/tmp/t1.img >/dev/null
o=$(root "dd if=/data/local/tmp/t1.img of=/dev/block/by-name/recovery bs=4096 2>/dev/null; sync; md5sum /dev/block/by-name/recovery" | tr -d '\r' | cut -d' ' -f1)
[ "$o" = "$IMD5" ] || { echo "slot mismatch $o"; exit 1; }
echo "=== T1 armed (map_range entry 0x465cb8) at $(date +%H:%M:%S)"
$ADB -s $TV reboot recovery
sleep 14
ok=""
for i in $(seq 1 20); do
  $ADB connect $TV >/dev/null 2>&1
  [ "$(root 'getprop sys.boot_completed' 2>/dev/null | tr -d '\r')" = 1 ] && { ok=1; break; }
  sleep 5
done
[ -z "$ok" ] && { echo "RESULT T1: NO RETURN -> never entered map_range"; exit 4; }
echo "RESULT T1: RETURNED -> map_range entry reached; death is right after it"
