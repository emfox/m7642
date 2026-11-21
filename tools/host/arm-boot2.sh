#!/system/bin/sh
set -e
BB=/vendor/bin/busybox
B=/dev/block/by-name/boot
echo "-- boot before $($BB md5sum $B | cut -d' ' -f1)  want 6272b10dcaf5e9efa40491d87f2c1289"
echo "-- img on dev  $($BB md5sum /data/local/tmp/handoff2.img | cut -d' ' -f1)  want eed03941e51f3f30ba4884fdc887965f"
[ "$($BB md5sum $B | cut -d' ' -f1)" = "6272b10dcaf5e9efa40491d87f2c1289" ] || { echo FAIL-boot-not-factory; exit 1; }
[ "$($BB md5sum /data/local/tmp/handoff2.img | cut -d' ' -f1)" = "eed03941e51f3f30ba4884fdc887965f" ] || { echo FAIL-img; exit 1; }
$BB dd if=/data/local/tmp/handoff2.img of=$B bs=4096 2>/dev/null
$BB sync
echo "-- boot after  $($BB md5sum $B | cut -d' ' -f1)"
echo "-- code1       $($BB dd if=$B bs=1 skip=2052 count=4 2>/dev/null | $BB od -A n -t x1)"
echo ARMED-BOOT-HANDOFF2
