#!/usr/bin/env python3
"""Wrap a bare arm64 Image into an Android boot image with an abort stub.

The stub is appended after the kernel; kernel offset 4 (code1) is patched to
branch to it; kernel_size covers kernel+stub and ramdisk_size is zeroed.  The
container is taken from a factory boot image so the page size and addresses
match what mboot expects.

For post-MMU checkpoints the appended stub cannot be reached (it lives past
_end), so --tramp injects a transition stub inside the mapped text and
--target points the checkpoint there instead.  --patch adds further
OFF=TARGET branch sites (e.g. code1 -> the pre-MMU entry shim).
"""
import argparse, struct, hashlib

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--src", default="/home/emfox/kbuild/rec/recovery_full.bin")
    ap.add_argument("--image", default="/home/emfox/kbuild/tcl-419/arch/arm64/boot/Image")
    ap.add_argument("--at", type=lambda x: int(x, 0), default=None,
                    help="Image offset to patch with `bl` (default: code1 at 4)")
    ap.add_argument("--nop", type=lambda x: int(x, 0), action="append", default=[],
                    help="Image offset(s) to overwrite with nop")
    ap.add_argument("--stub", required=True)
    ap.add_argument("--tramp", default=None,
                    help="transition stub injected inside the image")
    ap.add_argument("--tramp-at", type=lambda x: int(x, 0), default=0x36c000,
                    help="Image offset for --tramp (default: end-of-.text padding)")
    ap.add_argument("--target", type=lambda x: int(x, 0), default=None,
                    help="branch target for the patch (default: appended stub)")
    ap.add_argument("--patch", action="append", default=[],
                    help="OFF=TARGET branch site; replaces --at/--target when given")
    ap.add_argument("--out", required=True)
    a = ap.parse_args()

    src = bytearray(open(a.src, "rb").read())
    kern = open(a.image, "rb").read()
    stub = open(a.stub, "rb").read()
    assert src[:8] == b"ANDROID!", "not an ANDROID! container"
    page = struct.unpack("<I", src[36:40])[0] or 2048
    kernel_addr = struct.unpack("<I", src[12:16])[0]

    # The stub must live OUTSIDE the region the handover copies into
    # (0x20280000..0x21554a00 for the factory kernel), or the copy overwrites
    # the code that is still running.  Default: just past the factory kernel.
    at = max(len(kern), 0x1400000)
    at += (-at) % page
    body = bytearray(kern)
    body += b"\0" * (at - len(body))
    body = bytes(body) + stub
    body += b"\0" * ((-len(body)) % page)

    code = bytearray(body)
    for off in a.nop:
        struct.pack_into("<I", code, off, 0xD503201F)
        print("nop at %#x" % off)
    if a.tramp:
        tramp = open(a.tramp, "rb").read()
        ta = a.tramp_at
        assert len(tramp) and ta + len(tramp) <= at, "tramp overlaps the stub"
        code[ta:ta + len(tramp)] = tramp
        print("tramp %d B at Image+%#x (PA %#x, VA %#x)" %
              (len(tramp), ta, kernel_addr + ta, 0xffffffc080000000 + ta))
    if a.patch:
        patches = []
        for spec in a.patch:
            off, _, tgt = spec.partition("=")
            patches.append((int(off, 0), int(tgt, 0)))
    else:
        patches = [(a.at if a.at is not None else 4,
                    a.target if a.target is not None else at)]
    for patch_at, target in patches:
        assert 0 <= patch_at < len(code) and 0 <= target < len(code)
        delta = target - patch_at
        assert -(1 << 27) <= delta < (1 << 27), "branch out of range"
        struct.pack_into("<I", code, patch_at, 0x94000000 | ((delta >> 2) & 0x3FFFFFF))
        print("patch at %#x -> bl %#x" % (patch_at, target))

    hdr = bytearray(src[:page])
    struct.pack_into("<I", hdr, 8, len(code))           # kernel_size
    struct.pack_into("<I", hdr, 16, 0)                  # ramdisk_size = 0

    out = bytes(hdr) + bytes(code)
    assert len(out) <= len(src), "does not fit"
    out += b"\0" * (len(src) - len(out))
    open(a.out, "wb").write(out)
    print("kernel %d B + stub %d B at %#x, kernel_size %#x, ramdisk 0" %
          (len(kern), len(stub), at, len(code)))
    print("md5", hashlib.md5(out).hexdigest())

if __name__ == "__main__":
    main()
