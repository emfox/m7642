#!/system/bin/sh
# Verify the m7642 EHCI bases recovered from the disassembly of
# ehci_hcd_mstar_drv_probe (hcd->ehc_base at struct offset 568).
set -x
sh /data/local/tmp/rung.sh "addr=0xffffff800a226000 len=64" > /data/local/tmp/p3.txt 2>&1
sh /data/local/tmp/rung.sh "addr=0xffffff800a6e2800 len=64" > /data/local/tmp/p4.txt 2>&1
chmod 644 /data/local/tmp/p3.txt /data/local/tmp/p4.txt
echo RUNDONE
