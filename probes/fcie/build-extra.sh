#!/bin/sh
# Build the two diagnostic images for the code1 eMMC path.
#
#   m7642-rec-73-ctl.img   no eMMC access at all (control: proves that the
#                          code1 record+handover works with this image layout)
#   m7642-rec-73-regs.img  read-only FCIE0/EMMC_PLL dump taken at code1
#
# Usage: build-extra.sh
set -eu
CROSS=${CROSS:-$HOME/Debian/m7642-build/toolchain/gcc13/bin/aarch64-buildroot-linux-gnu-}
D=$(cd "$(dirname "$0")" && pwd)
W=$HOME/Debian/m7642-build/build/fcie-build
IMG=${IMG:-$HOME/Debian/m7642-build/kernel/linux-main/arch/arm64/boot/Image}
OUT=${OUT:-$HOME/Debian/m7642-build/out}
MK="$D/../../tools/host/mk-mainline-abort.py"
mkdir -p "$W"

"${CROSS}gcc" -c -o "$W/emmc_regs.o" "$D/emmc_regs.S"
"${CROSS}gcc" -c -o "$W/emmc_wr1.o" "$D/emmc_wr1.S"
"${CROSS}gcc" -c -o "$W/emmc_clk.o" "$D/emmc_clk.S"
"${CROSS}gcc" -DWTEST=1 -c -o "$W/emmc_wt1.o" "$D/emmc_wrtest.S"
"${CROSS}gcc" -DWTEST=2 -c -o "$W/emmc_wt2.o" "$D/emmc_wrtest.S"
"${CROSS}gcc" -c -o "$W/emmc_wt3.o" "$D/emmc_wt3.S"
"${CROSS}gcc" -c -o "$W/emmc_wt4.o" "$D/emmc_wt4.S"
"${CROSS}gcc" -c -o "$W/emmc_wt5.o" "$D/emmc_wt5.S"
"${CROSS}gcc" -DCPTEST=1 -c -o "$W/emmc_cpa.o" "$D/emmc_cpathA.S"
"${CROSS}gcc" -DCPTEST=2 -c -o "$W/emmc_cpb.o" "$D/emmc_cpathA.S"
"${CROSS}gcc" -c -O2 -march=armv8-a -mgeneral-regs-only -ffreestanding -fno-builtin -fno-stack-protector -fno-pic -fno-asynchronous-unwind-tables -fno-unwind-tables -o "$W/cpathmin.o" "$D/cpathmin.c"
"${CROSS}gcc" -c -o "$W/cpathmin_s.o" "$D/cpathmin.S"
"${CROSS}ld" -Ttext=0 -e _start -o "$W/cpathmin.elf" "$W/cpathmin_s.o" "$W/cpathmin.o"
"${CROSS}objcopy" -O binary --only-section=.text "$W/emmc_regs.o" "$W/emmc_regs.bin"
"${CROSS}objcopy" -O binary --only-section=.text "$W/emmc_wr1.o" "$W/emmc_wr1.bin"
"${CROSS}objcopy" -O binary --only-section=.text "$W/emmc_clk.o" "$W/emmc_clk.bin"
"${CROSS}objcopy" -O binary --only-section=.text "$W/emmc_wt1.o" "$W/emmc_wt1.bin"
"${CROSS}objcopy" -O binary --only-section=.text "$W/emmc_wt2.o" "$W/emmc_wt2.bin"
"${CROSS}objcopy" -O binary --only-section=.text "$W/emmc_wt3.o" "$W/emmc_wt3.bin"
"${CROSS}objcopy" -O binary --only-section=.text "$W/emmc_wt4.o" "$W/emmc_wt4.bin"
"${CROSS}objcopy" -O binary --only-section=.text "$W/emmc_wt5.o" "$W/emmc_wt5.bin"
"${CROSS}objcopy" -O binary --only-section=.text "$W/emmc_cpa.o" "$W/emmc_cpa.bin"
"${CROSS}objcopy" -O binary --only-section=.text "$W/emmc_cpb.o" "$W/emmc_cpb.bin"
echo "-- regs stub: $(wc -c < "$W/emmc_regs.bin") B, relocations:"
"${CROSS}readelf" -r "$W/emmc_regs.o" | grep -E "^[0-9a-f]{16}" || echo "   none"

python3 "$MK" --image "$IMG" --at 0x4 --stub "$W/emmc_regs.bin" \
	--out "$OUT/m7642-rec-73-regs.img"
python3 "$MK" --image "$IMG" --at 0x4 --stub "$W/emmc_wr1.bin" \
	--out "$OUT/m7642-rec-73-wr1.img"
python3 "$MK" --image "$IMG" --at 0x4 --stub "$W/emmc_wt1.bin" \
	--out "$OUT/m7642-rec-73-wt1.img"
"${CROSS}objcopy" -O binary --only-section=.text "$W/cpathmin.elf" "$W/cpathmin.bin"
python3 "$MK" --image "$IMG" --at 0x4 --stub "$W/cpathmin.bin" \
	--out "$OUT/m7642-rec-73-cmin.img"
python3 "$MK" --image "$IMG" --at 0x4 --stub "$W/emmc_cpa.bin" \
	--out "$OUT/m7642-rec-73-cpa.img"
python3 "$MK" --image "$IMG" --at 0x4 --stub "$W/emmc_cpb.bin" \
	--out "$OUT/m7642-rec-73-cpb.img"
python3 "$MK" --image "$IMG" --at 0x4 --stub "$W/emmc_wt2.bin" \
	--out "$OUT/m7642-rec-73-wt2.img"
python3 "$MK" --image "$IMG" --at 0x4 --stub "$W/emmc_wt3.bin" \
	--out "$OUT/m7642-rec-73-wt3.img"
python3 "$MK" --image "$IMG" --at 0x4 --stub "$W/emmc_wt4.bin" \
	--out "$OUT/m7642-rec-73-wt4.img"
python3 "$MK" --image "$IMG" --at 0x4 --stub "$W/emmc_wt5.bin" \
	--out "$OUT/m7642-rec-73-wt5.img"
python3 "$MK" --image "$IMG" --at 0x4 --stub "$W/emmc_clk.bin" \
	--out "$OUT/m7642-rec-73-clk.img"
python3 "$MK" --image "$IMG" --at 0x4 --stub "$D/../handoff/abort-rung.bin" \
	--out "$OUT/m7642-rec-73-ctl.img"
