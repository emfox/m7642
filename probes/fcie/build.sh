#!/bin/sh
# Build both halves of the FCIE probe.
#   $1 = "ko"    -> device module        (only reads registers; safe on live TV)
#   $1 = "bare"  -> freestanding object  (for the checkpoint/bare-metal blob)
#   $1 = "all"
set -e
CROSS=${CROSS:-$HOME/Debian/m7642-build/toolchain/gcc13/bin/aarch64-buildroot-linux-gnu-}
D=$(cd "$(dirname "$0")" && pwd)
W=$HOME/Debian/m7642-build/build/fcie-build
mkdir -p "$W"

bare() {
	"${CROSS}gcc" -c -O2 -march=armv8-a -mgeneral-regs-only \
	    -ffreestanding -fno-builtin -fno-stack-protector -fno-pic \
	    -fno-asynchronous-unwind-tables -fno-unwind-tables \
	    -o "$W/fcie_read.o" "$D/fcie_read.c"
	"${CROSS}gcc" -c -O2 -march=armv8-a -mgeneral-regs-only \
	    -ffreestanding -fno-builtin -fno-stack-protector -fno-pic \
	    -fno-asynchronous-unwind-tables -fno-unwind-tables \
	    -o "$W/fcie_probe.o" "$D/fcie_probe.c"
	"${CROSS}size" "$W/fcie_read.o" "$W/fcie_probe.o"
}

ko() {
	# The vendor tree cannot build modules the normal way (see
	# probes/README.md); build-probe.sh replays probe8's recorded command.
	"$HOME/Debian/m7642-build/scripts/build-probe.sh" fcie >/dev/null
	cp "$HOME/Debian/m7642-build/build/modules/fcie/fcie.ko" "$W/fcie.ko"
	ls -l "$W/fcie.ko"
}

case "$1" in
ko)   ko ;;
bare) bare ;;
all)  bare; ko ;;
*)    echo "usage: $0 ko|bare|all" >&2; exit 1 ;;
esac
