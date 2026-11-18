#!/system/bin/sh
# paint fb0 green, then repoint the GOP at it and hold for a while.
# Sleep first so whoever is watching has time to look at the panel.
sleep 5
chmod 755 /data/local/tmp/fbfill
/data/local/tmp/fbfill 0xff00cc00
sh /data/local/tmp/runprobe.sh probeX
cat /data/local/tmp/probeX.out
echo ALLDONE
