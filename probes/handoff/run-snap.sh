#!/bin/bash
set -u
ADB=/home/emfox/Debian/tv/adb/platform-tools/adb
TV=192.168.10.60:5555
IMD5=d8d207d9f365fadeab5b7340cd7ed74a
root(){ $ADB -s $TV exec-out su -c "$1"; }
ready(){ $ADB connect $TV >/dev/null 2>&1; [ "$(root 'getprop sys.boot_completed' 2>/dev/null | tr -d '\r')" = 1 ]; }
for n in 1 2 3; do
  for w in $(seq 1 40); do ready && break; sleep 5; done
  ready || { echo "run$n: not ready"; exit 9; }
  $ADB -s $TV push $HOME/kbuild/m7642-out/m7642-rec-73-snap.img /data/local/tmp/s.img >/dev/null
  o=$(root "dd if=/data/local/tmp/s.img of=/dev/block/by-name/recovery bs=4096 2>/dev/null; sync; md5sum /dev/block/by-name/recovery" | tr -d '\r' | cut -d' ' -f1)
  [ "$o" = "$IMD5" ] || { echo "run$n: slot mismatch"; exit 1; }
  echo "=== run$n $(date +%H:%M:%S)"
  $ADB -s $TV reboot recovery; sleep 14
  ok=""
  for i in $(seq 1 60); do ready && { ok=1; break; }; sleep 5; done
  [ -z "$ok" ] && { echo "run$n: NO RETURN"; exit 4; }
  root "/vendor/bin/busybox rmmod probeRW 2>/dev/null; /vendor/bin/busybox insmod /data/local/tmp/probeRW.ko addr=0x23080000 len=208 op=r; rmmod probeRW; /vendor/bin/busybox cat /data/local/tmp/probeRW.out" | tr -d '\r' | grep -E '^[0-9a-f]{16}:' > /tmp/snap$n.txt
  md5sum /tmp/snap$n.txt | cut -d' ' -f1 | sed 's/^/  snapshot md5 /'
done
echo "--- diff run1 vs run2:"; diff /tmp/snap1.txt /tmp/snap2.txt && echo "  identical"
echo "--- diff run1 vs run3:"; diff /tmp/snap1.txt /tmp/snap3.txt && echo "  identical"
echo "--- run1 snapshot:"; sed -n '1,6p' /tmp/snap1.txt
