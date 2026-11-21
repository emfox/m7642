#!/system/bin/sh
BB=/vendor/bin/busybox
echo "-- uptime $(cut -d. -f1 /proc/uptime)s completed=$(getprop sys.boot_completed)"
echo "-- pstore:"; $BB ls -l /sys/fs/pstore/ 2>&1 | $BB head -5
echo "-- zone 0x419c0000 now:"
$BB rmmod probeRW 2>/dev/null
$BB insmod /data/local/tmp/probeRW.ko addr=0x419c0000 len=32 op=r 2>/dev/null
rmmod probeRW 2>/dev/null
$BB cat /data/local/tmp/probeRW.out 2>/dev/null | $BB tail -2
echo "-- watchdog nodes:"
$BB ls -l /dev/watchdog* 2>&1
echo "-- watchdog in /proc/devices:"; $BB cat /proc/devices | $BB grep -i -E 'watchdog|wdt'
echo "-- wdt in dmesg:"; $BB dmesg | $BB grep -i -E 'watchdog|wdt' | $BB tail -6
echo "-- full misc/BCB:"; $BB dd if=/dev/block/by-name/misc bs=1 count=16 2>/dev/null | $BB od -A n -t x1
