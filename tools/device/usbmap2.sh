#!/system/bin/sh
# Targeted 64-byte reads around the m7642 USB block map.
# Single reads only -- no scanning (a wide sweep reset the TV once before).
set -x
sh /data/local/tmp/rung.sh "addr=0xffffff800a220000 len=64"  > /data/local/tmp/r_a.txt 2>&1
sh /data/local/tmp/rung.sh "addr=0xffffff800a224000 len=64"  > /data/local/tmp/r_b.txt 2>&1
sh /data/local/tmp/rung.sh "addr=0xffffff800a229000 len=64"  > /data/local/tmp/r_c.txt 2>&1
sh /data/local/tmp/rung.sh "addr=0xffffff800a6e2200 len=64"  > /data/local/tmp/r_d.txt 2>&1
chmod 644 /data/local/tmp/r_?.txt
echo RUNDONE
