#!/system/bin/sh
BB=/vendor/bin/busybox
for a in 0x4206000 0x4206010 0x4206020; do
  $BB rmmod probeRW 2>/dev/null
  $BB insmod /data/local/tmp/probeRW.ko addr=$a len=16 op=r 2>&1 | $BB head -1
  rmmod probeRW 2>/dev/null
  $BB grep -E '^[0-9a-f]{16}:' /data/local/tmp/probeRW.out 2>/dev/null
done
