#!/usr/bin/env python3
"""Flip MstarUpgrade_complete in place inside an mboot env block.

In-place means: one byte changes, nothing else moves, and only the leading
crc32 is recomputed.  envtool.py rebuilds the whole block from parsed
key=value pairs, which is fine when the block is clean but silently drops any
stray bytes; for a block we are about to write to the eMMC the difference
matters, so the surgical edit is preferred.
"""
import struct
import sys
import zlib

BODY = 0x10000
KEY = b"MstarUpgrade_complete="


def main(path, want):
    blk = bytearray(open(path, "rb").read())
    if len(blk) != BODY:
        raise SystemExit("%s is %d bytes, expected %d" % (path, len(blk), BODY))

    before = struct.unpack("<I", blk[0:4])[0]
    calc = zlib.crc32(bytes(blk[4:BODY])) & 0xFFFFFFFF
    print("crc stored=0x%08x calc=0x%08x  %s"
          % (before, calc, "OK" if before == calc else "MISMATCH"))

    pos = blk.find(KEY)
    if pos < 0:
        raise SystemExit("key not found")
    vpos = pos + len(KEY)
    old = blk[vpos:vpos + 1]
    print("key at 0x%04x  value at 0x%04x  %r -> %r" % (pos, vpos, old, want))
    if old == want:
        print("already set, nothing to do")
        return
    blk[vpos:vpos + 1] = want
    blk[0:4] = struct.pack("<I", zlib.crc32(bytes(blk[4:BODY])) & 0xFFFFFFFF)
    open(path, "wb").write(blk)
    print("new crc 0x%08x  wrote %s" % (struct.unpack("<I", blk[0:4])[0], path))


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2].encode() if len(sys.argv) > 2 else b"1")
