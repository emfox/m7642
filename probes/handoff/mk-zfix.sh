#!/bin/bash
# Checkpoints WITH the 2 MB-alignment correction forced to zero.
#
# Root cause (2026-11-22 14:0x): __pi_early_map_kernel computes the relocation
# offset as `adrp _text & 0x1fffff`.  With the MMU off `adrp` yields the
# PHYSICAL address, so a kernel loaded at 0x20280000 (not 2 MB aligned) gets
# 0x80000, and every relocated pointer shifts by 512 KB -- `br x8` then lands
# at 0xffffffc0804e805c (data) instead of __primary_switched.  arm64 wants the
# Image at a 2 MB aligned base; mboot insists on 0x20280000.
#
# Measured: with 0x465a1c forced to `mov x25, xzr`, the recorded x8 becomes
# 0xffffffc08046805c, i.e. correct.
#
#   mk-zfix.sh <image-offset> <tag> [pa|kva] [extra patcher args...]
set -eu
cd "$(dirname "$0")"
IMAGE=${IMAGE:-$HOME/Debian/m7642-build/kernel/linux-main/arch/arm64/boot/Image}
OUT=${OUT:-$HOME/Debian/m7642-build/out}
OFF=$1; TAG=$2; ENTRY=${3:-kva}; shift 3 2>/dev/null || true
case "$ENTRY" in
kva) TGT=0x36c004 ;;   # tramp's kernel-VA entry
pa)  TGT=0x36c000 ;;   # tramp's physical entry
esac

KADDR=0x20280000 ./build-postmmu.sh >/dev/null
python3 ../../tools/host/mk-mainline-abort.py \
	--image "$IMAGE" \
	--word "0x465a1c=0xaa1f03f9" \
	--patch "0x4=0x36c0c0" --patch "$OFF=$TGT" \
	--stub abort-postmmu.bin --tramp tramp-postmmu.bin --tramp-at 0x36c000 \
	--nop 0x46804c \
	--out "$OUT/m7642-rec-73-$TAG.img"
