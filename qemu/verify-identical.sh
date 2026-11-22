#!/bin/bash
# verify-identical.sh -- prove that the bench's copy of the tramp is the real thing
#
# bench copy : src/tramp-qemu.S   (adds two #ifndef'd addresses + INJECT_*
#                                  variants, nothing else)
# original   : ../probes/handoff/tramp-postmmu.S  (read-only, never touched)
#
# Both are assembled twice: with the stock defaults (which ARE the production
# values, see gen.py) and with the -D values derived from the kernel System.map
# exactly like probes/handoff/build-postmmu.sh derives them.  In both cases the
# resulting .text blob must be byte-identical to the committed
# probes/handoff/tramp-postmmu.bin.
set -eu
CD=$(cd "$(dirname "$0")" && pwd)
cd "$CD"
TC=${TC:-/home/emfox/Debian/m7642-build/toolchain/gcc13/bin}
CC=$TC/aarch64-buildroot-linux-gnu-gcc
OC=$TC/aarch64-buildroot-linux-gnu-objcopy
# inside the repo the original is ../probes/handoff, in a scratch copy fall
# back to the repo path so this script works from either place
if [ -z "${REPO:-}" ]; then
    if [ -d ../probes/handoff ]; then REPO=..; else REPO=/home/emfox/Debian/m7642; fi
fi
# v1: the source the bench's parameterised copy was derived from (22:02).  The
# repo file has since been rewritten (v2), so the pinned copy is what we compare
# against; it also matches the blob that was committed at that time.
ORIG=src/tramp-v1-pinned.S
BIN=$REPO/probes/handoff/tramp-postmmu.bin
V2SRC=src/tramp-v2.S
STUB=src/abort-stub-v3.S
V4SRC=src/tramp-v4.S
V5SRC=src/tramp-v5.S
STUBBIN=$REPO/probes/handoff/abort-postmmu.bin
SYSMAP=${SYSMAP:-/home/emfox/Debian/m7642-build/kernel/linux-main/System.map}
KADDR=${KADDR:-0x20280000}
WORK=gen/ident
mkdir -p "$WORK"

build() { # $1 source, $2 out name, rest: extra -D
    src=$1; out=$2; shift 2
    "$CC" "$@" -c "$src" -o "$WORK/$out.o"
    "$OC" -O binary --only-section=.text "$WORK/$out.o" "$WORK/$out.bin"
    md5sum "$WORK/$out.bin" | awk '{print "  " $1 "  " $2}'
}

echo "== 1. defaults (== the production constants) =="
echo "original:"; build "$ORIG" orig-default
echo "bench copy:"; build src/tramp-qemu.S bench-default

if [ -f "$SYSMAP" ]; then
    DEFS=$(python3 - "$SYSMAP" "$KADDR" <<'PY'
import sys
syms = {}
for line in open(sys.argv[1]):
    p = line.split()
    if len(p) >= 3:
        syms[p[2]] = int(p[0], 16)
text = syms["_text"]; kaddr = int(sys.argv[2], 16)
pa = lambda n: kaddr + syms[n] - text
print("-DBOOT_ARGS_PA=%#x -DIMAGE_START_PA=%#x -DIMAGE_END_PA=%#x "
      "-DKIMAGE_OFFSET=%#x -DPRIMARY_ENTRY_PA=%#x -DMEMSTART_VA=%#x" %
      (pa("boot_args"), pa("_stext"), pa("_end"), text - kaddr,
       pa("primary_entry"), syms["memstart_addr"]))
PY
)
    echo
    echo "== 2. System.map-derived constants (what build-postmmu.sh does) =="
    echo "defs: $DEFS"
    echo "original:"; build "$ORIG" orig-real $DEFS
    echo "bench copy:"; build src/tramp-qemu.S bench-real $DEFS
fi

echo
echo "== 3. committed production blob =="
md5sum "$BIN"

echo
echo "== 4. handover stub (v3) with its #ifndef defaults =="
if [ -f "$STUB" ]; then
    build "$STUB" stub-copy
    md5sum "$STUBBIN"
fi

echo
echo "== 5. v4 copy (world split) vs the blob committed right now =="
if [ -f "$V4SRC" ]; then
    build "$V4SRC" v4-copy
    md5sum "$BIN"
fi

echo
echo "== 6. v5 copy (entry offsets from tramp-entries.env) vs the repo blob =="
if [ -f "$V5SRC" ]; then
    build "$V5SRC" v5-copy
    md5sum "$BIN"
fi

echo
echo "== 7. bench v2 copy vs the blob committed right now =="
if [ -f "$V2SRC" ]; then
    build "$V2SRC" v2-copy
    md5sum "$BIN"
fi

echo
st=$(md5sum "$WORK/orig-default.bin" | cut -d' ' -f1)
sb=$(md5sum "$WORK/bench-default.bin" | cut -d' ' -f1)
sp=$(md5sum "$BIN" | cut -d' ' -f1)
if [ "$st" = "$sb" ]; then
    echo "OK: bench copy of v1 builds to exactly the pinned v1 source"
else
    echo "MISMATCH: bench v1 copy differs from src/tramp-v1-pinned.S"; exit 1
fi
if [ -f "$WORK/stub-copy.bin" ]; then
    s3=$(md5sum "$WORK/stub-copy.bin" | cut -d' ' -f1)
    sp3=$(md5sum "$STUBBIN" | cut -d' ' -f1)
    if [ "$s3" = "$sp3" ]; then
        echo "OK: bench stub copy builds to exactly probes/handoff/abort-postmmu.bin"
        echo "    (TV constants: record 0x23080000, staged 0x30000800 -> 0x20280000,"
        echo "     0x12d4a00 bytes, entry 0x21220000, and it is the blob the chain runs)"
    else
        echo "NOTE: the repo stub has changed since src/abort-stub-v3.S was pinned"
        echo "      pinned: $s3"; echo "      repo:   $sp3"
    fi
fi
if [ -f "$WORK/v5-copy.bin" ]; then
    s5=$(md5sum "$WORK/v5-copy.bin" | cut -d' ' -f1)
    if [ "$s5" = "$sp" ]; then
        echo "OK: bench v5 copy builds to exactly probes/handoff/tramp-postmmu.bin"
    else
        echo "NOTE: the repo tramp has changed again since src/tramp-v5.S was pinned"
        echo "      pinned v5: $s5"; echo "      repo blob: $sp"
    fi
fi
if [ -f "$WORK/v4-copy.bin" ]; then
    s4=$(md5sum "$WORK/v4-copy.bin" | cut -d' ' -f1)
    if [ "$s4" = "$sp" ]; then
        echo "OK: bench v4 copy builds to exactly probes/handoff/tramp-postmmu.bin"
    else
        echo "NOTE: the repo tramp has changed again since src/tramp-v4.S was pinned"
        echo "      pinned v4: $s4"; echo "      repo blob: $sp"
    fi
fi
if [ -f "$WORK/v2-copy.bin" ]; then
    s2=$(md5sum "$WORK/v2-copy.bin" | cut -d' ' -f1)
    if [ "$s2" = "$sp" ]; then
        echo "OK: bench v2 copy builds to exactly probes/handoff/tramp-postmmu.bin"
    else
        echo "NOTE: the repo tramp has changed again since src/tramp-v2.S was pinned"
        echo "      pinned v2: $s2"
        echo "      repo blob: $sp"
    fi
fi
