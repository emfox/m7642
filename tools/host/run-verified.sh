#!/bin/bash
# Verified rung runner: a "RETURNED" verdict only counts when the stash proves
# the stub actually ran (magic M764 + STEP + x30 == base+off+4).
set -u
ADB=/home/emfox/Debian/tv/adb/platform-tools/adb
TV=192.168.10.60:5555
root(){ $ADB -s $TV exec-out su -c "$1"; }
ready(){ $ADB connect $TV >/dev/null 2>&1; [ "$(root 'getprop sys.boot_completed' 2>/dev/null | tr -d '\r')" = 1 ]; }
run(){
  local tag=$1 img=$2 md5=$3 off=$4
  for w in $(seq 1 40); do ready && break; sleep 5; done
  ready || { echo "SKIP $tag: not ready"; return 9; }
  $ADB -s $TV push "$img" /data/local/tmp/c.img >/dev/null
  local o; o=$(root "dd if=/data/local/tmp/c.img of=/dev/block/by-name/recovery bs=4096 2>/dev/null; sync; md5sum /dev/block/by-name/recovery" | tr -d '\r' | cut -d' ' -f1)
  [ "$o" = "$md5" ] || { echo "SKIP $tag: slot mismatch"; return 9; }
  local t0=$(date +%s); echo "=== $tag ($off) $(date +%H:%M:%S)"
  $ADB -s $TV reboot recovery; sleep 14
  for i in $(seq 1 60); do ready && break; sleep 5; done
  local d; d=$(root "/vendor/bin/busybox rmmod probeRW 2>/dev/null; /vendor/bin/busybox insmod /data/local/tmp/probeRW.ko addr=0x23080000 len=32 op=r; rmmod probeRW; /vendor/bin/busybox cat /data/local/tmp/probeRW.out" | tr -d '\r' | grep -E '^[0-9a-f]{16}:')
  local magic=$(echo "$d" | head -1 | sed 's/.*: //' | cut -c1-8)
  local step=$(echo "$d" | head -1 | sed 's/.*: //' | cut -c19-26)
  local x30=$(echo "$d" | sed -n '2p' | sed 's/.*: //' | cut -c1-8)
  echo "  stash magic=$magic step=$step x30=$x30 (want x30=$(printf '%08x' $(( (0x20280000+off+4) & 0xffffffff ))))"
  if [ "$magic" = "4d373634" ] && [ "$x30" = "$(printf '%08x' $(( (0x20280000+off+4) & 0xffffffff )))" ]; then
    echo "RESULT $tag: REACHED (verified, $(( $(date +%s) - t0 ))s)"; return 0
  fi
  if [ "$magic" = "4d373634" ]; then
    echo "RESULT $tag: stub ran but x30 mismatch -> different rung"; return 5
  fi
  echo "RESULT $tag: INCONCLUSIVE/NO RETURN (stash empty -> checkpoint never ran)"; return 4
}
B=$HOME/Debian/m7642-build/out
run U1 $B/m7642-rec-73-fixU-0x465e80.img b3b797bd8c50abe03da836de782f7f4a 0x465e80 || exit $?
run Q2 $B/m7642-rec-73-fixQ2.img 071cc4ecee70f409b602dc8febfef61c 0x465e78 || exit $?
