#!/bin/bash
# Same rungs, but with a 300 s window and the actual uptime logged, so a slow
# boot is not mistaken for "checkpoint not reached".
set -u
ADB=/home/emfox/Debian/tv/adb/platform-tools/adb
TV=192.168.10.60:5555
root(){ $ADB -s $TV exec-out su -c "$1"; }
ready(){ $ADB connect $TV >/dev/null 2>&1; [ "$(root 'getprop sys.boot_completed' 2>/dev/null | tr -d '\r')" = 1 ]; }
run(){
  local tag=$1 img=$2 md5=$3 off=$4
  ready || { echo "SKIP $tag: device not ready"; return 9; }
  $ADB -s $TV push "$img" /data/local/tmp/c.img >/dev/null
  local o; o=$(root "dd if=/data/local/tmp/c.img of=/dev/block/by-name/recovery bs=4096 2>/dev/null; sync; md5sum /dev/block/by-name/recovery" | tr -d '\r' | cut -d' ' -f1)
  [ "$o" = "$md5" ] || { echo "SKIP $tag: slot mismatch"; return 9; }
  local t0=$(date +%s)
  echo "=== $tag ($off) armed $(date +%H:%M:%S)"
  $ADB -s $TV reboot recovery; sleep 14
  for i in $(seq 1 60); do
    if ready; then
      echo "RESULT $tag: RETURNED after $(( $(date +%s) - t0 ))s (uptime $(root 'cut -d. -f1 /proc/uptime' | tr -d '\r')s)"
      return 0
    fi
    sleep 5
  done
  echo "RESULT $tag: NO RETURN after 300s"
  return 4
}
B=$HOME/kbuild/m7642-out
run U1 $B/m7642-rec-73-fixU-0x465e80.img b3b797bd8c50abe03da836de782f7f4a 0x465e80 || exit $?
run V1 $B/m7642-rec-73-fixV1.img cd8b47abb5a30ec66226161cdec07b62 0x465e94 || exit $?
echo "BOTH REACHED"
