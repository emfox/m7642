#!/bin/bash
# Build the MMU-on probes used to find out why `br x8` into the kernel VA fails.
#
#   kva4  read *0xffffffc080000000 (_text) into a register with the MMU on,
#         drop the MMU, then store the answer.  The only MMU-on memory access.
#   kva5  write 0xded to 0x23090020 with the MMU on, read it back after the MMU
#         is off: is DDR writable under the MMU at all?
#   kva6  zero memory accesses: latch x8 / SCTLR / TTBR1 / TCR / VBAR / ESR / FAR
#         with mrs only.  This is the control that costs nothing.
#
# Both land at Image+0x36d000 (clear of the code1 shim at 0x36c0c0 and of the
# tramp at 0x36c000) and are reached from Image+0x4555b0 (`br x8`).
#
# Usage: mk-kva-images.sh
set -eu
cd "$(dirname "$0")"
CROSS=${CROSS:-$HOME/Debian/m7642-build/toolchain/gcc13/bin/aarch64-buildroot-linux-gnu-}
IMAGE=${IMAGE:-$HOME/Debian/m7642-build/kernel/linux-main/arch/arm64/boot/Image}
OUT=${OUT:-$HOME/Debian/m7642-build/out}
MK=../../tools/host/mk-mainline-abort.py
TRAMP_AT=0x36c000
SHIM_AT=$((TRAMP_AT + 0xc0))
PROBE_AT=0x36d000

# the tramp blob must exist (its code1 shim carries the built-in DTB)
[ -f tramp-postmmu.bin ] || ./build-postmmu.sh >/dev/null

for n in 4 5 6; do
	"${CROSS}gcc" -DKVA_TEST=$n -c -o "/tmp/kva$n.o" kvacheck.S
	"${CROSS}objcopy" -O binary --only-section=.text "/tmp/kva$n.o" "/tmp/kva$n.bin"
	python3 - "$n" <<'PY'
import sys
n = sys.argv[1]
tramp = open("tramp-postmmu.bin", "rb").read()
probe = open("/tmp/kva%s.bin" % n, "rb").read()
assert len(tramp) <= 0x1000 and len(probe) <= 0x1000, "blob too big"
blob = tramp + b"\0" * (0x1000 - len(tramp)) + probe
open("/tmp/kva-combined%s.bin" % n, "wb").write(blob)
print("combined %d B (tramp %d, probe %d at +0x1000)" % (len(blob), len(tramp), len(probe)))
PY
	python3 "$MK" --image "$IMAGE" \
		--patch "0x4=$SHIM_AT" --patch "0x4555b0=$PROBE_AT" \
		--stub "/tmp/kva$n.bin" --tramp "/tmp/kva-combined$n.bin" --tramp-at $TRAMP_AT \
		--nop 0x46804c \
		--out "$OUT/m7642-rec-73-kva$n.img"
done
