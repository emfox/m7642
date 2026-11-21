#!/usr/bin/env python3
"""Insert rung6 over the __pi_create_init_idmap prologue.

Base is the untouched ladder9 image, so the inline checkpoints stay as they are:
white (0xffff) -> red (0xf800) -> green (0x07e0) still paint before this rung,
and whatever colour the rung leaves behind is the readout.

Only two things change: the word at +0x465e5c, and the rung at +0xf9f000.
"""
import hashlib
import os
import struct
import sys

OUT = os.path.expanduser("~/kbuild/m7642-out/m7642-ladder9-ciim2.img")
BASE = os.path.expanduser("~/kbuild/m7642-out/m7642-ladder9.img")
RUNG = os.path.expanduser("~/kbuild/ciim/rung6.bin")
PAGE = 0x800
KERNEL_AT = 0x465E5C
RUNG_AT = 0xF9F000
EXPECT_ORIG = 0xD10143FF		# sub sp, sp, #0x50
EXPECT_LEN = 52


def branch(at, dst):
	disp = dst - at
	assert disp % 4 == 0, "unaligned branch"
	imm = disp // 4
	assert -(1 << 25) <= imm < (1 << 25), "branch out of range"
	return 0x14000000 | (imm & 0x3FFFFFF)


def target(word, at):
	imm = word & 0x3FFFFFF
	if imm & (1 << 25):
		imm -= 1 << 26
	return at + imm * 4


img = bytearray(open(BASE, "rb").read())
base_md5 = hashlib.md5(img).hexdigest()
print("base  %d bytes  md5 %s" % (len(img), base_md5))
assert base_md5 == "7090e41c1f1fbb62ca8ea13fac6ee10d", "unexpected base image"

rung = open(RUNG, "rb").read()
assert len(rung) == EXPECT_LEN, "rung is %d bytes, expected %d" % (len(rung), EXPECT_LEN)

at = PAGE + KERNEL_AT
orig = struct.unpack_from("<I", img, at)[0]
assert orig == EXPECT_ORIG, "expected %#010x at +%#x, found %#010x" % (EXPECT_ORIG, KERNEL_AT, orig)

dst = PAGE + RUNG_AT
if any(img[dst:dst + len(rung)]):
	sys.exit("destination +%#x is not empty" % RUNG_AT)
if RUNG_AT + len(rung) > 0xFA0000:
	sys.exit("rung would run into the vendor entry")

img[dst:dst + len(rung)] = rung
br = branch(KERNEL_AT, RUNG_AT)
struct.pack_into("<I", img, at, br)
print("patch +%#x  %#010x -> %#010x (b +%#x)" % (KERNEL_AT, orig, br, RUNG_AT))
print("rung  +%#x  %d bytes" % (RUNG_AT, len(rung)))

# read back
got = struct.unpack_from("<I", img, at)[0]
assert got == br and target(got, KERNEL_AT) == RUNG_AT, "branch does not reach the rung"
assert img[dst:dst + len(rung)] == rung, "rung not stored verbatim"

open(OUT, "wb").write(img)
print("wrote %s  %d bytes  md5 %s" % (OUT, len(img), hashlib.md5(img).hexdigest()))
