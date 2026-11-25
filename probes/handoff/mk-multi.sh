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

# Per-build constants come from the image itself (byte pattern for the early
# head.S alignment instruction, reserved slot for the trampoline).  Symbol
# names are not usable for .pi.text and config changes move code around.
RESOLVED=$(python3 ../../tools/host/resolve-params.py "$IMAGE" "$SYSMAP") || {
	echo "mk-multi: cannot resolve per-build constants" >&2; exit 1; }
# The 2 MB alignment instruction MUST come from the symbol-relative definition
# in tools/host/ckpt.py (__pi_early_map_kernel+0x3c).  Searching the image for
# the byte pattern finds a coincidental match (0x465224 in the 7.3.5 build) and
# silently patches unrelated code -- the kernel then dies in head.S and every
# probe image "hangs with no record".  Cost: several hours on 2026-11-25.
ALIGN_OFF=$(resolve zfix_align)
ALIGN_WORD=0x92405279
SLOT_OFF=$(printf '%s\n' "$RESOLVED" | sed -n 's/^SLOT_OFF=//p')
[ -n "$ALIGN_OFF" ] && [ -n "$SLOT_OFF" ] || { echo "mk-multi: bad resolve output" >&2; exit 1; }
python3 - "$IMAGE" "$ALIGN_OFF" "$ALIGN_WORD" <<'PY'
import struct, sys
img, off, want = sys.argv[1], int(sys.argv[2], 0), int(sys.argv[3], 0)
d = open(img, "rb").read()
w = struct.unpack_from("<I", d, off)[0]
if w != want:
    sys.exit("mk-multi: align site %#x holds %#010x, expected %#010x" % (off, w, want))
PY
USER_TRAMP_AT=${TRAMP_AT:-}
KADDR=${KADDR:-0x20280000} KERNEL="$KERNEL" TRAMP_AT=${USER_TRAMP_AT:-$SLOT_OFF} ./build-postmmu.sh >/dev/null
. ./tramp-entries.env
TRAMP_AT=${USER_TRAMP_AT:-$SLOT_OFF}

# The 2 MB-alignment fix is only needed because the image is loaded at
# 0x20280000 (base + 0x80000).  NO_ALIGN=1 builds without it, for the
# experiment where mboot is asked (via --kernel-addr) to load us 2 MB aligned.
ARGS=()
[ "${NO_ALIGN:-0}" = 1 ] || ARGS+=("--word" "$ALIGN_OFF=0xaa1f03f9")
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
# Metadata next to every image: without this a working image cannot be
# reproduced once the build tree moves (discipline.md §4).
META="$OUT/m7642-$TAG.meta"
{
	echo "image    : m7642-$TAG.img  md5 $(md5sum "$OUT/m7642-$TAG.img" | cut -d' ' -f1)"
	echo "kernel   : $KERNEL"
	echo "kimage   : md5 $(md5sum "$IMAGE" | cut -d' ' -f1)"
	echo "sysmap   : md5 $(md5sum "$SYSMAP" | cut -d' ' -f1)"
	[ -f "$KERNEL/.config" ] && echo "config   : md5 $(md5sum "$KERNEL/.config" | cut -d' ' -f1)"
	echo "align    : $(resolve zfix_align) -> mov x25,xzr"
	echo "nop      : $(resolve zfix_nop)"
	echo "tramp_at : ${TRAMP_AT:-0x36e000}"
	echo "save_va  : ${SAVE_VA:-default}"
	echo "specs    : $*"
	echo "built    : $(date -Is)"
} > "$META"

python3 ../../tools/host/mk-mainline-abort.py --image "$IMAGE" \
	--stub abort-postmmu.bin --tramp tramp-postmmu.bin --tramp-at "$TRAMP_AT" \
	${KERNEL_ADDR:+--kernel-addr $KERNEL_ADDR} \
	"${ARGS[@]}" --out "$OUT/m7642-$TAG.img"
