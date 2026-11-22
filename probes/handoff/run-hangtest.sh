#!/bin/bash
# Prove the harness self-recovers from a hang.
#
# Deploys a stub that writes a record and then spins forever, waits for the
# watchdog to bring Android back on its own, and reads the record out of DDR.
#
#   ./run-hangtest.sh            build (if needed) and run
#
# Success = Android returns without any human action, and probeRW finds the
# M764/HALT record the stub left behind.
set -u
D=$(cd "$(dirname "$0")" && pwd)
B=$HOME/Debian/m7642-build
ADB=/home/emfox/Debian/tv/adb/platform-tools/adb
TV=192.168.10.60:5555
CROSS=${CROSS:-$B/toolchain/gcc13/bin/aarch64-buildroot-linux-gnu-}
IMG=$B/out/m7642-rec-73-halt.img
root(){ $ADB -s $TV exec-out su -c "$1" | tr -d '\r'; }
ready(){ $ADB connect $TV >/dev/null 2>&1; [ "$(root 'getprop sys.boot_completed' 2>/dev/null)" = 1 ]; }

# --- build
if [ ! -f "$IMG" ] || [ "${REBUILD:-0}" = 1 ]; then
	"${CROSS}gcc" -c -o /tmp/halt.o "$D/halt.S"
	"${CROSS}objcopy" -O binary --only-section=.text /tmp/halt.o /tmp/halt.bin
	python3 "$D/../../tools/host/mk-mainline-abort.py" \
		--at 0x4 --stub /tmp/halt.bin --out "$IMG" | tail -2
fi
IMD5=$(md5sum "$IMG" | cut -d' ' -f1)

for w in $(seq 1 60); do ready && break; sleep 5; done
ready || { echo "SKIP: android not ready"; exit 9; }

echo "=== 镜像 $IMD5"
$ADB -s $TV push "$IMG" /data/local/tmp/halt.img >/dev/null || exit 9
o=$(root "dd if=/data/local/tmp/halt.img of=/dev/block/by-name/recovery bs=4096 2>/dev/null; sync; md5sum /dev/block/by-name/recovery" | cut -d' ' -f1)
[ "$o" = "$IMD5" ] || { echo "SKIP: slot mismatch ($o)"; exit 9; }

# the misc tail marker proves recoverycmd really ran
root "dd if=/data/local/tmp/mark.bin of=/dev/block/by-name/misc bs=512 seek=16376 count=8 2>/dev/null; sync" >/dev/null

echo "=== $(date +%H:%M:%S) 重启进 recovery，然后**不再碰设备**，看它能否自己回来"
t0=$(date +%s)
$ADB -s $TV reboot recovery
sleep 20
ok=""
for i in $(seq 1 80); do	# up to 400 s
	ready && { ok=1; break; }
	sleep 5
done
el=$(( $(date +%s) - t0 ))
if [ -n "$ok" ]; then
	echo "  ✅ 自己回到 Android，用时 ${el}s（无人工干预）"
else
	echo "  ❌ ${el}s 内没有回来 —— WDT 没布防或没生效"
	exit 8
fi

# 设备可能被 WDT 复位到待机：用红外补一次电源键，全程不需要人
if ! ready; then
	echo "  ⏳ 不在 Android（很可能停在待机），发红外电源键"
	"$D/../../tools/host/tvpower.sh" on >/dev/null 2>&1 || true
	sleep 25
	for i in $(seq 1 40); do ready && break; sleep 5; done
fi

echo "=== DDR 里的记录:"
probe(){ root "/vendor/bin/busybox rmmod probeRW 2>/dev/null; /vendor/bin/busybox insmod /data/local/tmp/probeRW.ko addr=$1 len=$2 op=r; rmmod probeRW; /vendor/bin/busybox cat /data/local/tmp/probeRW.out"; }
probe 0x23090000 16 > /tmp/hang-rec.txt
probe 0x23090800 16 > /tmp/hang-mark.txt
probe 0x23100000 16 > /tmp/hang-rec2.txt
probe 0x23100800 16 > /tmp/hang-mark2.txt
python3 - /tmp/hang-rec.txt /tmp/hang-mark.txt <<'PY'
import struct, sys
def rec(p):
    out=[]
    for line in open(p).read().splitlines():
        if ":" in line:
            a,b=line.split(":",1)
            if len(a.strip())==16: out.append(b.replace(" ","").strip())
    return bytes.fromhex("".join(out)) if out else b""
r=rec(sys.argv[1]); m=rec(sys.argv[2]); r2=rec(sys.argv[3]); m2=rec(sys.argv[4])
def show(n, b, tag):
    if len(b) >= 12:
        print("  %-22s %r %r %#x" % (n, b[0:4], b[4:8], struct.unpack("<I", b[8:12])[0]))
    else:
        print("  %-22s none" % n)
show("@0x23090000 (窗内)", r, "HALT")
show("@0x23100000 (窗外)", r2, "HALT")
show("@0x23100800 marker", m2, "HANG")
ok = r2[0:4]==b"M764" and r2[4:8]==b"HALT"
print("  VERDICT: %s" % ("窗外记录活下来了 —— 不需要 eMMC 写也能拿到挂之前的读数" if ok else "窗外记录也没了 —— DDR 跨复位不保，必须上 eMMC"))
PY
echo "=== misc 标记（应已被 mmc erase.p misc 擦掉）:"
root "dd if=/dev/block/by-name/misc bs=512 skip=16376 count=1 2>/dev/null | od -An -tx1 | head -1"
