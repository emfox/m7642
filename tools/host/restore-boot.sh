#!/system/bin/sh
set -e
BB=/vendor/bin/busybox
B=/dev/block/by-name/boot
echo "-- boot now  $($BB md5sum $B | cut -d' ' -f1)"
echo "-- img md5   $($BB md5sum /data/local/tmp/boot-factory.img | cut -d' ' -f1)  want 6272b10dcaf5e9efa40491d87f2c1289"
$BB dd if=/data/local/tmp/boot-factory.img of=$B bs=4096 2>/dev/null
$BB sync
echo "-- boot restored $($BB md5sum $B | cut -d' ' -f1)"
echo "-- recovery slot $($BB md5sum /dev/block/by-name/recovery | cut -d' ' -f1)"
