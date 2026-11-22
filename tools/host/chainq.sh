#!/bin/bash
set -u
ADB=/home/emfox/Debian/tv/adb/platform-tools/adb
TV=192.168.10.60:5555
root(){ $ADB -s $TV exec-out su -c "$1"; }
waitup(){
  for i in $(seq 1 24); do
    $ADB connect $TV >/dev/null 2>&1
    [ "$(root 'getprop sys.boot_completed' 2>/dev/null | tr -d '\r')" = 1 ] && return 0
    sleep 5
  done
  return 1
}
run(){
  local tag=$1 img=$2 md5=$3 off=$4
  waitup || { echo "SKIP $tag: device not ready"; return 9; }
  $ADB -s $TV push "$img" /data/local/tmp/c.img >/dev/null
  local o; o=$(root "dd if=/data/local/tmp/c.img of=/dev/block/by-name/recovery bs=4096 2>/dev/null; sync; md5sum /dev/block/by-name/recovery" | tr -d '\r' | cut -d' ' -f1)
  [ "$o" = "$md5" ] || { echo "SKIP $tag: slot mismatch"; return 9; }
  echo "=== $tag armed (checkpoint $off) at $(date +%H:%M:%S)"
  $ADB -s $TV reboot recovery
  sleep 14
  local ok=""
  for i in $(seq 1 20); do
    $ADB connect $TV >/dev/null 2>&1
    [ "$(root 'getprop sys.boot_completed' 2>/dev/null | tr -d '\r')" = 1 ] && { ok=1; break; }
    sleep 5
  done
  if [ -z "$ok" ]; then echo "RESULT $tag: NO RETURN  <-- died at or before $off"; return 4; fi
  echo "RESULT $tag: RETURNED (reached $off)"
  return 0
}
run Q1 "$HOME/Debian/m7642-build/out/m7642-rec-73-fixQ1.img" f9f7d794752a702f7085c175dc505533 0x465e50 || exit $?
run Q2 "$HOME/Debian/m7642-build/out/m7642-rec-73-fixQ2.img" 071cc4ecee70f409b602dc8febfef61c 0x465e78 || exit $?
run Q3 "$HOME/Debian/m7642-build/out/m7642-rec-73-fixQ3.img" 92607ce2fb8b95fa9e61ebd7ae53a5aa 0x465ecc || exit $?
echo "ALL Q REACHED (map_range returned)"
