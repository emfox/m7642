#!/bin/bash
set -u
export PATH=$HOME/.local/bin:$PATH
ADB=/home/emfox/Debian/tv/adb/platform-tools/adb
TV=192.168.10.60:5555
IMD5=54bd15b0e8b41b768bd4be8feb0d9cf5
root(){ $ADB -s $TV exec-out su -c "$1"; }
$ADB connect $TV >/dev/null 2>&1
$ADB -s $TV push $HOME/kbuild/m7642-out/m7642-boot-paint24e.img /data/local/tmp/paint24e.img >/dev/null
o=$(root "dd if=/data/local/tmp/paint24e.img of=/dev/block/by-name/boot bs=4096 2>/dev/null; sync; md5sum /dev/block/by-name/boot" | tr -d '\r' | cut -d' ' -f1)
echo "boot slot -> $o"; [ "$o" = "$IMD5" ] || { echo FAIL; exit 1; }
echo "=== reboot at $(date +%H:%M:%S)"; $ADB -s $TV reboot; sleep 10
echo "=== PRESS at $(date +%H:%M:%S) -- watch the screen now"; ~/Debian/m7642/tools/host/tvpower.sh on | tail -2
sleep 45
echo "--- restore boot slot"
o=$(root "dd if=/data/local/tmp/boot-factory.img of=/dev/block/by-name/boot bs=4096 2>/dev/null; sync; md5sum /dev/block/by-name/boot" | tr -d '\r' | cut -d' ' -f1)
echo "boot slot now $o (want 6272b10dcaf5e9efa40491d87f2c1289)"
