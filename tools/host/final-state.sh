#!/system/bin/sh
BB=/vendor/bin/busybox
echo "-- uptime $(cut -d. -f1 /proc/uptime)s"
echo "-- boot slot:     $($BB dd if=/dev/block/by-name/boot bs=1048576 count=32 2>/dev/null | $BB md5sum | $BB cut -d' ' -f1)  want 6272b10dcaf5e9efa40491d87f2c1289"
echo "-- recovery slot: $($BB md5sum /dev/block/by-name/recovery | $BB cut -d' ' -f1)  want 7c2f467bbda49053951c0ce547d11a00"
echo "-- misc BCB: $($BB dd if=/dev/block/by-name/misc bs=1 count=16 2>/dev/null | $BB od -A n -t x1)"
echo "-- data: $($BB df -h /data | $BB tail -1)"
