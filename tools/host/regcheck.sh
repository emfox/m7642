#!/system/bin/sh
BB=/vendor/bin/busybox
rd(){ $BB rmmod probeRW 2>/dev/null; $BB insmod /data/local/tmp/probeRW.ko addr=$1 len=4 op=r >/dev/null 2>&1; rmmod probeRW 2>/dev/null; $BB grep -E '^[0-9a-f]{16}:' /data/local/tmp/probeRW.out | $BB sed 's/.*: //'; }
wr(){ $BB rmmod probeRW 2>/dev/null; $BB insmod /data/local/tmp/probeRW.ko addr=$1 len=4 op=w val=$2 >/dev/null 2>&1; rmmod probeRW 2>/dev/null; }
echo "before 0x1f201fcc: $(rd 0x1f201fcc)"
echo "before 0x1f20210c: $(rd 0x1f20210c)"
wr 0x1f201fcc 0x1234
wr 0x1f20210c 0x1234
$BB sleep 1
echo "after  0x1f201fcc: $(rd 0x1f201fcc)"
echo "after  0x1f20210c: $(rd 0x1f20210c)"
