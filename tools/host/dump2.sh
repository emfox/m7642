#!/system/bin/sh
# dump a symbol to /data/local/tmp/wdtdump.bin and print its runtime address
BB=/vendor/bin/busybox
S=$1
L=${2:-1024}
$BB rmmod wdtdump 2>/dev/null
$BB insmod /data/local/tmp/wdtdump.ko sym=$S len=$L 2>&1 | head -2
rmmod wdtdump 2>/dev/null
$BB dmesg | $BB grep wdtdump | $BB tail -2
