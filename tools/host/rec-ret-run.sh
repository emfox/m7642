#!/bin/bash
# Arm the recovery slot with the *return* probe (no WDT in recoverycmd) and
# reboot into it.  Every check is made on the host before anything is written,
# and the reboot at the end only happens if all of them pass.
#
# Why this shape: an armed WDT resets the box 10 s after bootm, which destroys
# the pstore export (kmalloc lives in DRAM) before adb can be reached.  The
# only readout window is therefore "no WDT at all".
set -u
ADB=${ADB:-/home/emfox/Debian/tv/adb/platform-tools/adb}
TV=${TV:-192.168.10.60:5555}
IMG=${IMG:-/home/emfox/kbuild/m7642-out/m7642-rec-handoff1-ret.img}
T=/home/emfox/Debian/m7642/tools/host/envtool.py
W=/data/local/tmp
IMG_MD5=3a950d5064b4569f47df1d4337faa2f6
FACTORY=7c2f467bbda49053951c0ce547d11a00

say() { printf '%s\n' "$*"; }
die() { printf 'error: %s\n' "$*" >&2; exit 1; }
dev() { "$ADB" -s "$TV" shell "$@"; }
root() { "$ADB" -s "$TV" exec-out su -c "$1"; }

"$ADB" connect "$TV" >/dev/null 2>&1
st=$(dev getprop sys.boot_completed 2>/dev/null | tr -d '\r')
[ "$st" = "1" ] || die "device not in Android (sys.boot_completed='$st')"
say "device up, uptime $(dev cut -d. -f1 /proc/uptime | tr -d '\r')s"

# --- semantic env check: md5 changes on its own (MstarUpgrade_complete is a
# one-shot flag that mboot consumes), so compare the fields that matter.
root "dd if=/dev/block/mmcblk0 bs=4096 skip=2528 count=32 2>/dev/null" > /tmp/e128.bin
[ "$(stat -c %s /tmp/e128.bin)" = 131072 ] || die "short env read"
head -c 65536 /tmp/e128.bin > /tmp/ep.bin
python3 "$T" verify /tmp/ep.bin >/dev/null || die "env primary CRC invalid"
rc=$(python3 "$T" get /tmp/ep.bin recoverycmd)
say "recoverycmd = $rc"
case "$rc" in
    "mmc erase.p misc; "*"bootm 0x25000000") ;;
    *) die "recoverycmd does not start with erase.p misc / end with bootm" ;;
esac
case "$rc" in *wdt_enable*) die "recoverycmd still arms the WDT -- that is the bug" ;; esac
say "WDT_ENABLE=$(python3 "$T" get /tmp/ep.bin WDT_ENABLE)  MstarUpgrade_complete=$(python3 "$T" get /tmp/ep.bin MstarUpgrade_complete)"

# --- slot must still be factory before we overwrite it
cur=$(root "md5sum /dev/block/by-name/recovery" | tr -d '\r' | cut -d' ' -f1)
say "recovery slot $cur"
[ "$cur" = "$FACTORY" ] || die "slot is not factory; refusing to overwrite blind"

# --- image must be the one we built
[ "$(md5sum "$IMG" | cut -d' ' -f1)" = "$IMG_MD5" ] || die "local image md5 mismatch"
"$ADB" -s "$TV" push "$IMG" "$W/rec-ret.img" >/dev/null || die "push"
got=$(root "md5sum $W/rec-ret.img" | tr -d '\r' | cut -d' ' -f1)
[ "$got" = "$IMG_MD5" ] || die "image on device is $got"

out=$(root "dd if=$W/rec-ret.img of=/dev/block/by-name/recovery bs=4096 2>/dev/null; sync; md5sum /dev/block/by-name/recovery" | tr -d '\r')
say "slot readback $out"
[ "$(printf '%s' "$out" | cut -d' ' -f1)" = "$IMG_MD5" ] || die "slot readback mismatch"
say "bcb $(root 'dd if=/dev/block/by-name/misc bs=1 count=16 2>/dev/null | od -A n -t x1' | tr -d '\r')"

say "=== armed; rebooting into recovery at $(date +%H:%M:%S)"
"$ADB" -s "$TV" reboot recovery
