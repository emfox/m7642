#!/usr/bin/env python3
"""Pack a minimal probe at +0x600000, the address proved to execute here.

The dual2 blob painted the whole panel from +0x600000, so that offset is known
good.  This image puts a 28-byte probe there which writes 0xAA55 into the PM
wakeup-source word and halts.  0xAA55 is chosen because no hardware default
would plausibly be that value, so a reading of it proves the write really
happened -- something the constant reading of 1 has never established.

Layout mirrors dual2 exactly otherwise: code0 gets the same harmless MZ
disguise, code1 branches to the probe, and image_size is kept equal to
kernel_size so the two header fields cannot disagree.
"""
import os
import struct
import subprocess

OUT = os.path.expanduser("~/kbuild/m7642-out")
IMAGE = os.path.expanduser("~/kbuild/linux-main/arch/arm64/boot/Image")
SRC = os.path.expanduser("~/kbuild/rec/recovery_full.bin")
PROBE = os.path.expanduser("~/Debian/m7642/probes/mark600/probe.bin")
TAG = os.environ.get("TAG", "probe-mark600.img")
PROBE_AT = 0x600000
CODE0 = 0x91005a4d          # "MZ" + add x13,x18,#0x16, harmless; same as dual2

kernel = bytearray(open(IMAGE, "rb").read())
probe = open(PROBE, "rb").read()
assert len(kernel) < PROBE_AT, "Image does not fit below the probe"

kernel = kernel + b"\x00" * (PROBE_AT - len(kernel)) + probe
struct.pack_into("<I", kernel, 0, CODE0)

imm = (PROBE_AT - 4) // 4
kernel[4:8] = struct.pack("<I", 0x14000000 | (imm & 0x3FFFFFF))
kernel_size = len(kernel)
struct.pack_into("<Q", kernel, 16, kernel_size)      # image_size == kernel_size

# read back
c0, c1 = struct.unpack("<2I", kernel[:8])
assert c0 == CODE0
tgt = 4 + ((c1 & 0x3FFFFFF) * 4 if not (c1 & 0x2000000) else ((c1 & 0x3FFFFFF) - (1 << 26)) * 4)
print("code0 %#010x  code1 %#010x -> +%#x" % (c0, c1, tgt))
assert tgt == PROBE_AT, "code1 does not reach the probe"
print("probe %d bytes at +%#x, image_size %#x" % (len(probe), PROBE_AT, kernel_size))

src = open(SRC, "rb").read()
hdr = bytearray(src[:2048])
page = struct.unpack("<I", src[36:40])[0]
ramdisk_size = struct.unpack("<I", src[16:20])[0]
ramdisk = src[page + struct.unpack("<I", src[8:12])[0]:][:ramdisk_size]
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
