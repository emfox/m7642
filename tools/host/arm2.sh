#!/system/bin/sh
set -e
BB=/vendor/bin/busybox
R=/dev/block/by-name/recovery
echo "-- slot before: $($BB md5sum $R | cut -d' ' -f1)"
$BB dd if=/data/local/tmp/rec-hang.img of=$R bs=4096 2>/dev/null
$BB sync
echo "-- slot after:  $($BB md5sum $R | cut -d' ' -f1)"
echo "-- misc marker still there: $($BB dd if=/dev/block/by-name/misc bs=4096 skip=2 count=1 2>/dev/null | $BB head -c 16)"
echo REBOOTING
