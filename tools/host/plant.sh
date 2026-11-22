#!/system/bin/sh
# Plant a marker inside misc, far from the BCB fields, so that
# `mmc erase.p misc` (first command of recoverycmd) either wipes it or not.
# Pure marker test: independent of DDR, of pstore, and of the probe.
BB=/vendor/bin/busybox
M=/dev/block/by-name/misc
echo "-- misc size"
$BB blockdev --getsize64 $M 2>/dev/null || $BB cat /sys/class/block/mmcblk0p6/size
echo "-- plant marker at page 2 (offset 8192)"
$BB mkdir -p /data/local/tmp/x 2>/dev/null
i=0; : > /data/local/tmp/marker.bin
while [ $i -lt 4096 ]; do printf 'M7642MISCMARK' >> /data/local/tmp/marker.bin; i=$((i+16)); done
$BB dd if=/data/local/tmp/marker.bin of=$M bs=4096 seek=2 count=1 2>&1 | $BB tail -1
$BB sync
echo "-- readback page 2 (first 32 B)"
$BB dd if=$M bs=4096 skip=2 count=1 2>/dev/null | $BB hexdump -C | $BB head -2
echo "-- BCB page 0 (must still be all zero)"
$BB dd if=$M bs=512 count=1 2>/dev/null | $BB hexdump -C | $BB head -2
