#!/usr/bin/env python3
"""Wrap the mainline Image so the bootloader entry lands on primary_entry.

The factory hook proved the bootloader enters at +0xFA0000.  The vendor stub
sitting there does more than branch: its first useful act is to put the dtb
address (0x23000000, where `bootcmd` loads the dtb partition) into x0 before
handing over.  Jumping straight to primary_entry drops that, so reproduce it:

    +0x000000  the mainline Image, unmodified
    +0xFA0000  mov x0, #0x23000000
    +0xFA0004  b primary_entry

Both possible entry points still work: entry at +0 reads Image code1 (the
linker's own branch to primary_entry), entry at +0xFA0000 runs the two words.

kernel_size stops at +0xFA0008, which keeps the kernel below ramdisk_addr
(0x21280000): 0x20280000 + 0xFA0008 = 0x21220008.
"""
import os
import struct
import subprocess

OUT = os.path.expanduser("~/Debian/m7642-build/out")
IMAGE = os.path.expanduser("~/Debian/m7642-build/kernel/linux-main/arch/arm64/boot/Image")
SYSMAP = os.path.expanduser("~/Debian/m7642-build/kernel/linux-main/System.map")
SRC = os.path.expanduser("~/Debian/m7642-build/backups/partitions/rec/recovery_full.bin")
TAG = os.environ.get("TAG", "probe-mainline.img")
ENTRY = 0xFA0000
MOV_X0_DTB = struct.pack("<I", 0xD2A46000)	# mov x0, #0x23000000


def symbol(name):
    for line in open(SYSMAP):
        parts = line.split()
        if len(parts) == 3 and parts[2] == name:
            return int(parts[0], 16) & 0xFFFFFFFFFFFF
    raise SystemExit("symbol %s not found" % name)


def branch(at, dst):
    disp = dst - at
    assert disp % 4 == 0
    imm = disp // 4
    assert -(1 << 25) <= imm < (1 << 25), "out of range"
    return struct.pack("<I", 0x14000000 | (imm & 0x3FFFFFF))


def target(word, at):
    imm = word & 0x3FFFFFF
    if imm & (1 << 25):
        imm -= 1 << 26
    return at + imm * 4


text = symbol("_text")
primary = symbol("primary_entry") - text
print("primary_entry at +%#x" % primary)

img = open(IMAGE, "rb").read()
assert len(img) < ENTRY, "Image does not fit below the entry stub"

kernel = bytearray(img) + b"\x00" * (ENTRY - len(img))
kernel += MOV_X0_DTB + branch(ENTRY + 4, primary)
kernel_size = len(kernel)

# Read back both paths.
code1 = struct.unpack("<I", kernel[4:8])[0]
assert target(code1, 4) == primary, "Image code1 does not reach primary_entry"
mov = struct.unpack("<I", kernel[ENTRY:ENTRY + 4])[0]
assert mov == 0xD2A46000, "dtb load is not mov x0, #0x23000000"
stub = struct.unpack("<I", kernel[ENTRY + 4:ENTRY + 8])[0]
assert target(stub, ENTRY + 4) == primary, "entry stub does not reach primary_entry"
print("code1 %#010x -> +%#x" % (code1, target(code1, 4)))
print("stub  %#010x mov x0,#0x23000000 ; %#010x -> +%#x"
      % (mov, stub, target(stub, ENTRY + 4)))

hdr = bytearray(open(SRC, "rb").read(2048))
main = bytearray(open(SRC, "rb").read())
page = struct.unpack("<I", main[36:40])[0]
ramdisk_size = struct.unpack("<I", main[16:20])[0]
ramdisk = main[page + struct.unpack("<I", main[8:12])[0]:][:ramdisk_size]
assert len(ramdisk) == ramdisk_size

struct.pack_into("<I", hdr, 8, kernel_size)


def pad(data):
    rem = len(data) % page
    return data if rem == 0 else data + b"\x00" * (page - rem)


out = pad(bytes(hdr)) + pad(bytes(kernel)) + pad(ramdisk)
path = os.path.join(OUT, TAG)
open(path, "wb").write(out)
print("kernel %#x, ramdisk %#x, image %d bytes" % (kernel_size, ramdisk_size, len(out)))
print("kernel end %#x (ramdisk_addr 0x21280000)" % (0x20280000 + kernel_size))
print(subprocess.run(["md5sum", path], capture_output=True, text=True).stdout.strip())
