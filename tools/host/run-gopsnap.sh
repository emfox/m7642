#!/bin/bash
set -u
export PATH=$HOME/.local/bin:$PATH
ADB=/home/emfox/Debian/tv/adb/platform-tools/adb
TV=192.168.10.60:5555
IMD5=a2a2fc39fd363fd68a8ce7ac5614a452
root(){ $ADB -s $TV exec-out su -c "$1"; }
$ADB connect $TV >/dev/null 2>&1
$ADB -s $TV push $HOME/Debian/m7642-build/out/m7642-boot-gopsnap.img /data/local/tmp/gopsnap.img >/dev/null
o=$(root "dd if=/data/local/tmp/gopsnap.img of=/dev/block/by-name/boot bs=4096 2>/dev/null; sync; md5sum /dev/block/by-name/boot" | tr -d '\r' | cut -d' ' -f1)
echo "boot slot -> $o"; [ "$o" = "$IMD5" ] || { echo FAIL; exit 1; }
echo "=== reboot $(date +%H:%M:%S)"; $ADB -s $TV reboot; sleep 10
echo "=== press $(date +%H:%M:%S)"; ~/Debian/m7642/tools/host/tvpower.sh on | tail -1
for i in $(seq 1 12); do $ADB connect $TV >/dev/null 2>&1; s=$(root 'getprop sys.boot_completed' 2>/dev/null | tr -d '\r'); [ "$s" = 1 ] && break; sleep 5; done
echo "--- boot-time GOP snapshot:"
for k in 0 1 2 3 4 5 6 7; do
  a=$(printf '0x230%x0000' $((8+k)))
  root "/vendor/bin/busybox rmmod probeRW 2>/dev/null; /vendor/bin/busybox insmod /data/local/tmp/probeRW.ko addr=$a len=64 op=r; rmmod probeRW; /vendor/bin/busybox grep -E '^[0-9a-f]{16}:' /data/local/tmp/probeRW.out" | tr -d '\r'
done | tee /tmp/gop-boot.txt
o=$(root "dd if=/data/local/tmp/boot-factory.img of=/dev/block/by-name/boot bs=4096 2>/dev/null; sync; md5sum /dev/block/by-name/boot" | tr -d '\r' | cut -d' ' -f1)
echo "--- boot slot restored: $o"
