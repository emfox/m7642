#!/system/bin/sh
# Recon for the eMMC host controller: base address, driver symbols, register use.
BB=/vendor/bin/busybox
echo "== /proc/iomem (mmc/emmc/msdc):"
$BB grep -iE "mmc|emmc|msdc|sd" /proc/iomem 2>/dev/null | head -20
echo "== kallsyms matches:"
for pat in msdc mstar_mmc mstar_emmc emmc_ mmc_host mmc_cmd mmc_rsp mmc_data sdhci; do
  n=$($BB grep -c "$pat" /proc/kallsyms 2>/dev/null)
  echo "  $pat: $n"
done
echo "== sample symbols:"
$BB grep -iE "msdc|mstar.*emmc|emmc.*init" /proc/kallsyms 2>/dev/null | head -25
echo "== /sys/block:"
$BB ls /sys/block 2>/dev/null
echo "== mmc host sysfs:"
$BB ls /sys/class/mmc_host 2>/dev/null
for h in $($BB ls /sys/class/mmc_host 2>/dev/null); do
  echo "  $h: $(cat /sys/class/mmc_host/$h/device/uevent 2>/dev/null | head -3 | tr '\n' ' ')"
done
