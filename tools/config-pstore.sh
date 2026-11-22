#!/bin/bash
# Enable pstore/ramoops so the console log survives a crash or reset.
# Compression, pmsg, ftrace and the block backend are all left off: the
# console frontend alone is what covers an early boot failure, and every
# extra frontend is another 256 KB taken away from it.
set -e
KERNEL=${KERNEL:-$HOME/Debian/m7642-build/kernel/linux-main}
TOOLCHAIN=${TOOLCHAIN:-$HOME/Debian/m7642-build/toolchain/gcc13}
cd "$KERNEL"
export PATH="$TOOLCHAIN/bin:/usr/local/bin:/usr/bin:/bin"
export ARCH=arm64
export CROSS_COMPILE=aarch64-buildroot-linux-gnu-
unset -f rm mv cp 2>/dev/null || true

# fs/Kconfig sources fs/pstore/Kconfig inside "if MISC_FILESYSTEMS", so
# without this the PSTORE symbols do not exist at all and olddefconfig
# silently drops whatever we just wrote.
./scripts/config --file .config \
	--enable  MISC_FILESYSTEMS \
	--enable  PSTORE \
	--enable  PSTORE_CONSOLE \
	--enable  PSTORE_RAM \
	--disable PSTORE_COMPRESS \
	--disable PSTORE_PMSG \
	--disable PSTORE_FTRACE \
	--disable PSTORE_BLK

make olddefconfig >/dev/null

echo "--- resulting pstore config ---"
grep -E "^CONFIG_(PSTORE|REED_SOLOMON)" .config || true
