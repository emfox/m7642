#!/usr/bin/env python3
"""Dump the Android boot image header and the payload heads.

    ./bootimg-info.py img [img ...]

Prints every header field we care about, then the first bytes of the kernel
and ramdisk, so a hand-rolled image can be diffed against the vendor one field
by field. Exit status is 0 even when the magic looks wrong -- this is a probe,
not a checker.
"""

import struct
import sys

FIELDS_V1 = ("kernel_size", "kernel_addr", "ramdisk_size", "ramdisk_addr",
             "second_size", "second_addr", "tags_addr", "page_size")


def head_blob(b, n=48):
    return " ".join("%02x" % c for c in b[:n])


def dump(path):
    with open(path, "rb") as f:
        hdr = f.read(2048)
    print("== %s" % path)
    if hdr[:8] != b"ANDROID!":
        print("   magic not ANDROID!: %r" % hdr[:8])
        return
    vals = struct.unpack("<8I", hdr[8:40])
    for name, v in zip(FIELDS_V1, vals):
        print("   %-13s 0x%08x (%d)" % (name, v, v))
    hdr_ver, os_ver = struct.unpack("<2I", hdr[40:48])
    print("   %-13s %d" % ("header_version", hdr_ver))
    print("   %-13s 0x%08x" % ("os_version", os_ver))
    print("   %-13s %r" % ("name", hdr[48:64].rstrip(b"\0")))
    print("   %-13s %r" % ("cmdline", hdr[64:576].split(b"\0")[0]))
    print("   %-13s %s" % ("id[0:20]", head_blob(hdr[576:596], 20)))
    print("   %-13s %s" % ("id[20:32]", head_blob(hdr[596:608], 12)))
    page, ksize, rsize = vals[7], vals[0], vals[2]
    with open(path, "rb") as f:
        f.seek(page)
        khead = f.read(64)
        print("   kernel head  %s" % head_blob(khead, 32))
        print("   kernel +0x38 %s   (arm64 wants 41 52 4d 64 = 'ARM\\x64')"
              % head_blob(khead[0x38:0x40], 8))
        if rsize:
            f.seek(page + ((ksize + page - 1) // page) * page)
            rhead = f.read(32)
            print("   ramdisk head %s" % head_blob(rhead, 32))


if __name__ == "__main__":
    if len(sys.argv) < 2:
        sys.exit(__doc__)
    for p in sys.argv[1:]:
        dump(p)
        print()
