#!/bin/bash
# ident.sh -- print the seven identity registers that abort-postmmu.S v3 records
# (MIDR/CTR/REVIDR/TCR/MAIR/ID_AA64MMFR0/MPIDR), for several machine+CPU pairs.
# Same instructions, same order, MMU off -- no tramp involved.  TCR/MAIR are 0
# here because nothing configured them; in the chain run they hold the kernel's
# values instead.
set -eu
CD=$(cd "$(dirname "$0")" && pwd); cd "$CD"
TC=${TC:-/home/emfox/Debian/m7642-build/toolchain/gcc13/bin}
QEMU=${QEMU:-qemu-system-aarch64}
CC=$TC/aarch64-buildroot-linux-gnu-gcc
LD=$TC/aarch64-buildroot-linux-gnu-ld
mkdir -p gen
echo "machine        cpu          : values"
for cfg in "virt cortex-a72 0x40080000" "virt cortex-a53 0x40080000" \
           "xlnx-zcu102 cortex-a53 0x20000000" "xlnx-zcu102 cortex-a72 0x20000000"; do
    set -- $cfg
    "$CC" -I. -I src -c src/mrs-collect.S -o gen/mc.o
    "$LD" -Ttext=$3 -e _start gen/mc.o -o gen/mc.elf
    printf '%-14s %-12s : ' "$1" "$2"
    timeout 15 "$QEMU" -display none -audio none -nographic \
        -semihosting-config enable=on,target=native -M "$1" -cpu "$2" -m 1G \
        -kernel gen/mc.elf </dev/null 2>&1 | tr -d '\000' | tr '\n' ' ' | sed 's/  */ /g'
    echo
done
