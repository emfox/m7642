#!/bin/sh
# Build the two ladder rungs.  COLOUR/STEP come from the preprocessor, so a
# 32-bit COLOUR fails at compile time instead of on the panel.
set -e
cd "$(dirname "$0")"
PATH="$PATH:$HOME/kbuild/toolchain-gcc13/bin"
CC=aarch64-buildroot-linux-gnu-gcc
OC=aarch64-buildroot-linux-gnu-objcopy

cp -f blue.bin blue.bin.old 2>/dev/null || true
cp -f yellow.bin yellow.bin.old 2>/dev/null || true

# HALT=1 builds the rung that stops after the fill instead of branching to
# primary_entry; SUFFIX names the outputs so the two builds can coexist.
HALT=${HALT:-0}
FREEZE=${FREEZE:-1}
# HOLD=n keeps the fill on screen for n seconds before returning.  Used on
# the boot slot, where freezing would leave boot broken and there is no WDT.
HOLD=${HOLD:-0}
SUFFIX=${SUFFIX:-}

# COLOUR=0xcccc for the code1 rung on purpose: it is a scanout-format sentinel,
# not just an "I am here" colour.
#
# The rung paints c | (c<<16), so under ARGB8888 that 32-bit word splits into
# A = G = high byte of c and R = B = low byte.  A neutral grey is therefore
# impossible under ARGB except when the two bytes of c are equal -- c = 0xNNNN.
# For those values ARGB shows A=R=G=B=NN (byte order does not matter, all four
# bytes are identical), while RGB565 still shows a saturated colour.  So one
# colour answers two questions at once:
#
#   0xcccc  RGB565    (206,154,99)   warm ochre  -> format is RGB565, trust the rest
#   0xcccc  ARGB8888 (204,204,204)   light grey  -> format is ARGB8888, every later
#                                                  checkpoint colour is unreliable
#
# The previous 0xffff was immune to both formats, which looked safer but hid the
# format problem: white is white either way, so seeing white did not prove the
# control word had been programmed.  The old 0x001f was worse still -- A=0 under
# ARGB, i.e. "nothing was painted".
#
# Caveat, recorded so it is not forgotten: this sentinel is overwritten as soon
# as primary_entry paints its first checkpoint.  It is readable only when the
# kernel dies between the rung and that first checkpoint.  Past that point the
# format is inferred from whether a later colour came out right, e.g. green
# 0x07e0 showing as magenta means ARGB.
#
# STEP=0 removes the black bars entirely.  The only known source of the shredded
# pattern is the bars being broken up by the panel's tiled layout (2026-11-18:
# a 100x32 white bar came out as pink-white vertical crumbs).  Without bars the
# panel can only show a flat colour or something we did not paint.
$CC -c -DCOLOUR=0xcccc -DSTEP=0 -DHALT=$HALT -DFREEZE=$FREEZE -DHOLD=$HOLD -o blue.o ladder.S
$OC -O binary -j .text blue.o "blue$SUFFIX.bin"
$CC -c -DCOLOUR=0xffe0 -DSTEP=0 -DHALT=$HALT -DFREEZE=$FREEZE -DHOLD=$HOLD -o yellow.o ladder.S
$OC -O binary -j .text yellow.o "yellow$SUFFIX.bin"

ls -l "blue$SUFFIX.bin" "yellow$SUFFIX.bin"
sz=$(wc -c < "yellow$SUFFIX.bin")
[ "$sz" -le $((0xFA0000 - 0xF9FE00)) ] ||
    { echo "yellow rung $sz bytes overflows into the vendor entry at 0xFA0000"; exit 1; }
echo "yellow rung $sz bytes, limit 0x200 (0xFA0000 - 0xF9FE00)"
