#!/system/bin/sh
BB=/vendor/bin/busybox
rd() { $BB rmmod probeRW 2>/dev/null; $BB insmod /data/local/tmp/probeRW.ko addr=$1 len=4 op=r >/dev/null 2>&1; rmmod probeRW 2>/dev/null; $BB grep -E '^[0-9a-f]{16}:' /data/local/tmp/probeRW.out | $BB awk '{print $2$3$4$5}'; }
wr() { $BB rmmod probeRW 2>/dev/null; $BB insmod /data/local/tmp/probeRW.ko addr=$1 len=4 op=w val=$2 >/dev/null 2>&1; rmmod probeRW 2>/dev/null; }
echo "-- step1: strh 1 -> 0x1f201fcc"
wr 0x1f201fcc 1
$BB sleep 1
echo "-- step2: read 0x1f20210c"
V=$(rd 0x1f20210c); echo "   raw=$V"
# little endian: first bytes are the low half
LOW=$((0x${V#????????}))
echo "   low32=0x$(printf %08x $LOW)"
NEW=$(( LOW & ~1 ))
printf "   writing 0x%08x\n" $NEW
wr 0x1f20210c $NEW
$BB sleep 1
echo "-- step3: strh 1 -> 0x1f20210c"
wr 0x1f20210c 1
echo "-- done, observe"
