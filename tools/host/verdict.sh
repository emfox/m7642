#!/system/bin/sh
BB=/vendor/bin/busybox
M=/dev/block/by-name/misc
echo "-- misc marker @8192"
$BB dd if=$M bs=4096 skip=2 count=1 2>/dev/null | $BB hexdump -C | $BB head -2
echo "-- misc BCB @0"
$BB dd if=$M bs=512 count=1 2>/dev/null | $BB hexdump -C | $BB head -2
echo "-- misc non-zero bytes in first 64 KiB"
$BB dd if=$M bs=4096 count=16 2>/dev/null | $BB tr -d '\000' | $BB wc -c
echo "-- pstore"
$BB ls -l /sys/fs/pstore/ 2>&1
echo "-- uptime/bootreason"
cut -d. -f1 /proc/uptime; getprop ro.boot.bootreason
