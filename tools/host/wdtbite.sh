#!/system/bin/sh
BB=/vendor/bin/busybox
echo "-- WDT regs before (VA 0xffffff800a006000 = phys 0x1f006000)"
for a in 0x1f006000 0x1f006008 0x1f00600c 0x1f006010; do
  $BB rmmod probeRW 2>/dev/null; $BB insmod /data/local/tmp/probeRW.ko addr=$a len=4 op=r >/dev/null 2>&1; rmmod probeRW 2>/dev/null
  printf "  %-12s %s\n" $a "$($BB grep -E '^[0-9a-f]{16}:' /data/local/tmp/probeRW.out | $BB sed 's/.*: //')"
done
echo "-- set timeout to 1 tick (~5.5 ms) at 0x1f00600c"
$BB rmmod probeRW 2>/dev/null; $BB insmod /data/local/tmp/probeRW.ko addr=0x1f00600c len=4 op=w val=1 >/dev/null 2>&1; rmmod probeRW 2>/dev/null
echo "-- done (expect reset within ms if the WDT is running)"
