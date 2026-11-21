#!/system/bin/sh
BB=/vendor/bin/busybox
wr(){ $BB rmmod probeRW 2>/dev/null; $BB insmod /data/local/tmp/probeRW.ko addr=$1 len=$3 op=w val=$2 >/dev/null 2>&1; rmmod probeRW 2>/dev/null; }
rd(){ $BB rmmod probeRW 2>/dev/null; $BB insmod /data/local/tmp/probeRW.ko addr=$1 len=4 op=r >/dev/null 2>&1; rmmod probeRW 2>/dev/null; $BB grep -E '^[0-9a-f]{16}:' /data/local/tmp/probeRW.out | $BB sed 's/.*: //'; }
echo "-- 0xa01fe000 before: $(rd 0xa01fe000)"
wr 0xa01fe000 0 4
$BB sleep 1
echo "-- after clear:       $(rd 0xa01fe000)"
echo "-- step1 0x1f201fcc"; wr 0x1f201fcc 1 4
$BB sleep 1
echo "-- step2 0x1f20210c=0"; wr 0x1f20210c 0 4
$BB sleep 1
echo "-- step3 0x1f20210c=1"; wr 0x1f20210c 1 4
echo done
