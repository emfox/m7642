#!/bin/bash
set -u
export PATH=$HOME/.local/bin:$PATH
ADB=/home/emfox/Debian/tv/adb/platform-tools/adb
TV=192.168.10.60:5555
IMG=$HOME/Debian/m7642-build/out/m7642-boot-gopstash.img
IMD5=79fa577682e9637e8f98353aa17378f5
root(){ $ADB -s $TV exec-out su -c "$1"; }
$ADB connect $TV >/dev/null 2>&1
[ "$(root 'getprop sys.boot_completed' | tr -d '\r')" = 1 ] || { echo "not in Android"; exit 1; }
$ADB -s $TV push "$IMG" /data/local/tmp/gopstash.img >/dev/null
o=$(root "dd if=/data/local/tmp/gopstash.img of=/dev/block/by-name/boot bs=4096 2>/dev/null; sync; md5sum /dev/block/by-name/boot" | tr -d '\r' | cut -d' ' -f1)
echo "boot slot -> $o (want $IMD5)"; [ "$o" = "$IMD5" ] || { echo "write failed"; exit 1; }
echo "=== reboot at $(date +%H:%M:%S)"; $ADB -s $TV reboot; sleep 10
echo "=== press at $(date +%H:%M:%S)"; ~/Debian/m7642/tools/host/tvpower.sh on | tail -2
for i in $(seq 1 12); do $ADB connect $TV >/dev/null 2>&1; s=$(root 'getprop sys.boot_completed' 2>/dev/null | tr -d '\r'); [ "$s" = 1 ] && { echo "android up $(date +%H:%M:%S) uptime $(root 'cut -d. -f1 /proc/uptime' | tr -d '\r')s"; break; }; sleep 5; done
echo "--- stash pages:"
for k in 0 1 2 3 4 5 6 7; do
  a=$(printf '0x230%x0000' $((8+k)))
  root "/vendor/bin/busybox rmmod probeRW 2>/dev/null; /vendor/bin/busybox insmod /data/local/tmp/probeRW.ko addr=$a len=32 op=r; rmmod probeRW; /vendor/bin/busybox grep -E '^[0-9a-f]{16}:' /data/local/tmp/probeRW.out" | tr -d '\r' | sed "s/^/$a /"
done
echo "--- restore boot slot"
o=$(root "dd if=/data/local/tmp/boot-factory.img of=/dev/block/by-name/boot bs=4096 2>/dev/null; sync; md5sum /dev/block/by-name/boot" | tr -d '\r' | cut -d' ' -f1)
echo "boot slot now $o (want 6272b10dcaf5e9efa40491d87f2c1289)"
