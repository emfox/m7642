#!/bin/sh
# Build the stage-1 diagnostic image: FCIE register setup only.
#
# No command is issued: no SD_MODE/FIFO write, no SD_CTRL, no DMA job.  If this
# returns (Android boots) the register writes are safe at code1 and a later
# hang in the full probe is in the command/DMA half.
#
# Usage: build-stage.sh
set -eu
CROSS=${CROSS:-$HOME/kbuild/toolchain-gcc13/bin/aarch64-buildroot-linux-gnu-}
D=$(cd "$(dirname "$0")" && pwd)
W=$HOME/kbuild/fcie-build
IMG=${IMG:-$HOME/kbuild/linux-main/arch/arm64/boot/Image}
OUT=${OUT:-$HOME/kbuild/m7642-out}
mkdir -p "$W"

"$D/build.sh" bare
"${CROSS}gcc" -c -O2 -march=armv8-a -mgeneral-regs-only \
	-ffreestanding -fno-builtin -fno-stack-protector -fno-pic \
	-fno-asynchronous-unwind-tables -fno-unwind-tables \
	-DFCIE_STAGE=1 -o "$W/fcie_read_s1.o" "$D/fcie_read.c"
"${CROSS}ld" -Ttext=0 -e _start -o "$W/fcie_boot_s1.elf" \
	"$W/emmc_read.o" "$W/fcie_probe.o" "$W/fcie_read_s1.o"
"${CROSS}objcopy" -O binary --only-section=.text "$W/fcie_boot_s1.elf" "$W/fcie_boot_s1.bin"
"${CROSS}size" "$W/fcie_boot_s1.elf"
md5sum "$W/fcie_boot_s1.bin"

python3 "$D/../../tools/host/mk-mainline-abort.py" --image "$IMG" --at 0x4 \
	--stub "$W/fcie_boot_s1.bin" --out "$OUT/m7642-rec-73-setup.img"
