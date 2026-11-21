#!/bin/bash
# Read the record an early-boot probe left in the pstore pmsg zone.
#
# The probe runs before the kernel proper, writes a persistent_ram record into
# 0x419c0000 and branches back to the factory entry.  ramoops_init_prz() then
# sees a valid signature, copies the record into kmalloc (save_old) and zaps
# the ring, so the payload only ever appears as /sys/fs/pstore/pmsg-ramoops-0.
#
#   console-ramoops present but pmsg-ramoops-0 absent -> the probe did not run,
#   or it ran but the record was not accepted (signature/size wrong).
#
# The file is 0400 root:log, hence su.
set -u

ADB=${ADB:-/home/emfox/Debian/tv/adb/platform-tools/adb}
TV=${TV:-192.168.10.60:5555}
NAME=${NAME:-pmsg-ramoops-0}

say() { printf '%s\n' "$*"; }

"$ADB" connect "$TV" >/dev/null 2>&1
[ "$("$ADB" -s "$TV" shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')" = 1 ] ||
    { echo "device not booted" >&2; exit 1; }

say "== /sys/fs/pstore/"
"$ADB" -s "$TV" shell 'su -c "ls -l /sys/fs/pstore/"' 2>/dev/null | tr -d '\r'

say ""
say "== $NAME (hex)"
"$ADB" -s "$TV" shell "su -c 'od -A d -t x1 /sys/fs/pstore/$NAME 2>&1'" 2>/dev/null | tr -d '\r'

say ""
say "== $NAME (64-bit words)"
"$ADB" -s "$TV" shell "su -c 'od -A d -t x8 /sys/fs/pstore/$NAME 2>&1'" 2>/dev/null | tr -d '\r'

say ""
say "== pmsg zone as it is now (start/size should be 0: PRZ_FLAG_ZAP_OLD)"
"$ADB" -s "$TV" push "${KO:-/home/emfox/Debian/m7642/probes/probeRW/probeRW.ko}" /data/local/tmp/probeRW.ko >/dev/null 2>&1
"$ADB" -s "$TV" shell "su -c 'rm -f /data/local/tmp/probeRW.out; rmmod probeRW 2>/dev/null; insmod /data/local/tmp/probeRW.ko addr=0x419c0000 len=32 op=r; rmmod probeRW'" >/dev/null 2>&1
"$ADB" -s "$TV" shell 'su -c "cat /data/local/tmp/probeRW.out"' 2>/dev/null | tr -d '\r'
