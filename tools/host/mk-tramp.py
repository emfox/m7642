#!/usr/bin/env python3
"""Build the +0xFA0000 trampoline image.

The bootloader starts the image at +0xFA0000, not +0, so everything that was
placed at the start of the Image was dead code.  This pads the Image out to
0xFA0000, drops in a blob that steers GOP0, commits with GOP_FWR, floods a
colour and holds for two seconds, and finishes with a branch back to
primary_entry so the kernel actually runs.
"""
import struct
import os

OUT = os.path.expanduser("~/Debian/m7642-build/out")
IMAGE = os.path.expanduser("~/Debian/m7642-build/kernel/linux-main/arch/arm64/boot/Image")
SLOT = 0xFA0000
PRIMARY = 0x429038           # primary_entry, from System.map

tramp = bytearray(open(os.path.join(OUT, "tramp.bin"), "rb").read())
assert tramp[-4:] == b"\x00\x00\x00\x00", "placeholder missing"

# branch from the last word of the blob back to primary_entry
b_at = SLOT + len(tramp) - 4
disp = PRIMARY - b_at
assert disp % 4 == 0
imm = disp // 4
assert -(1 << 25) <= imm < (1 << 25), "out of branch range"
tramp[-4:] = struct.pack("<I", 0x14000000 | (imm & 0x3FFFFFF))

img = bytearray(open(IMAGE, "rb").read())
assert len(img) < SLOT, "Image already runs past the slot"

img[0x08:0x10] = struct.pack("<Q", 0x80000)          # text_offset, vendor value
img[0x10:0x18] = struct.pack("<Q", SLOT + len(tramp))  # image_size

out = bytearray(img) + b"\x00" * (SLOT - len(img)) + tramp
with open(os.path.join(OUT, "kernel-tramp.bin"), "wb") as f:
    f.write(bytes(out))

print("b at +%#x  disp %#x  imm %#x  word %#010x" %
      (b_at, disp, imm, 0x14000000 | (imm & 0x3FFFFFF)))
print("tramp %d bytes  total %#x  image_size %#x" %
      (len(tramp), len(out), SLOT + len(tramp)))
print("slot head:", bytes(out[SLOT:SLOT + 16]).hex(" "))
