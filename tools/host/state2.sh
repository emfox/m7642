#!/system/bin/sh
BB=/vendor/bin/busybox
echo "-- uptime $(cut -d. -f1 /proc/uptime)s  completed=$(getprop sys.boot_completed)"
echo "-- boot slot  $($BB dd if=/dev/block/by-name/boot bs=1048576 count=32 2>/dev/null | $BB md5sum | $BB cut -d' ' -f1)  want 6272b10dcaf5e9efa40491d87f2c1289"
echo "-- recovery   $($BB md5sum /dev/block/by-name/recovery | $BB cut -d' ' -f1)  want 7c2f467bbda49053951c0ce547d11a00"
echo "-- misc head  $($BB dd if=/dev/block/by-name/misc bs=1 count=16 2>/dev/null | $BB od -A n -t x1)"
echo "-- pstore:"; $BB ls -l /sys/fs/pstore/ 2>&1
echo "-- fdt header @0x23000000"
$BB rmmod probeRW 2>/dev/null
$BB insmod /data/local/tmp/probeRW.ko addr=0x23000000 len=64 op=r 2>&1 | $BB head -2
rmmod probeRW 2>/dev/null
$BB cat /data/local/tmp/probeRW.out 2>/dev/null
echo "-- tail of 1MB dtb load region @0x230F0000"
$BB insmod /data/local/tmp/probeRW.ko addr=0x230f0000 len=32 op=r 2>&1 | $BB head -1
rmmod probeRW 2>/dev/null
$BB cat /data/local/tmp/probeRW.out 2>/dev/null
