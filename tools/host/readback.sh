#!/system/bin/sh
BB=/vendor/bin/busybox
echo "-- uptime $(cut -d. -f1 /proc/uptime)s completed=$(getprop sys.boot_completed)"
echo "-- misc marker @8192: $($BB dd if=/dev/block/by-name/misc bs=4096 skip=2 count=1 2>/dev/null | $BB head -c 16)"
echo "-- misc BCB @0: $($BB dd if=/dev/block/by-name/misc bs=1 count=16 2>/dev/null | $BB od -A n -t x1)"
echo "-- slot: $($BB md5sum /dev/block/by-name/recovery | $BB cut -d' ' -f1)"
echo "-- zone 0x419c0000:"
$BB rmmod probeRW 2>/dev/null
$BB insmod /data/local/tmp/probeRW.ko addr=0x419c0000 len=32 op=r 2>/dev/null
rmmod probeRW 2>/dev/null
$BB cat /data/local/tmp/probeRW.out 2>/dev/null | $BB tail -2
echo "-- pstore: $($BB ls /sys/fs/pstore/ 2>&1)"
