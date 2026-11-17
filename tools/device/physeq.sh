#!/system/bin/sh
# Confirm the PHY init symbols exist, then dump Titania3_series_start_ehc code.
OUT=/data/local/tmp/physeq.txt
KS=/data/local/tmp/ks_phy.txt
grep -iE 'titania|ehci_mstar' /proc/kallsyms > $KS
chmod 644 $KS
rm -f $OUT
sh /data/local/tmp/rung.sh "sym=Titania3_series_start_ehc len=8192" > $OUT 2>&1
chmod 644 $OUT
wc -l < $OUT
echo RUNDONE
