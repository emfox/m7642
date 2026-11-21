#!/usr/bin/env python3
"""Insert a checkpoint into __pi_create_init_idmap's first instruction.

The panel stops on green, which head.S paints immediately before calling
__pi_create_init_idmap, and never reaches 0x4210, the first mark inside it.
Between those two points the compiler emits its own prologue: four stores to
the initial stack and one load of arm64_use_ng_mappings.  So the kernel dies in
code that no source-level mark can sit in front of.

This rewrites the function's first instruction to a branch into a small blob
that replays the original prologue, paints 0x7c00, and rejoins at +0x465e70.
The blob lives at +0x600200, clear of the old code1 rung at +0x600000.

Reading:
	0x7c00  dark red    the body was entered and the initial stack is writable
	0x4210  dull violet  the prologue completed, died in the text map_range
	0x8410  mid grey     the text range is mapped, died in the data map_range
	0xffe0  yellow       the whole function returned
	0x07e0  bright green never even entered the function

Everything is verified by disassembling the result, not by trusting the patch.
"""
import os
import struct
import subprocess
import sys

OBJDUMP = os.path.expanduser("~/kbuild/toolchain-gcc13/bin/aarch64-buildroot-linux-gnu-objdump")
RUNG = os.path.expanduser("~/kbuild/ciim/rung.bin")
PAGE = 0x800			# boot image header page, kernel starts after it

KERNEL_AT = 0x465e5c		# __pi_create_init_idmap
RUNG_AT = 0x600200		# must not collide with the old rung at 0x600000
REJOIN = 0x465e70		# add x29, sp, #0x10

EXPECT_ORIG = 0xD10143FF	# sub sp, sp, #0x50


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

    # The blob must still be the code we assembled, or the reading means nothing.
    assert len(rung) == 32, "unexpected blob length %d" % len(rung)
    words = [struct.unpack_from("<I", rung, i)[0] for i in range(0, 32, 4)]
    assert words[5] == 0x528F800C, "blob does not paint 0x7c00 (got %08x)" % words[5]
    assert words[6] == 0x97E881C2, "blob does not call the beacon (got %08x)" % words[6]
    assert words[7] == 0x17F99715, "blob does not rejoin at +%#x (got %08x)" % (REJOIN, words[7])

    img[PAGE + RUNG_AT:PAGE + RUNG_AT + len(rung)] = rung
    img[off:off + 4] = branch(KERNEL_AT, RUNG_AT)

    out = path.replace(".img", "-ciim.img")
    open(out, "wb").write(img)
    print("wrote %s" % out)

    # Read back through a disassembler rather than trusting the bytes.
    with open(out + ".k", "wb") as f:
        f.write(img[PAGE + KERNEL_AT - 8:PAGE + KERNEL_AT + 0x20])
    text = subprocess.run(
        [OBJDUMP, "-D", "-b", "binary", "-m", "aarch64",
         "--adjust-vma=%#x" % (KERNEL_AT - 8), out + ".k"],
        capture_output=True, text=True).stdout
    print(text.strip().split("\n", 4)[-1])
    os.unlink(out + ".k")

    with open(out + ".r", "wb") as f:
        f.write(img[PAGE + RUNG_AT:PAGE + RUNG_AT + 32])
    text = subprocess.run(
        [OBJDUMP, "-D", "-b", "binary", "-m", "aarch64",
         "--adjust-vma=%#x" % RUNG_AT, out + ".r"],
        capture_output=True, text=True).stdout
    print(text.strip().split("\n", 4)[-1])
    os.unlink(out + ".r")

    print(subprocess.run(["md5sum", out], capture_output=True, text=True).stdout.strip())


if __name__ == "__main__":
    main(sys.argv[1] if len(sys.argv) > 1 else
         os.path.expanduser("~/kbuild/m7642-out/m7642-ladder9.img"))
