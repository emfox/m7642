#!/bin/bash
ADB=/home/emfox/Debian/tv/adb/platform-tools/adb
TV=192.168.10.60:5555
mkdir -p hal/dump
for sym in machine_restart MDrv_SYS_ResetAeon mstar_pm_power_off mstar_pm_enter mstar_pm_regw; do
  $ADB connect $TV >/dev/null 2>&1
  $ADB -s $TV exec-out su -c "rmmod wdtdump 2>/dev/null; /vendor/bin/busybox insmod /data/local/tmp/wdtdump.ko sym=$sym len=512; rmmod wdtdump; /vendor/bin/busybox cat /data/local/tmp/wdtdump.bin; echo; dmesg | /vendor/bin/busybox grep 'wdtdump:' | /vendor/bin/busybox tail -2" > "hal/dump/rs_$sym.mix" 2>/dev/null
  sz=$(stat -c %s "hal/dump/rs_$sym.mix")
  echo "$sym mix=$sz"
done
