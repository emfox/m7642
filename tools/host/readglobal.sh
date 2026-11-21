#!/system/bin/sh
BB=/vendor/bin/busybox
A=$1
L=${2:-16}
$BB rmmod wdtdump 2>/dev/null
$BB insmod /data/local/tmp/wdtdump.ko vaddr=$A len=$L 2>&1 | head -2
rmmod wdtdump 2>/dev/null
echo "--- dumped:"
$BB od -A x -t x4 /data/local/tmp/wdtdump.bin 2>&1 | head -4
echo "--- dmesg:"
$BB dmesg | $BB grep wdtdump | $BB tail -2
