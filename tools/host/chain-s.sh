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
  [ "$o" = "$md5" ] || { echo "SKIP $tag: slot mismatch ($o)"; return 9; }
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
B=$HOME/kbuild/m7642-out
run S1 $B/m7642-rec-73-fixS1.img 1f0e271f0e4102a4ca6d38c94a176020 0x465cbc || exit $?
run S2 $B/m7642-rec-73-fixS2.img e997e52e33c1de7caf2c2ebaab2ffbca 0x465d7c || exit $?
run S3 $B/m7642-rec-73-fixS3.img 0a44d8d9d42bc466484f328c4e761aad 0x465d94 || exit $?
run S4 $B/m7642-rec-73-fixS4.img 06b80a198363ca02e125ab16c309572a 0x465dd8 || exit $?
echo "ALL S REACHED (recursion entered)"
