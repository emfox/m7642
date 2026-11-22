#!/system/bin/sh
BB=/vendor/bin/busybox
echo "-- /proc/kallsyms head:"
$BB head -3 /proc/kallsyms
echo "-- kallsyms lines: $($BB wc -l < /proc/kallsyms)"
echo "-- wdt symbols:"
$BB grep -i wdt /proc/kallsyms | $BB head -20
echo "-- MI_ symbols:"
$BB grep -c ' MI_' /proc/kallsyms
echo "-- modules:"
$BB cat /proc/modules | $BB head -5
