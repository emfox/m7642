#!/system/bin/sh
BB=/vendor/bin/busybox
echo "-- uptime $(cut -d. -f1 /proc/uptime)s"
echo "-- misc BCB: $($BB dd if=/dev/block/by-name/misc bs=1 count=16 2>/dev/null | $BB od -A n -t c)"
echo "-- boot slot: $($BB md5sum /dev/block/by-name/boot | cut -d' ' -f1)"
echo "-- recovery:  $($BB md5sum /dev/block/by-name/recovery | cut -d' ' -f1)"
echo "-- stash page0 (survives only if no power cut):"
$BB rmmod probeRW 2>/dev/null; $BB insmod /data/local/tmp/probeRW.ko addr=0x23080000 len=32 op=r 2>/dev/null; rmmod probeRW 2>/dev/null
$BB cat /data/local/tmp/probeRW.out 2>/dev/null | $BB tail -2
