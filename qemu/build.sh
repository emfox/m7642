#!/bin/bash
# build.sh <profile> <scenario> <variant>
#
# Builds the fake kernel + tramp blob for one bench configuration.
#   profile  : zcu102 | virt
#   scenario : 1 (P1, idmap alive) 2 (P2, idmap gone) 3 (P1, entry x5=0)
#              4 (P2, entry x5=0)
#   variant  : vanilla | badlin | no-idmap | pa-alias | dbl-offset
set -eu
CD=$(cd "$(dirname "$0")" && pwd)
cd "$CD"
PROFILE=${1:?profile}; SCEN=${2:?scenario}; VAR=${3:-vanilla}; TVER=${4:-v1}
MODE=${5:-normal}			# normal | chain
TC=${TC:-/home/emfox/Debian/m7642-build/toolchain/gcc13/bin}
CC=$TC/aarch64-buildroot-linux-gnu-gcc
LD=$TC/aarch64-buildroot-linux-gnu-ld
OC=$TC/aarch64-buildroot-linux-gnu-objcopy
OD=$TC/aarch64-buildroot-linux-gnu-objdump

python3 gen.py "$PROFILE" "$SCEN" "$VAR" "$TVER" "$MODE"
eval "$(cat gen/profile.sh)"

TRAMP_DEFS=$(cat gen/tramp-defs.txt)
# tramp: same -D shape as probes/handoff/build-postmmu.sh
TRAMP_SRC=$(cat gen/tramp-src.txt)
"$CC" -I. $TRAMP_DEFS -c "$TRAMP_SRC" -o gen/tramp.o
"$OC" -O binary --only-section=.text gen/tramp.o gen/tramp.bin
"$OD" -d gen/tramp.o > gen/tramp.dis

# the instruction words at the interesting blob offsets, so the bench can check
# (and name) what a patched `bl` would land on
python3 - "$TRAMP_ENTRY_OFF" <<'PYW'
import struct, sys
d = open("gen/tramp.bin", "rb").read()
def w(off):
    return struct.unpack_from("<I", d, off)[0] if off + 4 <= len(d) else 0
with open("gen/words.inc", "w") as f:
    f.write("/* generated: instruction words inside the tramp blob */\n")
    f.write(".equ TRAMP_W0, %#x\n" % w(0))
    f.write(".equ TRAMP_W4, %#x\n" % w(4))
    f.write(".equ TRAMP_W_ENTRY, %#x\n" % w(int(sys.argv[1], 0)))
PYW
cat gen/words.inc >> gen/layout.inc

# the VA entry offset (_start_kva) is version dependent: verify it
KVA_OFF=$("$TC/aarch64-buildroot-linux-gnu-nm" gen/tramp.o | awk '$3=="_start_kva"{print "0x"$1}')
if [ $(( KVA_OFF )) -ne $(( TRAMP_ENTRY_OFF )) ]; then
	echo "FATAL: _start_kva is at $KVA_OFF but gen.py assumed $TRAMP_ENTRY_OFF (version $TRAMP_VERSION)" >&2
	exit 1
fi

# fake kernel: SCENARIO/KILL_IDMAP are cpp-level, everything else is .equ
CFLAGS="-I. -I src -DSPIN_ON_FAULT=${SPIN_ON_FAULT:-0} -DKILL_IDMAP=$KILL_IDMAP -DSCENARIO=$SCEN -DTRAMP_V2=$TRAMP_V2 -DTRAMP_V4=$TRAMP_V4 -DTRAMP_VERSION_1=$TRAMP_VERSION_1 -DCHAIN=$CHAIN -DT0SZ16=$T0SZ16 -DTABLE_RO=$TABLE_RO -DUSE_BL=$USE_BL -ffreestanding -fno-stack-protector"
"$CC" $CFLAGS -c src/boot.S -o gen/boot.o
"$CC" $CFLAGS -c src/pad.S -o gen/pad.o
"$CC" $CFLAGS -c src/tramp-blob.S -o gen/tramp-blob.o
"$LD" -T src/link.ld --defsym=IMAGE_BASE=$IMAGE_BASE \
	-o gen/image.elf gen/boot.o gen/pad.o gen/tramp-blob.o

QEMU_ARGS_FILE=gen/qemu-args.txt
: > "$QEMU_ARGS_FILE"
if [ "$CHAIN" = 1 ]; then
	# full chain: the tramp hands over to the real abort-postmmu.S at its TV
	# address (loaded as a raw blob), which records, copies 0x12d4a00 bytes and
	# jumps to 0x21220000 -- where the impostor sits inside the staged payload.
	CC_SAVE=$CFLAGS
	"$CC" -I. -I src -c src/abort-stub-v3.S -o gen/stub.o
	"$OC" -O binary --only-section=.text gen/stub.o gen/stub.bin
	"$CC" $CFLAGS -c src/impostor.S -o gen/impostor.o
	"$OC" -O binary --only-section=.text gen/impostor.o gen/impostor.bin
	"$LD" -Ttext=0x21220000 -e _start gen/impostor.o -o gen/impostor.elf
	"$OC" -O binary gen/impostor.elf gen/impostor.bin
	python3 - <<'PYX'
import os
SIZE = 0x12d4a00
OFF_IMP = 0xFA0000          # -> 0x21220000 when loaded at 0x20280000
OFF_SIG = 0x100000          # -> 0x20380000
path = "gen/stage.bin"
with open(path, "wb") as f:
    f.truncate(SIZE)
    f.seek(OFF_SIG)
    f.write(b"STAGE-OK")
    f.seek(OFF_IMP)
    f.write(open("gen/impostor.bin", "rb").read())
PYX
	printf -- "-device loader,file=gen/stub.bin,addr=0x21680000,force-raw=on " >> "$QEMU_ARGS_FILE"
	printf -- "-device loader,file=gen/stage.bin,addr=0x30000800,force-raw=on" >> "$QEMU_ARGS_FILE"
fi

if [ "${QUIET:-0}" != 1 ]; then
	echo "  [$PROFILE/$SCENARIO_NAME/$VAR/$TRAMP_VERSION] image=$(printf %#x $IMAGE_BASE)" \
	     "tramp_pa=$(printf %#x $TRAMP_PA) tramp_va=$(printf %#x $TRAMP_VA)" \
	     "blob_md5=$(md5sum <gen/tramp.bin | cut -d' ' -f1)"
fi
