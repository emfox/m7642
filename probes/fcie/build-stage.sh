#!/bin/sh
# Build the C-path diagnostic images.
#
#   m7642-rec-73-cpath.img  stage 9: the full C entry/stack/heartbeat/handover
#                           path but ZERO MMIO access (isolates the C path)
#   m7642-rec-73-setup.img  stage 1: register setup only, no command
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
"${CROSS}gcc" -c -o "$W/emmc_read.o" "$D/emmc_read.S"

for st in 1 9; do
	"${CROSS}gcc" -c -O2 -march=armv8-a -mgeneral-regs-only \
		-ffreestanding -fno-builtin -fno-stack-protector -fno-pic \
		-fno-asynchronous-unwind-tables -fno-unwind-tables \
		-DFCIE_STAGE=$st -o "$W/fcie_read_s$st.o" "$D/fcie_read.c"
	"${CROSS}ld" -Ttext=0 -e _start -o "$W/fcie_boot_s$st.elf" \
		"$W/emmc_read.o" "$W/fcie_probe.o" "$W/fcie_read_s$st.o"
	"${CROSS}objcopy" -O binary --only-section=.text \
		"$W/fcie_boot_s$st.elf" "$W/fcie_boot_s$st.bin"
	"${CROSS}size" "$W/fcie_boot_s$st.elf"
	md5sum "$W/fcie_boot_s$st.bin"
done

python3 "$D/../../tools/host/mk-mainline-abort.py" --image "$IMG" --at 0x4 \
	--stub "$W/fcie_boot_s9.bin" --out "$OUT/m7642-rec-73-cpath.img"
python3 "$D/../../tools/host/mk-mainline-abort.py" --image "$IMG" --at 0x4 \
	--stub "$W/fcie_boot_s1.bin" --out "$OUT/m7642-rec-73-setup.img"
