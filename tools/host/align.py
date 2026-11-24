import os
R=os.path.expanduser("~/Debian/m7642")
p=os.path.join(R,"tools/host/mk-mainline-abort.py"); s=open(p).read()
if "--kernel-addr" not in s:
    s=s.replace('''    ap.add_argument("--out", required=True)''','''    ap.add_argument("--kernel-addr", type=lambda x: int(x, 0), default=None,
                    help="rewrite the container's kernel_addr (arm64 needs 2 MB alignment)")
    ap.add_argument("--stub-at", type=lambda x: int(x, 0), default=0x1400000,
                    help="Image offset for the appended stub (default 0x1400000)")
    ap.add_argument("--out", required=True)''')
    s=s.replace("    at = max(len(kern), 0x1400000)","    at = max(len(kern), a.stub_at)")
    s=s.replace('''    struct.pack_into("<I", hdr, 16, 0)                  # ramdisk_size = 0''','''    struct.pack_into("<I", hdr, 16, 0)                  # ramdisk_size = 0
    if a.kernel_addr is not None:
        struct.pack_into("<I", hdr, 12, a.kernel_addr)  # where mboot loads us
        print("kernel_addr %#x" % a.kernel_addr)''')
    open(p,"w").write(s); print("patcher: --kernel-addr / --stub-at")

# 2 MB 对齐的 checkpoint 构建脚本
p=os.path.join(R,"probes/handoff/mk-aligned.sh")
open(p,"w").write('''#!/bin/bash
# Build a checkpoint image at a 2 MB ALIGNED load address.
#
# Why (measured 2026-11-22 14:0x): __pi_early_map_kernel computes the relocation
# offset as `adrp _text & 0x1fffff`.  With mmap off `adrp` yields the PHYSICAL
# address, so a kernel loaded at 0x20280000 gets offset 0x80000 -- and that
# shifts every relocated pointer by 512 KB.  `br x8` then jumps to
# 0xffffffc0804e805c (data) instead of 0xffffffc08046805c (__primary_switched).
# arm64's boot protocol wants the Image at a 2 MB aligned base; mboot's
# 0x20280000 is not, which the vendor kernel happens to tolerate and mainline
# does not.
#
# 2 MB aligned base 0x20400000, stub parked at 0x21680000 (still outside the
# 0x20280000..0x21554a00 region the handover copies into).
#
#   mk-aligned.sh <checkpoint-image-offset> <tag> [nop-offset ...]
set -eu
cd "$(dirname "$0")"
KADDR=0x20400000
STUB_AT=0x1280000            # 0x20400000 + 0x1280000 = 0x21680000
CROSS=${CROSS:-$HOME/Debian/m7642-build/toolchain/gcc13/bin/aarch64-buildroot-linux-gnu-}
IMAGE=${IMAGE:-$HOME/Debian/m7642-build/kernel/linux-main/arch/arm64/boot/Image}
OUT=${OUT:-$HOME/Debian/m7642-build/out}
OFF=$1; TAG=$2; shift 2

# rebuild the blobs with the aligned addresses baked in
KADDR=$KADDR ./build-postmmu.sh >/dev/null

python3 ../../tools/host/mk-mainline-abort.py \\
	--image "$IMAGE" --kernel-addr $KADDR --stub-at $STUB_AT \\
	--patch "0x4=0x36c0c0" --patch "$OFF=0x36c000" \\
	--stub abort-postmmu.bin --tramp tramp-postmmu.bin --tramp-at 0x36c000 \\
	"$@" \\
	--out "$OUT/m7642-rec-73-$TAG.img"
''')
os.chmod(p,0o755)
print("mk-aligned.sh written")
