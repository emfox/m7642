#!/system/bin/sh
# Decide whether 0x2d100000 is the live scanout buffer, without looking at the
# panel: read it twice, flood it, read back, wait, read again.
#
# A != B                 something is drawing into it        -> live
# D <= our fill          the write landed
# E back to non-fill     it is being redrawn                 -> live scanout
K=/data/local/tmp/probeRW.ko

run() {
	/vendor/bin/busybox rmmod probeRW 2>/dev/null
	/vendor/bin/busybox insmod "$K" "$@" 2>/dev/null
	/system/bin/rmmod probeRW 2>/dev/null
	sleep 1
	chmod 644 /data/local/tmp/probeRW.out 2>/dev/null
	grep -E '^[0-9a-f]{16}:' /data/local/tmp/probeRW.out | head -1
}

echo "== A =="
run addr=0x2d100000 len=16 op=r
sleep 2
echo "== B (2 s later) =="
run addr=0x2d100000 len=16 op=r
echo "== flood 64 B with 0x0000ff00 =="
run addr=0x2d100000 len=64 op=f val=0x0000ff00
echo "== D (right after fill) =="
run addr=0x2d100000 len=16 op=r
sleep 3
echo "== E (3 s later) =="
run addr=0x2d100000 len=16 op=r
