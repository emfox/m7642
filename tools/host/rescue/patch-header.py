#!/usr/bin/env python3
"""Delete one partition section from an existing MStar upgrade BIN, in place.

Only the 16 KiB script block and the footer CRC are touched; the payload is
left byte for byte identical, so the bootloader's AllBinCRC stays valid.
That is the only kind of edit that keeps a package acceptable to mboot --
fabricating a package from scratch needs the AllBinCRC algorithm, which we
have not reproduced yet.

  ./patch-header.py MstarUpgrade.bin userdata           # dry run
  ./patch-header.py MstarUpgrade.bin userdata --apply
"""

import argparse
import hashlib
import struct
import sys
import zlib

HEADER = 0x4000
MAGIC = b"12345678"


def read_script(f, size):
    f.seek(0)
    block = f.read(HEADER)
    text = block.split(b"\xff", 1)[0].decode("latin1")
    return block, text


def strip_part(text, name):
    lines = text.splitlines(keepends=True)
    out, skip, seen = [], False, False
    for ln in lines:
        if ln.startswith("# File Partition:"):
            skip = ln.split(":", 1)[1].strip() == name
            seen = seen or skip
        if not skip:
            out.append(ln)
    return "".join(out), seen


def crc_at(f, size):
    f.seek(size - 32)
    foot = f.read(32)
    if foot[:8] != MAGIC:
        sys.exit("footer magic not where expected")
    return foot, struct.unpack("<I", foot[8:12])[0]


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("bin")
    ap.add_argument("partition")
    ap.add_argument("--apply", action="store_true")
    a = ap.parse_args()

    size = __import__("os").path.getsize(a.bin)
    with open(a.bin, "rb") as f:
        block, text = read_script(f, size)
        foot, old_crc = crc_at(f, size)
        f.seek(HEADER)
        payload_md5 = hashlib.md5()
        left = size - HEADER - 32
        while left:
            chunk = f.read(min(1 << 22, left))
            payload_md5.update(chunk)
            left -= len(chunk)

    new_text, removed = strip_part(text, a.partition)
    if not removed:
        sys.exit("no such partition section: %s" % a.partition)

    new_block = new_text.encode("latin1")
    if len(new_block) > HEADER:
        sys.exit("script would overflow the 16 KiB block")
    new_block += b"\xff" * (HEADER - len(new_block))
    new_crc = zlib.crc32(new_block) & 0xFFFFFFFF

    print("removed section : %s" % a.partition)
    print("script bytes    : %d -> %d" % (len(text), len(new_text)))
    print("footer crc      : 0x%08x -> 0x%08x" % (old_crc, new_crc))
    print("payload md5     : %s (unchanged by design)" % payload_md5.hexdigest())
    diff = [l for l in new_text.splitlines() if l.startswith(("filepartload", "mmc ", "sparse_write"))]
    print("remaining cmds  : %d" % len(diff))

    if not a.apply:
        print("dry run; pass --apply to write")
        return

    with open(a.bin, "r+b") as f:
        f.seek(0)
        f.write(new_block)
        f.seek(size - 24)
        f.write(struct.pack("<I", new_crc))
    print("written")


if __name__ == "__main__":
    main()
