#!/system/bin/sh
BB=/vendor/bin/busybox
echo "bank  off  CTRL    +4      +8      +12   (each bank 0x200, base 0x1f240400)"
for b in 0 1 2 3 4 5 6 7; do
  base=$((0x1f240400 + b*0x200))
  for w in 0 1 2 3; do
    off=$((base + w*0x40))
    $BB rmmod probeRW 2>/dev/null; $BB insmod /data/local/tmp/probeRW.ko addr=$(printf '0x%x' $off) len=16 op=r >/dev/null 2>&1; rmmod probeRW 2>/dev/null
    printf "b%d w%d %s\n" $b $w "$($BB grep -E '^[0-9a-f]{16}:' /data/local/tmp/probeRW.out | $BB sed 's/^[^:]*: //')"
  done
done
