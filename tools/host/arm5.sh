#!/system/bin/sh
set -e
BB=/vendor/bin/busybox
R=/dev/block/by-name/recovery
E=$(dd if=/dev/block/mmcblk0 bs=4096 skip=2528 count=32 2>/dev/null | $BB md5sum | cut -d' ' -f1)
S=$($BB md5sum $R | cut -d' ' -f1)
I=$($BB md5sum /data/local/tmp/rec-ret.img | cut -d' ' -f1)
echo "-- env  $E  (want a8397431901a1e7032c6651a1b732c66)"
echo "-- slot $S  (want 7c2f467bbda49053951c0ce547d11a00 factory)"
echo "-- img  $I  (want 3a950d5064b4569f47df1d4337faa2f6)"
[ "$E" = "a8397431901a1e7032c6651a1b732c66" ] || { echo "FAIL env"; exit 1; }
[ "$I" = "3a950d5064b4569f47df1d4337faa2f6" ] || { echo "FAIL img"; exit 1; }
$BB dd if=/data/local/tmp/rec-ret.img of=$R bs=4096 2>/dev/null
$BB sync
echo "-- slot now $($BB md5sum $R | cut -d' ' -f1)"
echo "-- bcb $($BB dd if=/dev/block/by-name/misc bs=1 count=16 2>/dev/null | $BB od -A n -t x1)"
echo "-- uptime $(cut -d. -f1 /proc/uptime)"
echo ARMED-RET-NOWDT
