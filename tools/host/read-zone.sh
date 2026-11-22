#!/system/bin/sh
# Read the pmsg zone at 0x419c0000 from a normally booted Android via probeRW.
# probeRW does its work in module_exit, so the read happens on unload.
# busybox rmmod insists on /lib/modules (absent here); toybox rmmod does not.
BB=/vendor/bin/busybox
KO=/data/local/tmp/probeRW.ko
OUT=/data/local/tmp/probeRW.out

echo "-- loaded?"
$BB lsmod | grep -i probe || echo "not loaded"

if ! $BB lsmod | grep -qi probe; then
    echo "-- insmod"
    $BB insmod $KO addr=0x419c0000 len=96 op=r; echo "insmod rc=$?"
fi

echo "-- unload (performs the read)"
rmmod probeRW; echo "rmmod rc=$?"

echo "-- out"
if [ -f $OUT ]; then cat $OUT; else echo "MISSING $OUT"; fi
