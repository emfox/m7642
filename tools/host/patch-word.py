#!/usr/bin/env python3
"""Overwrite one 4-byte word at Image offset `off` inside a built boot image."""
import struct, sys, hashlib
img, off, word, out = sys.argv[1], int(sys.argv[2], 0), int(sys.argv[3], 0), sys.argv[4]
d = bytearray(open(img, "rb").read())
page = 2048
old = struct.unpack("<I", d[page+off:page+off+4])[0]
struct.pack_into("<I", d, page+off, word)
open(out, "wb").write(bytes(d))
print("Image+%#x: %08x -> %08x, md5 %s" % (off, old, word, hashlib.md5(bytes(d)).hexdigest()))
