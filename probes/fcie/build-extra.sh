#!/bin/sh
# Build the two diagnostic images for the code1 eMMC path.
#
#   m7642-rec-73-ctl.img   no eMMC access at all (control: proves that the
#                          code1 record+handover works with this image layout)
#   m7642-rec-73-regs.img  read-only FCIE0/EMMC_PLL dump taken at code1
#
# Usage: build-extra.sh
set -eu
CROSS=${CROSS:-$HOME/kbuild/toolchain-gcc13/bin/aarch64-buildroot-linux-gnu-}
D=$(cd "$(dirname "$0")" && pwd)
W=$HOME/kbuild/fcie-build
IMG=${IMG:-$HOME/kbuild/linux-main/arch/arm64/boot/Image}
OUT=${OUT:-$HOME/kbuild/m7642-out}
MK="$D/../../tools/host/mk-mainline-abort.py"
mkdir -p "$W"

"${CROSS}gcc" -c -o "$W/emmc_regs.o" "$D/emmc_regs.S"
"${CROSS}objcopy" -O binary --only-section=.text "$W/emmc_regs.o" "$W/emmc_regs.bin"
echo "-- regs stub: $(wc -c < "$W/emmc_regs.bin") B, relocations:"
"${CROSS}readelf" -r "$W/emmc_regs.o" | grep -E "^[0-9a-f]{16}" || echo "   none"

python3 "$MK" --image "$IMG" --at 0x4 --stub "$W/emmc_regs.bin" \
	--out "$OUT/m7642-rec-73-regs.img"
python3 "$MK" --image "$IMG" --at 0x4 --stub "$D/../handoff/abort-rung.bin" \
	--out "$OUT/m7642-rec-73-ctl.img"
