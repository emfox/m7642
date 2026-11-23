#!/bin/bash
# Build an image with an arbitrary set of patches into the tramp blob.
#
#   mk-multi.sh <tag> <spec>...
#   spec := <checkpoint-name-or-offset>=<entry>
#   entry := pa | kva | save | restore
#            pa      _start        Image+0x36c000
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
[ $# -ge 1 ] || { echo "need at least one spec" >&2; exit 1; }

resolve() { python3 ../../tools/host/ckpt.py --sysmap "$SYSMAP" --env "$1" | cut -d= -f2; }
KADDR=0x20280000 KERNEL="$KERNEL" ./build-postmmu.sh >/dev/null
. ./tramp-entries.env

ARGS=("--word" "$(resolve zfix_align)=0xaa1f03f9" "--patch" "0x4=$TRAMP_FDT_ENTRY")
for spec in "$@"; do
	ck=${spec%%=*}; ent=${spec#*=}
	case "$ck" in 0x*) off=$ck ;; *) off=$(resolve "$ck") ;; esac
	case "$ent" in
	pa)      tgt=$TRAMP_PA_ENTRY ;;
	kva)     tgt=$TRAMP_KVA_ENTRY ;;
	save)    tgt=$(( TRAMP_AT + 0x400 )) ;;
	restore) tgt=$(( TRAMP_AT + 0x500 )) ;;
	*) echo "bad entry '$ent'" >&2; exit 1 ;;
	esac
	echo "  $ck -> $(printf %#x $off) : bl $(printf %#x $tgt)"
	ARGS+=("--patch" "$off=$tgt")
done
ARGS+=("--nop" "$(resolve zfix_nop)")
python3 ../../tools/host/mk-mainline-abort.py --image "$IMAGE" \
	--stub abort-postmmu.bin --tramp tramp-postmmu.bin --tramp-at 0x36c000 \
	"${ARGS[@]}" --out "$OUT/m7642-$TAG.img"
