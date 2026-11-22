#!/bin/bash
# Build the in-function checkpoints of __pi_early_map_kernel plus the
# return-to-kernel-VA probes.
#
# emap (entry, 0x4659e0) returns and prsw (__primary_switched, 0x46805c) does
# not, so the kernel dies in between.  mk1..mk6 walk the function body; ps0/ps1
# bracket the `br x8` into the kernel VA:
#
#   mk1 0x465a94  bl __memset                    (after map_fdt + dsb)
#   mk2 0x465ab8  bl __pi_init_feature_override  (after fdt_path_offset)
#   mk3 0x465c14  bl idmap_cpu_replace_ttbr1     (after the 6 map_segment calls)
#   mk4 0x465c1c  bl __pi_relocate_kernel        (after the first TTBR1 switch)
#   mk5 0x465ca4  bl idmap_cpu_replace_ttbr1     (after memcpy)
#   mk6 0x465cbc  ldp x27, x28                   (epilogue)
#   ps0 0x4555b0  br x8                          (kernel-VA branch, still PA)
#   ps1 0x468060  __primary_switched+4           (after the br + bti c)
#   kva 0x4555b0  custom stub: record x8, read kernel VAs
set -eu
cd "$(dirname "$0")"
KERNEL=${KERNEL:-/home/emfox/kbuild/linux-main}
IMAGE=${IMAGE:-$KERNEL/arch/arm64/boot/Image}
OUT=${OUT:-/home/emfox/kbuild/m7642-out}
MK=../../tools/host/mk-mainline-abort.py
CROSS=${CROSS:-$HOME/kbuild/toolchain-gcc13/bin/aarch64-buildroot-linux-gnu-}
TRAMP_AT=0x36c000
FDT_SHIM=$((TRAMP_AT + 0xc0))

build() {	# off tag entry
	python3 "$MK" --image "$IMAGE" \
		--patch "0x4=$FDT_SHIM" --patch "$1=$3" \
		--stub abort-postmmu.bin --tramp tramp-postmmu.bin --tramp-at $TRAMP_AT \
		--nop 0x46804c \
		--out "$OUT/m7642-rec-73-$2.img"
}

for spec in "0x465a94 mk1" "0x465ab8 mk2" "0x465c14 mk3" \
	    "0x465c1c mk4" "0x465ca4 mk5" "0x465cbc mk6" \
	    "0x4555b0 ps0"; do
	set -- $spec
	build "$1" "$2" $TRAMP_AT
done
build 0x468060 ps1 $((TRAMP_AT + 4))

# kva: the code1 shim comes from the tramp blob, the custom stub sits in the
# tramp slot.
"${CROSS}gcc" -c -o /tmp/kvacheck.o kvacheck.S
"${CROSS}objcopy" -O binary --only-section=.text /tmp/kvacheck.o /tmp/kvacheck.bin
python3 "$MK" --image "$IMAGE" \
	--patch "0x4=$FDT_SHIM" --patch "0x4555b0=$TRAMP_AT" \
	--stub tramp-postmmu.bin --tramp /tmp/kvacheck.bin --tramp-at $TRAMP_AT \
	--nop 0x46804c \
	--out "$OUT/m7642-rec-73-kva.img"
