#!/bin/bash
# Decisive test: ldrb at 0x465e7c replaced by `mov w2, wzr`; checkpoint 0x465e80.
set -u
ADB=/home/emfox/Debian/tv/adb/platform-tools/adb
TV=192.168.10.60:5555
IMD5=0b20c03f1f23b5cb5e946597c8d303cc
WANT=206e5e84
root(){ $ADB -s $TV exec-out su -c "$1"; }
ready(){ $ADB connect $TV >/dev/null 2>&1; [ "$(root 'getprop sys.boot_completed' 2>/dev/null | tr -d '\r')" = 1 ]; }
for n in 1 2; do
  for w in $(seq 1 40); do ready && break; sleep 5; done
  ready || { echo "run$n: not ready"; exit 9; }
  $ADB -s $TV push $HOME/Debian/m7642-build/out/m7642-rec-73-ldrbfix.img /data/local/tmp/lf.img >/dev/null
  o=$(root "dd if=/data/local/tmp/lf.img of=/dev/block/by-name/recovery bs=4096 2>/dev/null; sync; md5sum /dev/block/by-name/recovery" | tr -d '\r' | cut -d' ' -f1)
  [ "$o" = "$IMD5" ] || { echo "run$n: slot mismatch ($o)"; exit 1; }
  t0=$(date +%s); echo "=== run$n $(date +%H:%M:%S)"
  $ADB -s $TV reboot recovery; sleep 14
  ok=""
  for i in $(seq 1 60); do ready && { ok=1; break; }; sleep 5; done
  d=$(root "/vendor/bin/busybox rmmod probeRW 2>/dev/null; /vendor/bin/busybox insmod /data/local/tmp/probeRW.ko addr=0x23080000 len=32 op=r; rmmod probeRW; /vendor/bin/busybox cat /data/local/tmp/probeRW.out" | tr -d '\r' | grep -E '^[0-9a-f]{16}:')
  w0=$(echo "$d" | head -1 | sed 's/.*: //' | tr -d ' ')
  xs=$(echo "$d" | sed -n '2p' | sed 's/.*: //' | tr -d ' ' | cut -c1-8)
  x30="${xs:6:2}${xs:4:2}${xs:2:2}${xs:0:2}"
  echo "  magic=$(echo "$w0" | cut -c1-8) x30=$x30 want=$WANT android_up=${ok:-no}"
  if [ "$(echo "$w0" | cut -c1-8)" = "4d373634" ] && [ "$x30" = "$WANT" ]; then
    echo "RESULT run$n: REACHED (verified) -> the ldrb was the killer"; exit 0
  fi
  echo "RESULT run$n: NOT REACHED / INCONCLUSIVE"
  [ $n = 1 ] && { echo "(stopping: needs a power cycle before a second run)"; exit 4; }
done
