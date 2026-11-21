#!/bin/bash
# Fast runner: 120 s readiness, 150 s verdict.  Usage: run-fast.sh <img> <md5> <tag>
set -u
ADB=/home/emfox/Debian/tv/adb/platform-tools/adb
TV=192.168.10.60:5555
IMG=$1; IMD5=$2; TAG=$3
root(){ $ADB -s $TV exec-out su -c "$1"; }
ready(){ $ADB connect $TV >/dev/null 2>&1; [ "$(root 'getprop sys.boot_completed' 2>/dev/null | tr -d '\r')" = 1 ]; }
for w in $(seq 1 24); do ready && break; sleep 5; done
ready || { echo "SKIP $TAG: not ready"; exit 9; }
$ADB -s $TV push "$IMG" /data/local/tmp/f.img >/dev/null
o=$(root "dd if=/data/local/tmp/f.img of=/dev/block/by-name/recovery bs=4096 2>/dev/null; sync; md5sum /dev/block/by-name/recovery" | tr -d '\r' | cut -d' ' -f1)
[ "$o" = "$IMD5" ] || { echo "SKIP $TAG: slot mismatch"; exit 9; }
t0=$(date +%s); echo "=== $TAG $(date +%H:%M:%S)"
$ADB -s $TV reboot recovery; sleep 12
ok=""
for i in $(seq 1 30); do ready && { ok=1; break; }; sleep 5; done
echo "  android_up=${ok:-no} ($(( $(date +%s) - t0 ))s)"
root "/vendor/bin/busybox rmmod probeRW 2>/dev/null; /vendor/bin/busybox insmod /data/local/tmp/probeRW.ko addr=0x23080000 len=64 op=r; rmmod probeRW; /vendor/bin/busybox cat /data/local/tmp/probeRW.out" | tr -d '\r' | grep -E '^[0-9a-f]{16}:' | sed 's/^/  /'
