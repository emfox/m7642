#!/system/bin/sh
BB=/vendor/bin/busybox
echo "-- misc first 512 B"
$BB dd if=/dev/block/by-name/misc bs=512 count=1 2>/dev/null | $BB hexdump -C | head -8
echo "-- misc non-zero bytes"
$BB dd if=/dev/block/by-name/misc bs=4096 count=1 2>/dev/null | tr -d '\000' | wc -c
echo "-- recovery slot now"
$BB dd if=/dev/block/by-name/recovery bs=1048576 2>/dev/null | $BB md5sum
echo "-- cmdline"
cat /proc/cmdline
