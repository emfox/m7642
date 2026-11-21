#!/bin/bash
# Read back the entry-ladder marker left in the DRAM hole.
#
# The ladder image paints the panel and also leaves three words at 0x43300000,
# so the answer survives even when the panel readout is ambiguous:
#
#   [0] 0x4d373634 "M764"   ladder ran at all
#   [1] step                 1 = reached via code1, 2 = via +0xFA0000
#   [2] ~step                complement, so a stale or half-written word is
#                            not mistaken for a fresh one
#
# Run this after a failed ladder boot, from a normally booted Android.  If the
# words are absent, say so and stop -- an absent marker is a result too.
set -u

ADB=${ADB:-/home/emfox/Debian/tv/adb/platform-tools/adb}
TV=${TV:-192.168.10.60:5555}
ROOT=${ROOT:-/home/emfox/Debian/tv-quiz/device/root.sh}
KO=${KO:-/home/emfox/Debian/m7642/probes/probeRW/probeRW.ko}
W=/data/local/tmp

say() { printf '%s\n' "$*"; }
die() { printf 'error: %s\n' "$*" >&2; exit 1; }

"$ADB" connect "$TV" >/dev/null 2>&1
state=$("$ADB" -s "$TV" shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')
[ "$state" = 1 ] || die "device not booted (sys.boot_completed='$state'); power-cycle it and retry"

"$ADB" -s "$TV" push "$KO" "$W/probeRW.ko" >/dev/null || die "push failed"

# Fresh output file every run: the module truncates on open, but a stale file
# from an earlier run must never be mistaken for this one.
# rmmod first: probeRW does nothing at insmod (its module_init returns 0 and the
# real work is in module_exit), so a leftover module from a previous run would
# swallow the insmod with EEXIST and print nothing.  Then insmod with the args,
# then rmmod again -- that second unload is what actually does the read.
ADB="$ADB" TV_HOST="$TV" "$ROOT" -t "rm -f $W/probeRW.out; rmmod probeRW 2>/dev/null; insmod $W/probeRW.ko addr=0x43300000 len=16 op=r; rmmod probeRW" \
    >/dev/null 2>&1

# su, not a plain shell: the module creates the file 0600 root:root.
dump=$("$ADB" -s "$TV" shell "su -c 'cat $W/probeRW.out'" 2>/dev/null | tr -d '\r')
[ -n "$dump" ] || die "no output from probeRW -- module did not load"

say "$dump"

# Decode the three words out of the hexdump.  probeRW prints 16 bytes per line
# as "0000000043300000: 34 36 37 4d ...".
words=$(printf '%s\n' "$dump" | sed -n 's/^[0-9a-f]\{16\}: *//p' \
        | tr -s ' ' '\n' | grep -E '^[0-9a-f]{2}$' | head -12)
[ -n "$words" ] || die "could not parse the hexdump"

v() { printf '%s\n' "$words" | sed -n "$1,$2p" | tac | tr -d '\n'; }

m0=$(v 1 4); m1=$(v 5 8); m2=$(v 9 12)
say ""
say "word0 0x$m0  word1 0x$m1  word2 0x$m2"

if [ "$m0" != "4d373634" ]; then
    say "VERDICT: marker absent -- inconclusive, not a negative."
    say "  If the device sat in standby before this boot, DDR may not have held"
    say "  the word.  The panel colour, read while the ladder boot is still"
    say "  hung, is the authoritative answer; this word only confirms it."
    exit 0
fi

step=$(printf '%d' "0x$m1")
comp=$(printf '%d' "0x$m2")
if [ $(( step ^ comp )) -ne 4294967295 ]; then
    say "VERDICT: marker present but the complement does not match -- treat with suspicion."
else
    case "$step" in
    1) say "VERDICT: the bootloader entered the image through code1 (blue rung)." ;;
    2) say "VERDICT: the bootloader entered the image at +0xFA0000 (yellow rung)." ;;
    *) say "VERDICT: unexpected step $step." ;;
    esac
fi
say ""
say "Next: whether primary_entry ran is read from the panel colour:"
say "  blue/yellow as above  -> kernel never reached primary_entry"
say "  white                 -> primary_entry reached"
say "  red                   -> record_mmu_state returned"
say "  green                 -> preserve_boot_args returned"
