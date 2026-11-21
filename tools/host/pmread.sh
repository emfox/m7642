#!/system/bin/sh
BB=/vendor/bin/busybox
for a in 0x1f201fcc 0x1fa01fcc 0x1f800000 0x1f000000; do
  $BB rmmod probeRW 2>/dev/null
  $BB insmod /data/local/tmp/probeRW.ko addr=$a len=16 op=r >/dev/null 2>&1
  rmmod probeRW 2>/dev/null
  printf "%-12s " $a
  $BB grep -E '^[0-9a-f]{16}:' /data/local/tmp/probeRW.out 2>/dev/null | $BB head -1
  echo
done
