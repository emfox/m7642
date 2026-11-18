#!/usr/bin/env python3
"""Two-trampoline image: whichever offset the bootloader starts at, end up in
primary_entry -- and leave a colour behind on the way.

Evidence so far:
  probe-entry2    code1 = b +0x600000, blobs at 0x600000 and 0xFA0000 -> solid colour
  probe-fixed     Image's own code1 (b +0x429038)                     -> bootloader picture
  probe-tramp     Image's own code1, blob at 0xFA0000                 -> bootloader picture

The only build that ever ran code we placed had code1 rewritten to `b +0x600000`.
So the rewrite is the variable that matters, not which offset the blob sits at.
This build keeps that rewrite and puts a full blob at 0x600000 (paint, hold,
branch) plus a bare branch at 0xFA0000, so the screen separates three cases:

  no colour at all      -> 0x600000 was never reached either
  colour, then nothing  -> the blob ran, but primary_entry dies on entry
  colour, then magenta  -> primary_entry is alive and the kernel is running
"""
import struct
import os

OUT = os.path.expanduser("~/kbuild/m7642-out")
IMAGE = os.path.expanduser("~/kbuild/linux-main/arch/arm64/boot/Image")
PRIMARY = 0x429038
SLOT_A = 0x600000
SLOT_B = 0xFA0000


def branch(at, dst):
    disp = dst - at
    assert disp % 4 == 0
    imm = disp // 4
    assert -(1 << 25) <= imm < (1 << 25), "out of range"
    return struct.pack("<I", 0x14000000 | (imm & 0x3FFFFFF))


tramp = bytearray(open(os.path.join(OUT, "tramp.bin"), "rb").read())
assert tramp[-4:] == b"\x00\x00\x00\x00", "placeholder missing"
body = tramp[:-4]                       # paint + hold, ends before the branch

img = bytearray(open(IMAGE, "rb").read())
assert len(img) < SLOT_A

img[0:4] = struct.pack("<I", 0x91005a4d)      # MZ disguise, harmless
img[4:8] = branch(4, SLOT_A)
img[0x08:0x10] = struct.pack("<Q", 0x80000)
img[0x10:0x18] = struct.pack("<Q", SLOT_B + 4)

out = bytearray(img) + b"\x00" * (SLOT_A - len(img))
out += body
out += branch(SLOT_A + len(body), PRIMARY)
out += b"\x00" * (SLOT_B - len(out))
out += branch(SLOT_B, PRIMARY)

with open(os.path.join(OUT, "kernel-dual.bin"), "wb") as f:
    f.write(bytes(out))

for name, addr in (("code1", 4), ("A branch", SLOT_A + len(body)), ("B branch", SLOT_B)):
    w = struct.unpack("<I", bytes(out[addr:addr + 4]))[0]
    imm = w & 0x3FFFFFF
    if imm & (1 << 25):
        imm -= (1 << 26)
    print("%-10s @+%#08x  word %#010x  -> +%#x" % (name, addr, w, addr + imm * 4))
print("blob %d bytes, total %#x, image_size %#x" % (len(body) + 4, len(out), SLOT_B + 4))
