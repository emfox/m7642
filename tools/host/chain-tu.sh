#!/bin/bash
set -u
ADB=/home/emfox/Debian/tv/adb/platform-tools/adb
TV=192.168.10.60:5555
root(){ $ADB -s $TV exec-out su -c "$1"; }
waitup(){ for i in $(seq 1 24); do $ADB connect $TV >/dev/null 2>&1; [ "$(root 'getprop sys.boot_completed' 2>/dev/null | tr -d '\r')" = 1 ] && return 0; sleep 5; done; return 1; }
run(){
  local tag=$1 img=$2 md5=$3 off=$4
  waitup || { echo "SKIP $tag: not ready"; return 9; }
  $ADB -s $TV push "$img" /data/local/tmp/c.img >/dev/null
  local o; o=$(root "dd if=/data/local/tmp/c.img of=/dev/block/by-name/recovery bs=4096 2>/dev/null; sync; md5sum /dev/block/by-name/recovery" | tr -d '\r' | cut -d' ' -f1)
  [ "$o" = "$md5" ] || { echo "SKIP $tag: slot mismatch"; return 9; }
  echo "=== $tag (checkpoint $off) at $(date +%H:%M:%S)"
  $ADB -s $TV reboot recovery; sleep 14
  local ok=""
  for i in $(seq 1 20); do $ADB connect $TV >/dev/null 2>&1; [ "$(root 'getprop sys.boot_completed' 2>/dev/null | tr -d '\r')" = 1 ] && { ok=1; break; }; sleep 5; done
  [ -z "$ok" ] && { echo "RESULT $tag: NO RETURN"; return 4; }
  echo "RESULT $tag: RETURNED (reached $off)"; return 0
}
B=$HOME/Debian/m7642-build/out
run T1r $B/m7642-rec-73-fixT1.img b05fcbc26e1aea2da1bfaacc2ed2227a 0x465cb8 || exit $?
run U2  $B/m7642-rec-73-fixU-0x465ec8.img 830f37c49668d3a3541ac24d203913cd 0x465ec8 || exit $?
echo "BOTH REACHED"
