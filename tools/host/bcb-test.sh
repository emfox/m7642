#!/bin/bash
# Deterministic recovery entry + WDT test.
#
# Removes the two hidden variables the earlier rounds left open:
#   1. whether mboot ever entered recovery  -> marker in misc page 2; only
#      `mmc erase.p misc` (first command of recoverycmd) can remove it
#   2. whether the WDT actually fires       -> the probe hangs; if the box comes
#      back on its own the watchdog reset it, if not it just sat there
set -u
ADB=/home/emfox/Debian/tv/adb/platform-tools/adb
TV=192.168.10.60:5555
IMG=/home/emfox/Debian/m7642-build/out/m7642-rec-handoff1-hang.img
IMD5=4cdbc794195c44bf964639d0eaf0c9fd
dev() { $ADB -s $TV shell "$@"; }
root() { $ADB -s $TV exec-out su -c "$1"; }
$ADB connect $TV >/dev/null 2>&1
[ "$(dev getprop sys.boot_completed 2>/dev/null | tr -d '\r')" = 1 ] || { echo "not in Android"; exit 1; }
echo "uptime $(dev cut -d. -f1 /proc/uptime | tr -d '\r')s"

$ADB -s $TV push "$IMG" /data/local/tmp/hang1.img >/dev/null
o=$(root "md5sum /data/local/tmp/hang1.img" | tr -d '\r' | cut -d' ' -f1)
[ "$o" = "$IMD5" ] || { echo "img md5 $o"; exit 1; }
o=$(root "dd if=/data/local/tmp/hang1.img of=/dev/block/by-name/recovery bs=4096 2>/dev/null; sync; md5sum /dev/block/by-name/recovery" | tr -d '\r' | cut -d' ' -f1)
echo "slot $o"
[ "$o" = "$IMD5" ] || { echo "slot mismatch"; exit 1; }

# 1. marker in misc page 2 (offset 8192), far from the BCB fields
printf 'M7642MISCMARK%.0s' $(seq 1 128) > /tmp/mark.bin
$ADB -s $TV push /tmp/mark.bin /data/local/tmp/mark.bin >/dev/null
# 2. BCB = "boot-recovery" ourselves, then marker
root 'printf boot-recovery > /data/local/tmp/bcb.bin; /vendor/bin/busybox dd if=/data/local/tmp/bcb.bin of=/dev/block/by-name/misc bs=512 count=1 2>/dev/null; /vendor/bin/busybox dd if=/data/local/tmp/mark.bin of=/dev/block/by-name/misc bs=4096 seek=2 count=1 2>/dev/null; /vendor/bin/busybox sync; echo "-- BCB now:"; /vendor/bin/busybox dd if=/dev/block/by-name/misc bs=1 count=16 2>/dev/null | /vendor/bin/busybox od -A n -t c; echo "-- marker now:"; /vendor/bin/busybox dd if=/dev/block/by-name/misc bs=4096 skip=2 count=1 2>/dev/null | /vendor/bin/busybox head -c 16; echo' | tr -d '\r'
echo "=== reboot at $(date +%H:%M:%S)  (BCB set by us, hang probe, wdt_enable 10)"
$ADB -s $TV reboot recovery
sleep 8
for i in $(seq 1 24); do
  sleep 5
  $ADB connect $TV >/dev/null 2>&1
  s=$(dev getprop sys.boot_completed 2>/dev/null | tr -d '\r')
  if [ "$s" = 1 ]; then
    u=$(dev cut -d. -f1 /proc/uptime | tr -d '\r')
    echo "=== Android at $(date +%H:%M:%S) uptime ${u}s"
    echo "--- misc after (marker gone => recoverycmd ran; BCB empty => erase ran)"
    root '/vendor/bin/busybox dd if=/dev/block/by-name/misc bs=1 count=16 2>/dev/null | /vendor/bin/busybox od -A n -t x1; /vendor/bin/busybox dd if=/dev/block/by-name/misc bs=4096 skip=2 count=1 2>/dev/null | /vendor/bin/busybox head -c 8' | tr -d '\r'
    exit 0
  fi
done
echo "=== no self-return within ~130 s"
