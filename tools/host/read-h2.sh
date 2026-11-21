#!/system/bin/sh
# Read the eight handoff2 stash sites through probeRW.
BB=/vendor/bin/busybox
for k in 0 1 2 3 4 5 6 7; do
    A=$(printf '0x230%x0000' $((8+k)))
    $BB rmmod probeRW 2>/dev/null
    rmmod probeRW 2>/dev/null
    $BB insmod /data/local/tmp/probeRW.ko addr=$A len=64 op=r >/dev/null 2>&1
    rmmod probeRW 2>/dev/null
    echo "== $A"
    $BB grep '^0000' /data/local/tmp/probeRW.out 2>/dev/null
done
