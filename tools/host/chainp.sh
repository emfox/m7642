#!/bin/bash
set -u
ADB=/home/emfox/Debian/tv/adb/platform-tools/adb
TV=192.168.10.60:5555
root(){ $ADB -s $TV exec-out su -c "$1"; }
run(){
  local tag=$1 img=$2 md5=$3 off=$4
  $ADB connect $TV >/dev/null 2>&1
  [ "$(root 'getprop sys.boot_completed' | tr -d '\r')" = 1 ] || { echo "SKIP $tag: not in Android"; return 9; }
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
    echo "RESULT $tag: NO RETURN  <-- died between previous checkpoint and $off"
    return 4
  fi
  echo "RESULT $tag: RETURNED (reached $off)"
  return 0
}
run P2 "$HOME/kbuild/m7642-out/m7642-rec-73-fixP2.img" ba363859109f76e55bf417a3c9aef61b 0x455058 || exit $?
run P3 "$HOME/kbuild/m7642-out/m7642-rec-73-fixP3.img" d61966294659e462034688b8ce09d538 0x455074 || exit $?
run P4 "$HOME/kbuild/m7642-out/m7642-rec-73-fixP4.img" 064a10ad4bec0749c239f3bbfd32f5bd 0x455090 || exit $?
echo "ALL P REACHED"
