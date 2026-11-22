#!/system/bin/sh
BB=/vendor/bin/busybox
echo "bank  CTRL  STR_L STR_H STR_EX   (gop0 bank b, win0)"
for b in 0 1 2 3 4 5 6 7; do
  A=$(printf '0x1f%04x00' $((0x2400 + b*2)))
  A=$((0x1f240000 + b*0x200))
  ADDR=$(printf '0x%x' $A)
  $BB rmmod probeRW 2>/dev/null; $BB insmod /data/local/tmp/probeRW.ko addr=$ADDR len=16 op=r >/dev/null 2>&1; rmmod probeRW 2>/dev/null
  printf "b%d   %s\n" $b "$($BB grep -E '^[0-9a-f]{16}:' /data/local/tmp/probeRW.out | $BB sed 's/.*: //')"
done
