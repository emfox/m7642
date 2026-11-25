#!/bin/bash
# Build the m7642 kernel Image.
#
# IMPORTANT: arch/arm64/boot/Image must stay a BARE arm64 Image (starts with
# "MZ").  tools/host/mk-mainline-abort.py takes the bare kernel via --image and
# supplies the ANDROID! container header itself (from its --src template).
# Wrapping the Image here would make it a container-in-a-container and mboot
# would execute the inner header as code -- every probe image then hangs in
# head.S with no record.  Cost: a whole evening (2026-11-25).
#
#   mkimage.sh [<out-tree>]
set -eu
cd "$(dirname "$0")"
K=${KERNEL:-$HOME/Debian/m7642-build/kernel}
O=${1:-$K/linux-735-ir}
SRC=$K/linux-git
export PATH=$HOME/Debian/m7642-build/toolchain/gcc13/bin:$PATH
make -C "$SRC" O="$O" ARCH=arm64 CROSS_COMPILE=aarch64-buildroot-linux-gnu- -j"$(nproc)" dtbs Image
python3 - "$O" <<'PY'
import sys, os
O = sys.argv[1]
d = open(os.path.join(O, "arch/arm64/boot/Image"), "rb").read(4)
assert d[:2] == b"MZ", "Image is not a bare arm64 Image (did something wrap it?)"
print("mkimage: bare arm64 Image ok (%d bytes)" % os.path.getsize(os.path.join(O,"arch/arm64/boot/Image")))
PY
