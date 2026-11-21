#!/usr/bin/env python3
"""Pack the mainline Image into a three-rung entry ladder.

The board has produced two mutually exclusive stories about how the bootloader
starts an image, and five past builds agree only on one thing: an image whose
code1 was redirected to a blob of ours did execute that blob.  So instead of
betting on one rule, this image satisfies all of them at once and colours each
rung differently:

    +0x600000  blue    reached via code1
    +0xF9FF00  yellow  reached via +0xFA0000 (the vendor entry offset)
    kernel beacon      white -> red -> green

Every rung then branches to primary_entry, whose own beacon reports how far the
kernel itself got.  The colour left on the panel names the furthest rung.

Three things are asserted rather than assumed, because each has caused a wrong
conclusion in this bring-up already:

  * kernel_size and image_size are equal and cover every rung, because a
    six-megabyte kernel_size was what stopped the bootloader copying the code
    we expected it to run;
  * image_size covers +0xFA0000, since the ramdisk offset is derived from it;
  * the blobs change no register the bootloader used to hand over -- x0 is the
    DTB pointer and the previous probe destroyed it.
"""
import os
import struct
import subprocess
import sys

OUT = os.path.expanduser("~/kbuild/m7642-out")
IMAGE = os.path.expanduser("~/kbuild/linux-main/arch/arm64/boot/Image")
SYSMAP = os.path.expanduser("~/kbuild/linux-main/System.map")
SRC = os.path.expanduser("~/kbuild/rec/recovery_full.bin")
HERE = os.path.dirname(os.path.abspath(__file__))
# BLUE/YELLOW point at a different pair when the rung was assembled with
# -DHALT=1: that build loops forever after the fill, so its trailing branch to
# primary_entry is dead code.  Packing still needs it (the rung layout and the
# end mark are unchanged), it just never executes.
BLUE = os.environ.get("BLUE") or os.path.join(HERE, "..", "..", "probes", "ladder", "blue.bin")
YELLOW = os.environ.get("YELLOW") or os.path.join(HERE, "..", "..", "probes", "ladder", "yellow.bin")
TAG = os.environ.get("TAG", "m7642-ladder.img")

CODE1_AT = 0x600000
FA_AT = 0xF9FE00			# runs when +0xFA0000 is redirected here; 512 bytes
VENDOR_ENTRY = 0xFA0000
KERNEL_SIZE = 0xFA0100			# covers every rung, 256-byte aligned
END_MARK = 0x4D373645			# "M76E", last word of each blob


def symbol(name):
    for line in open(SYSMAP):
        parts = line.split()
        if len(parts) == 3 and parts[2] == name:
            return int(parts[0], 16) & 0xFFFFFFFFFFFF
    raise SystemExit("symbol %s not found" % name)


def branch(at, dst):
    disp = dst - at
    assert disp % 4 == 0, "unaligned branch %#x -> %#x" % (at, dst)
    imm = disp // 4
    assert -(1 << 25) <= imm < (1 << 25), "branch out of range"
    return struct.pack("<I", 0x14000000 | (imm & 0x3FFFFFF))


def target(word, at):
    imm = word & 0x3FFFFFF
    if imm & (1 << 25):
        imm -= 1 << 26
    return at + imm * 4


def rung(path, at, primary):
    """Return the blob with its trailing placeholder turned into b primary."""
    b = bytearray(open(path, "rb").read())
    assert struct.unpack("<I", b[-4:])[0] == END_MARK, "%s missing end mark" % path
    struct.pack_into("<I", b, len(b) - 8, struct.unpack("<I", branch(at + len(b) - 8, primary))[0])
    got = struct.unpack("<I", b[len(b) - 8:len(b) - 4])[0]
    assert target(got, at + len(b) - 8) == primary, "%s does not reach primary" % path
    return bytes(b)


text = symbol("_text")
primary = symbol("primary_entry") - text
print("primary_entry at +%#x" % primary)

img = bytearray(open(IMAGE, "rb").read())
text_off, image_size = struct.unpack("<QQ", img[8:24])
print("Image %d bytes, text_offset %#x, image_size %#x" % (len(img), text_off, image_size))
assert len(img) <= CODE1_AT, "Image overlaps the +0x600000 rung"

blue = rung(BLUE, CODE1_AT, primary)
yellow = rung(YELLOW, FA_AT, primary)
print("blue rung %d bytes at +%#x, yellow rung %d bytes" % (len(blue), CODE1_AT, len(yellow)))
assert FA_AT + len(yellow) <= VENDOR_ENTRY, "yellow rung runs into the vendor entry"

kernel = img + b"\x00" * (KERNEL_SIZE - len(img))
kernel[CODE1_AT:CODE1_AT + len(blue)] = blue
kernel[FA_AT:FA_AT + len(yellow)] = yellow

# The vendor's own entry is at +0xFA0000; if the bootloader goes there, send it
# to the yellow rung instead of into our zero padding.
struct.pack_into("<I", kernel, VENDOR_ENTRY, struct.unpack("<I", branch(VENDOR_ENTRY, FA_AT))[0])

# code1 must reach the blue rung: the one rule five builds agree on.
struct.pack_into("<I", kernel, 4, struct.unpack("<I", branch(4, CODE1_AT))[0])

kernel_size = len(kernel)
struct.pack_into("<Q", kernel, 16, kernel_size)

# --- read back -----------------------------------------------------------
c1 = struct.unpack("<I", kernel[4:8])[0]
assert target(c1, 4) == CODE1_AT, "code1 does not reach the blue rung"
fa = struct.unpack("<I", kernel[VENDOR_ENTRY:VENDOR_ENTRY + 4])[0]
assert target(fa, VENDOR_ENTRY) == FA_AT, "+0xFA0000 does not reach the yellow rung"
assert struct.unpack("<Q", kernel[16:24])[0] == kernel_size
print("code1 %#010x -> +%#x" % (c1, CODE1_AT))
print("+0xFA0000 %#010x -> +%#x" % (fa, FA_AT))
print("kernel_size == image_size == %#x" % kernel_size)

# Nothing outside the three intended spots may differ from the padded Image.
base = img + b"\x00" * (KERNEL_SIZE - len(img))
allowed = set(range(CODE1_AT, CODE1_AT + len(blue)))
allowed |= set(range(FA_AT, FA_AT + len(yellow)))
allowed |= set(range(VENDOR_ENTRY, VENDOR_ENTRY + 4))
allowed |= set(range(4, 8))		# code1
allowed |= set(range(16, 24))		# image_size
stray = [i for i in range(KERNEL_SIZE) if kernel[i] != base[i] and i not in allowed]
assert not stray, "modified bytes outside the rungs: %s" % [hex(i) for i in stray[:8]]
print("changes confined to the three rungs")

# --- wrap in the vendor boot image -----------------------------------------
src = open(SRC, "rb").read()
page = struct.unpack("<I", src[36:40])[0]
orig_ks = struct.unpack("<I", src[8:12])[0]
ramdisk_size = struct.unpack("<I", src[16:20])[0]
ramdisk_at = page + ((orig_ks + page - 1) // page) * page
ramdisk = src[ramdisk_at:ramdisk_at + ramdisk_size]
assert len(ramdisk) == ramdisk_size, "short ramdisk at %#x" % ramdisk_at
assert struct.unpack("<I", src[8:12])[0] == orig_ks

hdr = bytearray(src[:page])
struct.pack_into("<I", hdr, 8, kernel_size)


def pad(d):
    rem = len(d) % page
    return d if not rem else d + b"\x00" * (page - rem)


out = bytes(hdr) + pad(bytes(kernel)) + pad(ramdisk)
path = os.path.join(OUT, TAG)
open(path, "wb").write(out)
print("wrote %s  %d bytes" % (path, len(out)))
print(subprocess.run(["md5sum", path], capture_output=True, text=True).stdout.strip())
