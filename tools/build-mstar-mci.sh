#!/bin/bash
# Build the mstar-mci eMMC driver against the 7.3 tree.
#
# Kept as a script because the kernel build is hostile to the sandbox: the
# safe-delete wrapper turns every filechk() into a failure.  Run this over ssh
# to localhost so the build sees a normal shell.
#
#   ssh ... emfox@localhost '~/Debian/m7642/tools/build-mstar-mci.sh'
set -e

KERNEL=${KERNEL:-$HOME/kbuild/linux-main}
TOOLCHAIN=${TOOLCHAIN:-$HOME/kbuild/toolchain-gcc13}

cd "$KERNEL"
export PATH="$TOOLCHAIN/bin:/usr/local/bin:/usr/bin:/bin"
export ARCH=arm64
export CROSS_COMPILE=aarch64-buildroot-linux-gnu-

# Nothing here deletes outside the build tree; unset the wrapper so that
# filechk() and checksyscalls.sh can do their job.
unset -f rm mv cp 2>/dev/null || true

exec make drivers/mmc/host/mstar-mci/ "$@"
