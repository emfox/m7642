#!/bin/bash
set -u
ADB=/home/emfox/Debian/tv/adb/platform-tools/adb
TV=192.168.10.60:5555
IMG=/home/emfox/Debian/m7642-build/out/m7642-rec-hangonly.img
IMD5=8ce527423b10b5f9c0a0c6a84fa1ed7e
dev() { $ADB -s $TV shell "$@"; }
root() { $ADB -s $TV exec-out su -c "$1"; }
$ADB connect $TV >/dev/null 2>&1
[ "$(dev getprop sys.boot_completed 2>/dev/null | tr -d '\r')" = 1 ] || { echo "not in Android"; exit 1; }
echo "--- kernel writes a pmsg record (this is the thing under test)"
root 'echo M7642SURV1 > /dev/pmsg0; echo "rc=$?"' | tr -d '\r'
echo "--- zone after the kernel write"
root '/vendor/bin/busybox rmmod probeRW 2>/dev/null; /vendor/bin/busybox insmod /data/local/tmp/probeRW.ko addr=0x419c0000 len=32 op=r; rmmod probeRW; cat /data/local/tmp/probeRW.out' | tr -d '\r' | tail -3
$ADB -s $TV push "$IMG" /data/local/tmp/hangonly.img >/dev/null
o=$(root "md5sum /data/local/tmp/hangonly.img" | tr -d '\r' | cut -d' ' -f1)
[ "$o" = "$IMD5" ] || { echo "img md5 mismatch on device: $o"; exit 1; }
o=$(root "dd if=/data/local/tmp/hangonly.img of=/dev/block/by-name/recovery bs=4096 2>/dev/null; sync; md5sum /dev/block/by-name/recovery" | tr -d '\r' | cut -d' ' -f1)
echo "--- slot now $o"
[ "$o" = "$IMD5" ] || { echo "slot readback mismatch"; exit 1; }
echo "=== reboot recovery at $(date +%H:%M:%S)  (pure b . -> 10 s WDT)"
$ADB -s $TV reboot recovery
