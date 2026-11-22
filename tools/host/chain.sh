#!/bin/bash
# Run fix+checkpoint images in order; stop at the first one that does not return.
set -u
ADB=/home/emfox/Debian/tv/adb/platform-tools/adb
TV=192.168.10.60:5555
root(){ $ADB -s $TV exec-out su -c "$1"; }
run(){
  local tag=$1 img=$2 md5=$3 off=$4
  $ADB connect $TV >/dev/null 2>&1
  [ "$(root 'getprop sys.boot_completed' | tr -d '\r')" = 1 ] || { echo "SKIP $tag: device not in Android"; return 9; }
  $ADB -s $TV push "$img" /data/local/tmp/c.img >/dev/null
  local o; o=$(root "dd if=/data/local/tmp/c.img of=/dev/block/by-name/recovery bs=4096 2>/dev/null; sync; md5sum /dev/block/by-name/recovery" | tr -d '\r' | cut -d' ' -f1)
  [ "$o" = "$md5" ] || { echo "SKIP $tag: slot mismatch"; return 9; }
  echo "=== $tag armed (checkpoint $off) at $(date +%H:%M:%S)"
  $ADB -s $TV reboot recovery
  sleep 14
  for i in $(seq 1 20); do
    $ADB connect $TV >/dev/null 2>&1
    [ "$(root 'getprop sys.boot_completed' 2>/dev/null | tr -d '\r')" = 1 ] && break
    sleep 5
  done
  $ADB connect $TV >/dev/null 2>&1
  if [ "$(root 'getprop sys.boot_completed' 2>/dev/null | tr -d '\r')" != 1 ]; then
    echo "RESULT $tag: NO RETURN  <-- death between previous checkpoint and $off"
    return 4
  fi
  local x30; x30=$(root "/vendor/bin/busybox rmmod probeRW 2>/dev/null; /vendor/bin/busybox insmod /data/local/tmp/probeRW.ko addr=0x23080000 len=72 op=r; rmmod probeRW; /vendor/bin/busybox cat /data/local/tmp/probeRW.out" | tr -d '\r' | grep -E '^2308' | head -1 | sed 's/.*: //' | cut -d' ' -f5-8 | tr -d ' ')
  echo "RESULT $tag: RETURNED  x30=$x30 (want $(printf '%08x' $((0x20280000+off+4))))"
  return 0
}
run N1 "$HOME/Debian/m7642-build/out/m7642-rec-73-fixN1.img" 7bfd4780002454200596d9a87c5c8a81 0x465e4c || exit $?
run N2 "$HOME/Debian/m7642-build/out/m7642-rec-73-fixN2.img" 55604f65a31507ca9b81d4cf56c45303 0x4550a4 || exit $?
run N3 "$HOME/Debian/m7642-build/out/m7642-rec-73-fixN3.img" 2355a659f086e34e2e115efeba68def0 0x45580c || exit $?
run N4 "$HOME/Debian/m7642-build/out/m7642-rec-73-fixN4.img" 27339fc9358be52066738cc0dcfee6c0 0x455580 || exit $?
echo "ALL REACHED up to __primary_switch"
