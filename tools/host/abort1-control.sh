#!/bin/bash
# Control: the handover device alone (abort1), 3 runs, 300 s window.
set -u
ADB=/home/emfox/Debian/tv/adb/platform-tools/adb
TV=192.168.10.60:5555
IMD5=7aaef778634ddd654da4e802071a6b70
root(){ $ADB -s $TV exec-out su -c "$1"; }
ready(){ $ADB connect $TV >/dev/null 2>&1; [ "$(root 'getprop sys.boot_completed' 2>/dev/null | tr -d '\r')" = 1 ]; }
for n in 1 2 3; do
  ready || { echo "run$n: device not ready, stopping"; exit 9; }
  $ADB -s $TV push $HOME/Debian/m7642-build/out/m7642-rec-abort1.img /data/local/tmp/a1.img >/dev/null
  o=$(root "dd if=/data/local/tmp/a1.img of=/dev/block/by-name/recovery bs=4096 2>/dev/null; sync; md5sum /dev/block/by-name/recovery" | tr -d '\r' | cut -d' ' -f1)
  [ "$o" = "$IMD5" ] || { echo "run$n: slot mismatch ($o)"; exit 1; }
  t0=$(date +%s); echo "=== run$n $(date +%H:%M:%S)"
  $ADB -s $TV reboot recovery; sleep 14
  ok=""
  for i in $(seq 1 60); do ready && { ok=1; break; }; sleep 5; done
  if [ -n "$ok" ]; then
    echo "run$n: RETURNED after $(( $(date +%s) - t0 ))s"
    root "/vendor/bin/busybox rmmod probeRW 2>/dev/null; /vendor/bin/busybox insmod /data/local/tmp/probeRW.ko addr=0x23080000 len=16 op=r; rmmod probeRW; /vendor/bin/busybox cat /data/local/tmp/probeRW.out" | tr -d '\r' | grep -E '^[0-9a-f]{16}:' | tail -1 | sed 's/^/  /'
  else
    echo "run$n: NO RETURN after 300s"; exit 4
  fi
done
