#!/usr/bin/env python3
"""Wrap a bare arm64 Image into an Android boot image with an abort stub.

The stub is appended after the kernel; kernel offset 4 (code1) is patched to
branch to it, kernel_size covers kernel+stub and ramdisk_size is zeroed.  The
container is taken from a factory boot image so the page size and addresses
match what mboot expects.
"""
import argparse, struct, hashlib

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--src", default="/home/emfox/kbuild/rec/recovery_full.bin")
    ap.add_argument("--image", default="/home/emfox/kbuild/tcl-419/arch/arm64/boot/Image")
    ap.add_argument("--stub", required=True)
    ap.add_argument("--out", required=True)
    a = ap.parse_args()

    src = bytearray(open(a.src, "rb").read())
    kern = open(a.image, "rb").read()
    stub = open(a.stub, "rb").read()
    assert src[:8] == b"ANDROID!", "not an ANDROID! container"
    page = struct.unpack("<I", src[36:40])[0] or 2048

    at = len(kern)
    body = bytearray(kern)
    body = body[:at - ((-at) % page)] if False else bytearray(kern)
    # pad kernel to a page so the stub starts aligned
    if len(body) % page:
        body += b"\0" * (page - len(body) % page)
    at = len(body)
    body = bytes(body) + stub
    body += b"\0" * ((-len(body)) % page)

    code = bytearray(body)
    imm = ((at - 4) >> 2) & 0x3FFFFFF
    struct.pack_into("<I", code, 4, 0x14000000 | imm)   # code1 -> stub

    hdr = bytearray(src[:page])
    struct.pack_into("<I", hdr, 8, len(code))           # kernel_size
    struct.pack_into("<I", hdr, 16, 0)                  # ramdisk_size = 0

    out = bytes(hdr) + bytes(code)
    assert len(out) <= len(src), "does not fit"
    out += b"\0" * (len(src) - len(out))
    open(a.out, "wb").write(out)
    print("kernel %d B + stub %d B at %#x, kernel_size %#x, ramdisk 0" %
          (len(kern), len(stub), at, len(code)))
    print("code1 %08x" % (0x14000000 | imm))
    print("md5", hashlib.md5(out).hexdigest())

if __name__ == "__main__":
    main()
