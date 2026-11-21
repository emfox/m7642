#!/usr/bin/env python3
"""Add a zero-the-pool stub at code1 to an already-built rung image."""
import struct, sys, hashlib
img, stub_path, out = sys.argv[1:4]
d = bytearray(open(img, "rb").read())
stub = open(stub_path, "rb").read()
page = 2048
at = 0x1400800                      # right after the handover stub (0x1400000 + 2 KB)
d[page+at:page+at+len(stub)] = stub
imm = ((at - 4) >> 2) & 0x3FFFFFF
struct.pack_into("<I", d, page+4, 0x14000000 | imm)   # code1 -> zero stub
open(out, "wb").write(bytes(d))
print("zero stub at %#x, code1 -> %08x, md5 %s" % (at, 0x14000000|imm, hashlib.md5(bytes(d)).hexdigest()))
