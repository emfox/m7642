#!/system/bin/sh
BB=/vendor/bin/busybox
echo "-- module files on device:"
$BB find /vendor /system -name '*utpa2k*' -o -name '*mik*' 2>/dev/null | $BB head -5
$BB ls /vendor/lib/modules 2>/dev/null | $BB head -8
echo "-- arm and read rc immediately"
rmmod wdtarm 2>/dev/null
$BB insmod /data/local/tmp/wdtarm.ko secs=10
rmmod wdtarm
echo "-- dmesg right after:"
$BB dmesg | $BB grep -i wdtarm | $BB tail -4
