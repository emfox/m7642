#!/bin/bash
# Repeatability control: run each image N times, stop when the device needs a
# physical power cycle, and print the tally.
set -u
ADB=/home/emfox/Debian/tv/adb/platform-tools/adb
TV=192.168.10.60:5555
root(){ $ADB -s $TV exec-out su -c "$1"; }
ready(){ $ADB connect $TV >/dev/null 2>&1; [ "$(root 'getprop sys.boot_completed' 2>/dev/null | tr -d '\r')" = 1 ]; }
runonce(){
  local tag=$1 img=$2 md5=$3
  ready || return 9
  $ADB -s $TV push "$img" /data/local/tmp/c.img >/dev/null
  local o; o=$(root "dd if=/data/local/tmp/c.img of=/dev/block/by-name/recovery bs=4096 2>/dev/null; sync; md5sum /dev/block/by-name/recovery" | tr -d '\r' | cut -d' ' -f1)
  [ "$o" = "$md5" ] || { echo "  slot mismatch"; return 9; }
  $ADB -s $TV reboot recovery; sleep 14
  for i in $(seq 1 24); do
    $ADB connect $TV >/dev/null 2>&1
    [ "$(root 'getprop sys.boot_completed' 2>/dev/null | tr -d '\r')" = 1 ] && return 0
    sleep 5
  done
  return 4
}
B=$HOME/Debian/m7642-build/out
for spec in "U1:0x465e80:b3b797bd8c50abe03da836de782f7f4a" "V1:0x465e94:cd8b47abb5a30ec66226161cdec07b62"; do
  tag=${spec%%:*}; rest=${spec#*:}; off=${rest%%:*}; md5=${rest##*:}
  if [ "$tag" = U1 ]; then img=$B/m7642-rec-73-fixU-0x465e80.img; else img=$B/m7642-rec-73-fix${tag}.img; fi
  ok=0; fail=0
  for n in 1 2 3; do
    if runonce "$tag" "$img" "$md5"; then ok=$((ok+1)); echo "  $tag run$n: RETURNED"; else
      rc=$?; if [ $rc = 9 ]; then echo "  $tag run$n: device not ready, stopping"; echo "TALLY $tag: ok=$ok fail=$fail"; exit 0; fi
      fail=$((fail+1)); echo "  $tag run$n: NO RETURN"
    fi
  done
  echo "TALLY $tag: ok=$ok fail=$fail"
done
