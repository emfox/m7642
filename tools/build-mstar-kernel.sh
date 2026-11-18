#!/bin/bash
# Full kernel build, to prove mstar-mci links and does not add undefined symbols.
set -e
KERNEL=${KERNEL:-$HOME/kbuild/linux-main}
TOOLCHAIN=${TOOLCHAIN:-$HOME/kbuild/toolchain-gcc13}
cd "$KERNEL"
export PATH="$TOOLCHAIN/bin:/usr/local/bin:/usr/bin:/bin"
export ARCH=arm64
export CROSS_COMPILE=aarch64-buildroot-linux-gnu-
unset -f rm mv cp 2>/dev/null || true
exec make -j"$(nproc)" "$@"
