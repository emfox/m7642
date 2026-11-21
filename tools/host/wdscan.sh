#!/system/bin/sh
BB=/vendor/bin/busybox
echo "== dev nodes:"; $BB ls /dev | $BB grep -i -E "wdt|watchdog|wdog"
echo "== processes:"; $BB ps | $BB grep -i -E "wdt|watchdog" | $BB grep -v grep
echo "== binaries mentioning watchdog:"; $BB grep -rl watchdog /vendor/bin /system/bin 2>/dev/null | $BB head -5
echo "== props:"; getprop | $BB grep -i wdt
echo "== dmesg wdt:"; dmesg | $BB grep -i -E "wdt|watchdog" | $BB tail -6
