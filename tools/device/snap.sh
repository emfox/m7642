#!/system/bin/sh
# usage: snap.sh <out-file> [extra insmod params...]
OUT="$1"; shift
/vendor/bin/busybox rmmod probeS 2>/dev/null
rm -f "$OUT"
/vendor/bin/busybox insmod /data/local/tmp/probeS.ko out="$OUT" "$@"
/system/bin/rmmod probeS 2>/dev/null
chmod 644 "$OUT" 2>/dev/null
wc -l "$OUT" 2>&1
