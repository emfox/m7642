#!/system/bin/sh
# Two-stage GOP experiment: repoint without commit, hold, then commit, hold.
# Paint first so the moment the window actually moves, the panel shows it.
chmod 755 /data/local/tmp/fbfill
/data/local/tmp/fbfill 0xff00cc00
echo "painted"
sh /data/local/tmp/runprobe.sh probeY
cat /data/local/tmp/probeY.out
echo ALLDONE
