#!/system/bin/sh
set -e
BB=/vendor/bin/busybox
R=/dev/block/by-name/recovery
echo "-- slot before: $($BB md5sum $R | cut -d' ' -f1)  (want factory 7c2f467bbda49053951c0ce547d11a00)"
echo "-- img md5:     $($BB md5sum /data/local/tmp/paintgreen.img | cut -d' ' -f1)  (want c758519710a7681a8087f98375ba720f)"
$BB dd if=/data/local/tmp/paintgreen.img of=$R bs=4096 2>/dev/null
$BB sync
echo "-- slot after:  $($BB md5sum $R | cut -d' ' -f1)"
echo "-- code1:       $($BB dd if=$R bs=1 skip=2052 count=4 2>/dev/null | $BB od -A n -t x1)"
echo "-- probe word at kernel+0x12d4a00:"
$BB dd if=$R bs=1 skip=$((2048+0x12d4a00)) count=40 2>/dev/null | $BB od -A n -t x4 | $BB head -3
echo "-- bcb: $($BB dd if=/dev/block/by-name/misc bs=1 count=16 2>/dev/null | $BB od -A n -t x1)"
echo PAINT-ARMED
