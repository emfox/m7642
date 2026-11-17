#!/system/bin/sh
# usage: rung.sh "sym=NAME len=256"   (params are passed through to insmod)
/vendor/bin/busybox rmmod probeG 2>/dev/null
rm -f /data/local/tmp/probeG.out
/vendor/bin/busybox insmod /data/local/tmp/probeG.ko $1
echo "insmod_rc=$?"
/system/bin/rmmod probeG
echo "rmmod_rc=$?"
chmod 644 /data/local/tmp/probeG.out 2>/dev/null
cat /data/local/tmp/probeG.out 2>&1 | head -80
