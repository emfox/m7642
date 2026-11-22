#!/bin/bash
# Build the in-function checkpoints of __pi_early_map_kernel.
#
# emap (its entry, 0x4659e0) returns, prsw (__primary_switched) does not, so the
# kernel dies inside this function.  Landmarks are the call sites (all run at
# PA, so the tramp's _start entry applies), patched with `bl tramp`:
#
#   mk1 0x465a94  bl __memset                 (after map_fdt + dsb)
#   mk2 0x465ab8  bl __pi_init_feature_override (after fdt_path_offset)
#   mk3 0x465c14  bl idmap_cpu_replace_ttbr1   (after the 6 map_segment calls)
#   mk4 0x465c1c  bl __pi_relocate_kernel      (after the first TTBR1 switch)
#   mk5 0x465ca4  bl idmap_cpu_replace_ttbr1   (after memcpy)
#   mk6 0x465cbc  ldp x27, x28                 (epilogue, about to return)
set -eu
cd "$(dirname "$0")"
KERNEL=${KERNEL:-/home/emfox/kbuild/linux-main}
IMAGE=${IMAGE:-$KERNEL/arch/arm64/boot/Image}
OUT=${OUT:-/home/emfox/kbuild/m7642-out}
MK=../../tools/host/mk-mainline-abort.py
TRAMP_AT=0x36c000
FDT_SHIM=$((TRAMP_AT + 0xc0))

for spec in "0x465a94 mk1" "0x465ab8 mk2" "0x465c14 mk3" \
	    "0x465c1c mk4" "0x465ca4 mk5" "0x465cbc mk6"; do
	set -- $spec
	python3 "$MK" --image "$IMAGE" \
		--patch "0x4=$FDT_SHIM" --patch "$1=$TRAMP_AT" \
		--stub abort-postmmu.bin --tramp tramp-postmmu.bin --tramp-at $TRAMP_AT \
		--nop 0x46804c \
		--out "$OUT/m7642-rec-73-$2.img"
done
