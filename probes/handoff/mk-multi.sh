#!/bin/bash
# Build an image with an arbitrary set of patches into the tramp blob.
#
#   mk-multi.sh <tag> <spec>...
#   spec := <checkpoint-name-or-offset>=<entry>
#   entry := pa | kva | save | restore
#            pa      _start        Image+0x36e000
#            kva     _start_kva    Image+0x36c010
#            save    _start_save   Image+0x36c400  (world A, returns to the kernel)
#            restore _start_restore Image+0x36c500 (world B, restores TTBR0/TCR)
set -eu
cd "$(dirname "$0")"
KERNEL=${KERNEL:-$HOME/Debian/m7642-build/kernel/linux-735-out}
OUT=${OUT:-$HOME/Debian/m7642-build/out}
SYSMAP=$KERNEL/System.map
IMAGE=$KERNEL/arch/arm64/boot/Image
TAG=$1; shift
# PLAIN=1 (or no specs) builds a boot-only image: alignment fix + entry shim,
# no checkpoints, no hand-over.  Used to test a plain kernel boot.
[ $# -ge 1 ] || [ "${PLAIN:-0}" = 1 ] || { echo "need at least one spec (or PLAIN=1)" >&2; exit 1; }

resolve() { python3 ../../tools/host/ckpt.py --sysmap "$SYSMAP" --env "$1" | cut -d= -f2; }
# readout symbols: "name" or "name+delta", comma or space separated
syms_to_vas() {
	python3 - "$SYSMAP" "$1" <<'PY'
import sys
syms = {}
for line in open(sys.argv[1]):
    p = line.split()
    if len(p) >= 3: syms[p[2]] = int(p[0], 16)
out = []
for spec in sys.argv[2].replace(",", " ").split():
    name, _, delta = spec.partition("+")
    if name in syms: out.append(hex(syms[name] + (int(delta, 0) if delta else 0)))
    else: sys.stderr.write("no such symbol: %s\n" % name)
print(" ".join(out))
PY
}
READOUT_SYMS=$(syms_to_vas "${READOUT_SYMS:-memblock+16 memblock+32 memblock+56 memblock+72 max_pfn min_low_pfn}")
export READOUT_SYMS
KADDR=${KADDR:-0x20280000} KERNEL="$KERNEL" ./build-postmmu.sh >/dev/null
. ./tramp-entries.env

# The 2 MB-alignment fix is only needed because the image is loaded at
# 0x20280000 (base + 0x80000).  NO_ALIGN=1 builds without it, for the
# experiment where mboot is asked (via --kernel-addr) to load us 2 MB aligned.
ARGS=()
[ "${NO_ALIGN:-0}" = 1 ] || ARGS+=("--word" "$(resolve zfix_align)=0xaa1f03f9")
ARGS+=("--patch" "0x4=$TRAMP_FDT_ENTRY")
for spec in "$@"; do
	ck=${spec%%=*}; ent=${spec#*=}
	case "$ck" in 0x*) off=$ck ;; *) off=$(resolve "$ck") ;; esac
	case "$ent" in
	pa)      tgt=$TRAMP_PA_ENTRY ;;
	kva)     tgt=$TRAMP_KVA_ENTRY ;;
	save)    tgt=$(( TRAMP_AT + 0x400 )) ;;
	restore) tgt=$(( TRAMP_AT + 0x500 )) ;;
	readout) tgt=$(( TRAMP_AT + 0x600 )) ;;
	count)   tgt=$(( TRAMP_AT + 0x700 )) ;;
	regdump) tgt=$(( TRAMP_AT + 0x800 )) ;;
	*) echo "bad entry '$ent'" >&2; exit 1 ;;
	esac
	echo "  $ck -> $(printf %#x $off) : bl $(printf %#x $tgt)"
	ARGS+=("--patch" "$off=$tgt")
done
# The dcache-invalid NOP at preserve_boot_args+0x20 has never been
# proven necessary; NO_NOP=1 builds an image without it.
if [ "${NO_NOP:-0}" != 1 ]; then
ARGS+=("--nop" "$(resolve zfix_nop)")
fi
python3 ../../tools/host/mk-mainline-abort.py --image "$IMAGE" \
	--stub abort-postmmu.bin --tramp tramp-postmmu.bin --tramp-at ${TRAMP_AT:-0x36e000} \
	${KERNEL_ADDR:+--kernel-addr $KERNEL_ADDR} \
	"${ARGS[@]}" --out "$OUT/m7642-$TAG.img"
