#!/system/bin/sh
set -e
BB=/vendor/bin/busybox
R=/dev/block/by-name/recovery
echo "-- env file md5: $($BB md5sum /data/local/tmp/env-nowdt.bin | cut -d' ' -f1)  (want a8397431901a1e7032c6651a1b732c66)"
$BB dd if=/data/local/tmp/env-nowdt.bin of=/dev/block/mmcblk0 bs=4096 seek=2528 count=32 2>/dev/null
$BB sync
echo "-- env readback:  $($BB dd if=/dev/block/mmcblk0 bs=4096 skip=2528 count=32 2>/dev/null | $BB md5sum | cut -d' ' -f1)"
echo "-- img md5 on dev: $($BB md5sum /data/local/tmp/rec-hang.img | cut -d' ' -f1)  (want 4cdbc794195c44bf964639d0eaf0c9fd)"
echo "-- slot before:   $($BB md5sum $R | cut -d' ' -f1)"
$BB dd if=/data/local/tmp/rec-hang.img of=$R bs=4096 2>/dev/null
$BB sync
echo "-- slot after:    $($BB md5sum $R | cut -d' ' -f1)"
echo "-- bcb: $($BB dd if=/dev/block/by-name/misc bs=1 count=16 2>/dev/null | $BB od -A n -t x1)"
echo ARMED-NOWDT
