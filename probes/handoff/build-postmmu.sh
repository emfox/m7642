#!/bin/bash
# Build the post-MMU abort blobs.  Usage: build-postmmu.sh
#
# The tramp hard-codes the physical addresses of boot_args, _stext and _end,
# plus PRIMARY_ENTRY_PA, so they are derived from System.map.  Re-run this
# after every kernel rebuild.
set -eu
cd "$(dirname "$0")"
TC=${TC:-/home/emfox/Debian/m7642-build/toolchain/gcc13/bin}
KERNEL=${KERNEL:-/home/emfox/Debian/m7642-build/kernel/linux-main}
SYSMAP=${SYSMAP:-$KERNEL/System.map}
KADDR=${KADDR:-0x20280000}
export PATH="$TC:$PATH"

DEFS=$(python3 - "$SYSMAP" "$KADDR" <<'PY'
import sys
syms = {}
for line in open(sys.argv[1]):
    p = line.split()
    if len(p) >= 3:
        syms[p[2]] = int(p[0], 16)
text = syms["_text"]
kaddr = int(sys.argv[2], 16)
pa = lambda n: kaddr + syms[n] - text
print("-DBOOT_ARGS_PA=%#x -DIMAGE_START_PA=%#x -DIMAGE_END_PA=%#x "
      "-DKIMAGE_OFFSET=%#x -DPRIMARY_ENTRY_PA=%#x" %
      (pa("boot_args"), pa("_stext"), pa("_end"),
       text - kaddr, pa("primary_entry")))
PY
)
echo "defs: $DEFS"
aarch64-buildroot-linux-gnu-gcc $DEFS -c tramp-postmmu.S -o tramp-postmmu.o
aarch64-buildroot-linux-gnu-gcc -c abort-postmmu.S -o abort-postmmu.o
# abort-rung.bin is the plain record+handover stub the fcie build scripts
# patch in for the ctl/paint images; it needs no kernel constants.
aarch64-buildroot-linux-gnu-gcc -c abort-rung.S -o abort-rung.o
for f in tramp-postmmu abort-postmmu abort-rung; do
	aarch64-buildroot-linux-gnu-objcopy -O binary --only-section=.text "$f.o" "$f.bin"
done
ls -l tramp-postmmu.bin abort-postmmu.bin abort-rung.bin
md5sum tramp-postmmu.bin abort-postmmu.bin abort-rung.bin
