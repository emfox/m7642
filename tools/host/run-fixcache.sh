#!/bin/bash
set -u
ADB=/home/emfox/Debian/tv/adb/platform-tools/adb
TV=192.168.10.60:5555
IMD5=e3371ae4b626ffd11fcc3baac7818b5a
root(){ $ADB -s $TV exec-out su -c "$1"; }
$ADB connect $TV >/dev/null 2>&1
[ "$(root 'getprop sys.boot_completed' | tr -d '\r')" = 1 ] || { echo "not in Android"; exit 1; }
$ADB -s $TV push $HOME/kbuild/m7642-out/m7642-rec-73-fixcacheK.img /data/local/tmp/fix.img >/dev/null
o=$(root "dd if=/data/local/tmp/fix.img of=/dev/block/by-name/recovery bs=4096 2>/dev/null; sync; md5sum /dev/block/by-name/recovery" | tr -d '\r' | cut -d' ' -f1)
[ "$o" = "$IMD5" ] || { echo "slot mismatch $o"; exit 1; }
echo "=== armed (nop @0x46803c + checkpoint @0x455048) at $(date +%H:%M:%S)"
$ADB -s $TV reboot recovery
sleep 14
ok=""
for i in $(seq 1 20); do
  $ADB connect $TV >/dev/null 2>&1
  s=$(root 'getprop sys.boot_completed' 2>/dev/null | tr -d '\r')
  [ "$s" = 1 ] && { ok=1; echo "=== Android back at $(date +%H:%M:%S)"; break; }
  sleep 5
done
[ -z "$ok" ] && { echo "RESULT: NO RETURN (still dying before 0x455048)"; exit 4; }
root "/vendor/bin/busybox rmmod probeRW 2>/dev/null; /vendor/bin/busybox insmod /data/local/tmp/probeRW.ko addr=0x23080000 len=72 op=r; rmmod probeRW; /vendor/bin/busybox cat /data/local/tmp/probeRW.out" | tr -d '\r' | grep -E '^[0-9a-f]{16}:' | sed 's/^/  /'
echo "RESULT: RETURNED -> cache-op fix worked; x30 should be $(printf '0x%x' $((0x20280000+0x455048+4)))"
