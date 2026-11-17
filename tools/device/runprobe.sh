#!/system/bin/sh
# Run a probe module: insmod (init is skipped on this ROM), rmmod triggers exit.
N="$1"
[ -z "$N" ] && { echo "usage: runprobe.sh <module>"; exit 1; }
rm -f "/data/local/tmp/$N.out"
/system/bin/rmmod "$N" 2>/dev/null
/vendor/bin/busybox insmod "/data/local/tmp/$N.ko"
RC=$?
echo "insmod_rc=$RC"
/system/bin/rmmod "$N"
echo "rmmod_rc=$?"
sleep 1
chmod 644 "/data/local/tmp/$N.out" 2>/dev/null
ls -l "/data/local/tmp/$N.out" 2>&1
