#!/bin/sh
# Build the CMD24 write-probe image.
#
#   LBA=<target lba> ./build-write.sh
#
# The LBA must be a scratch block; the probe itself refuses (E_NOT_EMPTY)
# unless the block reads back uniformly 0x00 or 0xFF, so a wrong LBA cannot
# damage real data.  run-write.sh derives it from the device's partition table.
set -eu
CROSS=${CROSS:-$HOME/Debian/m7642-build/toolchain/gcc13/bin/aarch64-buildroot-linux-gnu-}
D=$(cd "$(dirname "$0")" && pwd)
W=$HOME/Debian/m7642-build/fcie-build
IMG=${IMG:-$HOME/Debian/m7642-build/kernel/linux-main/arch/arm64/boot/Image}
OUT=${OUT:-$HOME/Debian/m7642-build/out}
LBA=${LBA:?set LBA=<scratch block>}
mkdir -p "$W"

CC="${CROSS}gcc -c -O2 -march=armv8-a -mgeneral-regs-only \
    -ffreestanding -fno-builtin -fno-stack-protector -fno-pic \
    -fno-asynchronous-unwind-tables -fno-unwind-tables"
$CC -o "$W/fcie_read.o"  "$D/fcie_read.c"
$CC -o "$W/fcie_write.o" "$D/fcie_write.c"
"${CROSS}gcc" -DLBA="${LBA}" -c -o "$W/emmc_write.o" "$D/emmc_write.S"

"${CROSS}ld" -Ttext=0 -e _start -o "$W/emmc_write.elf" \
	"$W/emmc_write.o" "$W/fcie_write.o" "$W/fcie_read.o"

# No undefined symbols, no runtime relocations: the blob runs with the MMU off
# at a fixed physical address, so either would be fatal.
if "${CROSS}nm" -u "$W/emmc_write.elf" | grep -q ' U '; then
	echo "FAIL: undefined symbols:" >&2
	"${CROSS}nm" -u "$W/emmc_write.elf" >&2
	exit 1
fi
if "${CROSS}readelf" -r "$W/emmc_write.elf" | grep -q 'R_AARCH64'; then
	echo "FAIL: runtime relocations present:" >&2
	"${CROSS}readelf" -r "$W/emmc_write.elf" >&2
	exit 1
fi

# .rodata must travel with .text.  Getting this wrong once already shipped a
# blob whose constant table was read from *outside* the image.
"${CROSS}objcopy" -O binary --only-section=.text --only-section=.rodata \
	"$W/emmc_write.elf" "$W/emmc_write.bin"
"${CROSS}size" "$W/emmc_write.elf"
"${CROSS}readelf" -S "$W/emmc_write.elf" | awk '/\.text|\.rodata/ {print "  section", $2, "size", $6}'
echo "  blob $(stat -c %s "$W/emmc_write.bin") B  md5 $(md5sum "$W/emmc_write.bin" | cut -d' ' -f1)"

python3 "$D/../../tools/host/mk-mainline-abort.py" --image "$IMG" --at 0x4 \
	--stub "$W/emmc_write.bin" --out "$OUT/m7642-rec-73-write.img"
