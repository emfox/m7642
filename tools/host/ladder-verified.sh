#!/bin/bash
# Stash-verified ladder: A -> B -> fixcacheK -> N1 -> Q2 -> U1 -> T1.
# A "reached" only counts when stash magic is M764 and x30 == base+off+4.
set -u
ADB=/home/emfox/Debian/tv/adb/platform-tools/adb
TV=192.168.10.60:5555
B=$HOME/Debian/m7642-build/out
root(){ $ADB -s $TV exec-out su -c "$1"; }
ready(){ $ADB connect $TV >/dev/null 2>&1; [ "$(root 'getprop sys.boot_completed' 2>/dev/null | tr -d '\r')" = 1 ]; }
run(){
  local tag=$1 img=$2 md5=$3 off=$4
  local want=$(printf '%08x' $(( (0x20280000 + off + 4) & 0xffffffff )))
  for w in $(seq 1 40); do ready && break; sleep 5; done
  ready || { echo "SKIP $tag: not ready"; return 9; }
  $ADB -s $TV push "$img" /data/local/tmp/c.img >/dev/null
  local o; o=$(root "dd if=/data/local/tmp/c.img of=/dev/block/by-name/recovery bs=4096 2>/dev/null; sync; md5sum /dev/block/by-name/recovery" | tr -d '\r' | cut -d' ' -f1)
  [ "$o" = "$md5" ] || { echo "SKIP $tag: slot mismatch ($o)"; return 9; }
  local t0=$(date +%s); echo "=== $tag ($off) $(date +%H:%M:%S)"
  $ADB -s $TV reboot recovery; sleep 14
  local ok=""
  for i in $(seq 1 60); do ready && { ok=1; break; }; sleep 5; done
  local d; d=$(root "/vendor/bin/busybox rmmod probeRW 2>/dev/null; /vendor/bin/busybox insmod /data/local/tmp/probeRW.ko addr=0x23080000 len=32 op=r; rmmod probeRW; /vendor/bin/busybox cat /data/local/tmp/probeRW.out" | tr -d '\r' | grep -E '^[0-9a-f]{16}:')
  local w0=$(echo "$d" | head -1 | sed 's/.*: //' | tr -d ' ')
  local magic=$(echo "$w0" | cut -c1-8)
  local xs=$(echo "$d" | sed -n '2p' | sed 's/.*: //' | tr -d ' ' | cut -c1-8)
  local x30="${xs:6:2}${xs:4:2}${xs:2:2}${xs:0:2}"   # little-endian -> value
  echo "  magic=$magic x30=$x30 want=$want  (android_up=${ok:-no})"
  if [ "$magic" = "4d373634" ] && [ "$x30" = "$want" ]; then
    echo "RESULT $tag: REACHED (verified, $(( $(date +%s) - t0 ))s)"; return 0
  fi
  echo "RESULT $tag: NOT REACHED / INCONCLUSIVE (stash magic=$magic)"; return 4
}
run A $B/m7642-rec-73-rungA.img 1cb41a671c70b1b83f9cc668fcbe8217 0x4 || exit $?
run B $B/m7642-rec-73-rungB.img 75efe3cf0669f6f0aad9ee8b24335e6b 0x455038 || exit $?
run K $B/m7642-rec-73-fixcacheK.img e3371ae4b626ffd11fcc3baac7818b5a 0x455048 || exit $?
run N1 $B/m7642-rec-73-fixN1.img 7bfd4780002454200596d9a87c5c8a81 0x465e4c || exit $?
run Q2 $B/m7642-rec-73-fixQ2.img 071cc4ecee70f409b602dc8febfef61c 0x465e78 || exit $?
run U1 $B/m7642-rec-73-fixU-0x465e80.img b3b797bd8c50abe03da836de782f7f4a 0x465e80 || exit $?
run T1 $B/m7642-rec-73-fixT1.img b05fcbc26e1aea2da1bfaacc2ed2227a 0x465cb8 || exit $?
echo "ALL REACHED (verified)"
