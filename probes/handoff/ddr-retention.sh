#!/bin/bash
# Does DRAM survive standby?  Write two markers, sleep the TV, wake it, read back.
set -u
export PATH=$HOME/.local/bin:$PATH
ADB=/home/emfox/Debian/tv/adb/platform-tools/adb
TV=192.168.10.60:5555
root(){ $ADB -s $TV exec-out su -c "$1"; }
ready(){ $ADB connect $TV >/dev/null 2>&1; [ "$(root 'getprop sys.boot_completed' 2>/dev/null | tr -d '\r')" = 1 ]; }
for w in $(seq 1 30); do ready && break; sleep 5; done
ready || { echo "not ready"; exit 9; }
echo "-- write markers"
$ADB -s $TV push $HOME/Debian/m7642-build/out/m7642-rec-73-snap.img /dev/null 2>/dev/null || true
root "/vendor/bin/busybox insmod /data/local/tmp/probeRW.ko addr=0x23400000 len=4 op=w val=0xdeadbeef; rmmod probeRW; /vendor/bin/busybox insmod /data/local/tmp/probeRW.ko addr=0x23080000 len=4 op=w val=0xfeedface; rmmod probeRW; /vendor/bin/busybox insmod /data/local/tmp/probeRW.ko addr=0x23400000 len=4 op=r; rmmod probeRW; /vendor/bin/busybox grep -E '^[0-9a-f]{16}:' /data/local/tmp/probeRW.out" | tr -d '\r' | sed 's/^/  before: /'
echo "-- standby"
~/Debian/m7642/tools/host/tvpower.sh off 2>&1 | tail -1
sleep 12
echo "-- wake"
~/Debian/m7642/tools/host/tvpower.sh on 2>&1 | tail -2
for w in $(seq 1 40); do ready && break; sleep 5; done
ready || { echo "did not come back"; exit 9; }
root "/vendor/bin/busybox insmod /data/local/tmp/probeRW.ko addr=0x23400000 len=4 op=r; rmmod probeRW; /vendor/bin/busybox grep -E '^[0-9a-f]{16}:' /data/local/tmp/probeRW.out" | tr -d '\r' | sed 's/^/  0x23400000 after: /'
root "/vendor/bin/busybox insmod /data/local/tmp/probeRW.ko addr=0x23080000 len=4 op=r; rmmod probeRW; /vendor/bin/busybox grep -E '^[0-9a-f]{16}:' /data/local/tmp/probeRW.out" | tr -d '\r' | sed 's/^/  0x23080000 after: /'
