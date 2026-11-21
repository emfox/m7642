#!/usr/bin/env python3
"""Insert the bar-counting probe at __pi_create_init_idmap's first instruction.

Replaces "sub sp, sp, #0x50" with a branch into rung2.bin, which paints a white
field with one black bar, performs the store under test, then paints two bars
and rejoins at +0x465e70.

The reading is a bar count, not a hue:

	one bar    the stp faulted, the initial stack is not writable
	two bars   the stp succeeded, the stack is fine

White (0xffffffff) and black (0xff000000) are the only two fill values that mean
the same thing under RGB565 and ARGB8888, so the count survives a format error.

Everything is checked by disassembling the result, not by trusting the patch.
"""
import os
import struct
import subprocess
import sys

OBJDUMP = os.path.expanduser("~/kbuild/toolchain-gcc13/bin/aarch64-buildroot-linux-gnu-objdump")
RUNG = os.path.expanduser("~/kbuild/ciim/rung2.bin")
PAGE = 0x800			# boot image header page, kernel starts after it

KERNEL_AT = 0x465e5c		# __pi_create_init_idmap
RUNG_AT = 0x600200		# clear of the dead code1 rung at 0x600000
REJOIN = 0x465e70		# add x29, sp, #0x10

EXPECT_ORIG = 0xD10143FF	# sub sp, sp, #0x50
EXPECT_LEN = 148

BL_BEACON = 0x97E881C2		# +0x18  bl 0x20920
STP_TESTED = 0xA9017BFD		# +0x24  stp x29, x30, [sp, #16]
B_CONT = 0x17F9970C		# +0x40  b 0x465e70


def branch(at, dst):
    disp = dst - at
    assert disp % 4 == 0, "unaligned branch %#x -> %#x" % (at, dst)
    imm = disp // 4
    assert -(1 << 25) <= imm < (1 << 25), "branch out of range"
    return struct.pack("<I", 0x14000000 | (imm & 0x3FFFFFF))


def main(path):
    img = bytearray(open(path, "rb").read())
    rung = open(RUNG, "rb").read()
    print("image %s  %d bytes" % (path, len(img)))
    print("blob  %d bytes at +%#x" % (len(rung), RUNG_AT))

    off = PAGE + KERNEL_AT
    orig = struct.unpack_from("<I", img, off)[0]
    if orig != EXPECT_ORIG:
        sys.exit("expected %08x at +%#x, found %08x -- wrong image?"
                 % (EXPECT_ORIG, KERNEL_AT, orig))

    assert len(rung) == EXPECT_LEN, "unexpected blob length %d" % len(rung)
    words = [struct.unpack_from("<I", rung, i)[0] for i in range(0, EXPECT_LEN, 4)]
    assert words[6] == BL_BEACON, "no beacon call (got %08x)" % words[6]
    assert words[9] == STP_TESTED, "stp under test moved (got %08x)" % words[9]
    assert words[16] == B_CONT, "no rejoin to +%#x (got %08x)" % (REJOIN, words[16])

    img[PAGE + RUNG_AT:PAGE + RUNG_AT + len(rung)] = rung
    img[off:off + 4] = branch(KERNEL_AT, RUNG_AT)

    out = path.replace(".img", "-bars.img")
    open(out, "wb").write(img)
    print("wrote %s" % out)

    with open(out + ".k", "wb") as f:
        f.write(img[PAGE + KERNEL_AT - 8:PAGE + KERNEL_AT + 0x18])
    print(subprocess.run(
        [OBJDUMP, "-D", "-b", "binary", "-m", "aarch64",
         "--adjust-vma=%#x" % (KERNEL_AT - 8), out + ".k"],
        capture_output=True, text=True).stdout.strip().split("\n", 4)[-1])
    os.unlink(out + ".k")

    with open(out + ".r", "wb") as f:
        f.write(img[PAGE + RUNG_AT:PAGE + RUNG_AT + EXPECT_LEN])
    print(subprocess.run(
        [OBJDUMP, "-D", "-b", "binary", "-m", "aarch64",
         "--adjust-vma=%#x" % RUNG_AT, out + ".r"],
        capture_output=True, text=True).stdout.strip().split("\n", 4)[-1])
    os.unlink(out + ".r")

    print(subprocess.run(["md5sum", out], capture_output=True, text=True).stdout.strip())


if __name__ == "__main__":
    main(sys.argv[1] if len(sys.argv) > 1 else
         os.path.expanduser("~/kbuild/m7642-out/m7642-ladder9.img"))
