#!/system/bin/sh
# usage: runmany.sh "<param set 1>" "<param set 2>" ...
# Runs probeG once per parameter set and concatenates the outputs.
OUT=/data/local/tmp/multi.out
: > "$OUT"
for p in "$@"; do
  /vendor/bin/busybox rmmod probeG 2>/dev/null
  rm -f /data/local/tmp/probeG.out
  /vendor/bin/busybox insmod /data/local/tmp/probeG.ko $p >/dev/null 2>&1
  /system/bin/rmmod probeG 2>/dev/null
  echo "===== $p" >> "$OUT"
  cat /data/local/tmp/probeG.out >> "$OUT" 2>/dev/null
done
chmod 644 "$OUT"
wc -l "$OUT"
