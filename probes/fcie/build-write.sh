#!/bin/sh
# Build the CMD24 write-probe image.
#
#   LBA=<target lba> ./build-write.sh
#
# The LBA must be a scratch block: the probe refuses unless the block reads back
# uniformly 0x00 or 0xFF.  The runner derives it from the device's partition
# table; see run-write.sh.
set -eu
CROSS=${CROSS:-$HOME/Debian/m7642-build/toolchain/gcc13/bin/aarch64-buildroot-linux-gnu-}
D=$(cd "$(dirname "$0")" && pwd)
W=$HOME/Debian/m7642-build/fcie-build
IMG=${IMG:-$HOME/Debian/m7642-build/kernel/linux-main/arch/arm64/boot/Image}
OUT=${OUT:-$HOME/Debian/m7642-build/out}
LBA=${LBA:?set LBA=<scratch block>}
mkdir -p "$W"

"${CROSS}gcc" -c -O2 -march=armv8-a -mgeneral-regs-only \
    -ffreestanding -fno-builtin -fno-stack-protector -fno-pic \
    -fno-asynchronous-unwind-tables -fno-unwind-tables \
    -o "$W/fcie_read.o" "$D/fcie_read.c"
"${CROSS}gcc" -c -O2 -march=armv8-a -mgeneral-regs-only \
    -ffreestanding -fno-builtin -fno-stack-protector -fno-pic \
    -fno-asynchronous-unwind-tables -fno-unwind-tables \
    -o "$W/fcie_write.o" "$D/fcie_write.c"
"${CROSS}gcc" -DLBA=$LBA -c -o "$W/emmc_write.o" "$D/emmc_write.S"
"${CROSS}ld" -Ttext=0 -e _start -o "$W/emmc_write.elf" \
	"$W/emmc_write.o" "$W/fcie_write.o" "$W/fcie_read.o"
"${CROSS}objcopy" -O binary --only-section=.text "$W/emmc_write.elf" "$W/emmc_write.bin"
"${CROSS}size" "$W/emmc_write.elf"
md5sum "$W/emmc_write.bin"

python3 "$D/../../tools/host/mk-mainline-abort.py" --image "$IMG" --at 0x4 \
	--stub "$W/emmc_write.bin" --out "$OUT/m7642-rec-73-write.img"
