#!/system/bin/sh
set -e
BB=/vendor/bin/busybox
R=/dev/block/by-name/recovery
echo "-- slot before $($BB md5sum $R | cut -d' ' -f1)  (want factory 7c2f467bbda49053951c0ce547d11a00)"
echo "-- boot img md5 $($BB md5sum /data/local/tmp/boot-factory.img | cut -d' ' -f1)  (want 6272b10dcaf5e9efa40491d87f2c1289)"
[ "$($BB md5sum $R | cut -d' ' -f1)" = "7c2f467bbda49053951c0ce547d11a00" ] || { echo FAIL-slot; exit 1; }
[ "$($BB md5sum /data/local/tmp/boot-factory.img | cut -d' ' -f1)" = "6272b10dcaf5e9efa40491d87f2c1289" ] || { echo FAIL-img; exit 1; }
$BB dd if=/data/local/tmp/boot-factory.img of=$R bs=4096 2>/dev/null
$BB sync
echo "-- slot now    $($BB md5sum $R | cut -d' ' -f1)"
echo E1-ARMED
