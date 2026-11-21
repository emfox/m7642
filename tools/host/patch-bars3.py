#!/usr/bin/env python3
"""Insert rung4 at __pi_create_init_idmap's first instruction.

Same probe as patch-bars2.py, relocated.  The old site, +0x600200, sits in the
kernel bss tail; two runs in a row painted nothing there, while the inline
checkpoints in head.S (same paint routine) do reach the panel.  So the rung
never ran, and the dot grid on screen was never ours.

The new site, +0x4a7000, is a real zero hole in the image that ends just below
__pi_init_idmap_pg_dir, inside the first range the kernel maps.  The patcher
refuses to write there unless those bytes are still empty.

The reading is a bar count on a white field, not a hue:

	one bar    the stp faulted, the initial stack is not writable
	two bars   the stp succeeded, the stack is fine

Everything is checked by disassembling the result, not by trusting the patch.
"""
import os
import struct
import subprocess
import sys

OBJDUMP = os.path.expanduser("~/kbuild/toolchain-gcc13/bin/aarch64-buildroot-linux-gnu-objdump")
RUNG = os.path.expanduser("~/kbuild/ciim/rung4.bin")
PAGE = 0x800			# boot image header page, kernel starts after it

KERNEL_AT = 0x465e5c		# __pi_create_init_idmap
RUNG_AT = 0x4A7000		# zero hole just below __pi_init_idmap_pg_dir
REJOIN = 0x465e70		# add x29, sp, #0x10

EXPECT_ORIG = 0xD10143FF	# sub sp, sp, #0x50
EXPECT_LEN = 172

MOVK_CTRL = 0xF2A3E48A		# +0x18  movk x10, #0x1f24, lsl 16
STRH_CTRL = 0x7900014B		# +0x2c  strh w11, [x10]
BL_BEACON = 0x97EDE63B		# +0x34  bl 0x20920
STP_TESTED = 0xA9017BFD		# +0x40  stp x29, x30, [sp, #16]
B_CONT = 0x17FEFB85		# +0x5c  b 0x465e70


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
    assert words[6] == MOVK_CTRL, "ctrl address moved (got %08x)" % words[6]
    assert words[11] == STRH_CTRL, "no ctrl write (got %08x)" % words[11]
    assert words[13] == BL_BEACON, "no beacon call (got %08x)" % words[13]
    assert words[16] == STP_TESTED, "stp under test moved (got %08x)" % words[16]
    assert words[23] == B_CONT, "no rejoin to +%#x (got %08x)" % (REJOIN, words[23])

    dst = PAGE + RUNG_AT
    if any(img[dst:dst + len(rung)]):
        sys.exit("destination +%#x is not empty -- refusing to clobber code" % RUNG_AT)
    img[dst:dst + len(rung)] = rung
    img[off:off + 4] = branch(KERNEL_AT, RUNG_AT)

    out = path.replace(".img", "-bars4.img")
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
