#!/bin/sh
# Build the boot-path CMD17 probe image.
#
# The pre-MMU code1 shim (emmc_read.S) and the freestanding FCIE reader are
# linked into one blob, which mk-mainline-abort.py appends after the kernel and
# branches to from code1.  The blob must stay OUTSIDE the factory-kernel copy
# region (0x20280000..0x21554a00); the builder puts it at Image+0x1400000.
#
# Usage: build-boot.sh [out.img]
set -eu
CROSS=${CROSS:-$HOME/Debian/m7642-build/toolchain/gcc13/bin/aarch64-buildroot-linux-gnu-}
D=$(cd "$(dirname "$0")" && pwd)
W=$HOME/Debian/m7642-build/build/fcie-build
IMG=${IMG:-$HOME/Debian/m7642-build/kernel/linux-main/arch/arm64/boot/Image}
OUT=${1:-$HOME/Debian/m7642-build/out/m7642-rec-73-emmc.img}
mkdir -p "$W"

"$D/build.sh" bare

"${CROSS}gcc" -c -o "$W/emmc_read.o" "$D/emmc_read.S"
"${CROSS}ld" -Ttext=0 -e _start -o "$W/fcie_boot.elf" \
	"$W/emmc_read.o" "$W/fcie_probe.o" "$W/fcie_read.o"
"${CROSS}objcopy" -O binary --only-section=.text "$W/fcie_boot.elf" "$W/fcie_boot.bin"
"${CROSS}size" "$W/fcie_boot.elf"
echo "-- layout (symbols):"
"${CROSS}nm" -n "$W/fcie_boot.elf" | grep -E " (_start|fcie_probe_once|fcie_read_block)$"
echo "-- undefined symbols (must be none):"
"${CROSS}nm" -u "$W/fcie_boot.elf" || true
echo "-- relocations (must be none):"
"${CROSS}readelf" -r "$W/fcie_boot.elf" | grep -E "^[0-9a-f]{16}" || true
md5sum "$W/fcie_boot.bin"

python3 "$D/../../tools/host/mk-mainline-abort.py" --image "$IMG" --at 0x4 \
	--stub "$W/fcie_boot.bin" --out "$OUT"
