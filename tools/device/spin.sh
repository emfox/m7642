#!/system/bin/sh
# Dump the MStar CPU bring-up ops (protocol unknown, source missing from the GPL drop).
for f in boot_cpu prepare_cpu init_cpu; do
	sh /data/local/tmp/rung.sh "sym=mstar_smp_spin_table_$f len=1024" > /data/local/tmp/spin_$f.txt 2>&1
	cp /data/local/tmp/probeG.out /data/local/tmp/spin_$f.dump 2>/dev/null
done
chmod 644 /data/local/tmp/spin_*.dump /data/local/tmp/spin_*.txt
wc -l /data/local/tmp/spin_boot_cpu.dump
echo RUNDONE
