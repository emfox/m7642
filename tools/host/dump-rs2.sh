#!/system/bin/sh
BB=/vendor/bin/busybox
: > /data/local/tmp/dump-addr.txt
for s in machine_restart MDrv_SYS_ResetAeon mstar_pm_power_off mstar_pm_enter mstar_pm_regw MDrv_SYS_Reset; do
  rmmod wdtdump 2>/dev/null
  $BB insmod /data/local/tmp/wdtdump.ko sym=$s len=384 >/dev/null 2>&1
  rmmod wdtdump 2>/dev/null
  if [ -f /data/local/tmp/wdtdump.bin ]; then
    $BB cp /data/local/tmp/wdtdump.bin /data/local/tmp/dump_$s.bin
    $BB rm -f /data/local/tmp/wdtdump.bin
  fi
  dmesg | $BB grep "wdtdump: $s at" | $BB tail -1 >> /data/local/tmp/dump-addr.txt
done
$BB ls -l /data/local/tmp/dump_*.bin
