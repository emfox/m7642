#!/usr/bin/env python3
"""Wrap the freshly built 4.19 Image and graft three colour rungs onto it.

The board has no usable text console for this kernel -- SERIAL_8250 is off and
the vendor framebuffer driver lives in the part of drivers/mstar2/ that was
never published -- so the only output channel is the panel, exactly as it was
for the mainline ladder.  Three checkpoints separate the three hypotheses that
matter:

    cyan    code1 was taken, so the bootloader loaded and jumped into a kernel
            built from the vendor 4.19 source and nothing else
    orange  stext ran to completion: preserve_boot_args, el2_setup,
            __create_page_tables and __cpu_setup all returned, which is the
            range the 7.3 ladder dies in (its +0x465ef0 never paints)
    green   __primary_switched reached the `b start_kernel`, i.e. the MMU is on
            and the kernel is about to enter C

Reading rules, from the mainline bring-up: only a flat full-screen colour
counts.  Bars and stripes have come out shredded before.  Orange sitting on the
panel means the kernel got at least that far and then stopped somewhere we
cannot see -- there is no console to say where.

Every assertion here has cost a flash before:

  * image_size and the boot header's kernel_size must both cover the rungs,
    because that is the field the bootloader copies by;
  * the rungs must not touch x0..x5 (handover state) or x21/x23 (FDT pointer,
    KASLR offset) -- ladder.S only uses x7..x19;
  * nothing outside the rungs, code1, the two patched branches and image_size
    may differ from the plain Image.
"""
import os
import struct
import subprocess

IMAGE = os.environ.get("IMAGE") or os.path.expanduser(
    "~/kbuild/tcl-419/arch/arm64/boot/Image")
SYSMAP = os.environ.get("SYSMAP") or os.path.expanduser(
    "~/kbuild/tcl-419/System.map")
OUT = os.path.expanduser("~/kbuild/m7642-out")
HERE = os.path.dirname(os.path.abspath(__file__))
RUNG = os.environ.get("RUNG") or os.path.join(
    HERE, "..", "..", "probes", "ladder", "blue.bin")
SRC = os.environ.get("SRC") or os.path.expanduser(
    "~/kbuild/rec/recovery_full.bin")
TAG = os.environ.get("TAG", "m7642-419-rung0.img")

# mboot ignores the Image header's text_offset and copies the image to the
# address the factory recovery header itself names (kernel_addr at offset 12).
BASE = 0x20280000
END_MARK = 0x4D373645			# "M76E", last word of a rung blob
# 0xffff is white: as ARGB8888 it is A=R=G=B=ff, as RGB565 it is two 0xffff
# pixels.  It is the only value that reads as white under either interpretation,
# and no bootloader draws a plain white screen, so "the panel went white" is
# real evidence that our fill reached the panel.  The old 0x07ff was chosen as
# RGB565 cyan but shows as magenta once read as 32bpp -- which is exactly what
# has been on the panel, and is indistinguishable from stale buffer contents.
CYAN = 0xFFFF
ORANGE = int(os.environ.get("ORANGE", "0xFC00"), 16)
GREEN = int(os.environ.get("GREEN", "0x07E0"), 16)


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


def rung(at, colour, dst, step, halt=False):
    """Copy the rung blob to file offset `at`, recolour it, retarget its tail."""
    b = bytearray(open(RUNG, "rb").read())
    assert struct.unpack("<I", b[-4:])[0] == END_MARK, "rung missing end mark"
    patched = 0
    steps = 0
    for i in range(0, len(b) - 8, 4):
        w = struct.unpack("<I", b[i:i + 4])[0]
        if (w & 0xFFE0001F) == 0x5280000F:		# movz w15, #imm16
            b[i:i + 4] = struct.pack("<I", 0x5280000F | ((colour & 0xFFFF) << 5))
            patched += 1
        elif (w & 0xFFE0001F) == 0x72A0000F:		# movk w15, #imm16, lsl #16
            b[i:i + 4] = struct.pack("<I", 0x72A0000F | ((colour & 0xFFFF) << 5))
            patched += 1
        elif (w & 0xFFE0001F) == 0x52800013:		# movz w19, #imm16 (STEP)
            # The DRAM mark at 0x43300000 stores STEP and its complement, so
            # each rung must carry a distinct one: that is what turns the
            # screen-free readout into a level, not just an "it ran".
            b[i:i + 4] = struct.pack("<I", 0x52800013 | ((step & 0xFFFF) << 5))
            steps += 1
    assert patched == 2, "expected 2 colour immediates, patched %d" % patched
    assert steps == 1, "expected 1 STEP immediate, patched %d" % steps
    tail = len(b) - 8
    if halt:
        # A HALT build ends in `b .`; rewriting that word would turn the
        # deliberate stop into a branch, which is the one thing it must not do.
        imm = struct.unpack("<I", b[tail:tail + 4])[0]
        assert (imm & 0xFC000000) == 0x14000000, "HALT build does not end in b"
        assert target(imm, at + tail) == at + tail, "HALT branch is not self"
    else:
        b[tail:tail + 4] = branch(at + tail, dst)	# at+dst are file offsets here
        assert target(struct.unpack("<I", b[tail:tail + 4])[0], at + tail) == dst
    return bytes(b)


def find_branch(img, lo, hi, dst):
    """Find the `b dst` in [lo,hi) and return its file offset."""
    want = branch(0, dst)
    # branch() is position independent only for a fixed displacement, so
    # compare against a displacement built at each candidate.
    hits = [i for i in range(lo, hi, 4)
            if struct.unpack("<I", img[i:i + 4])[0] ==
            struct.unpack("<I", branch(i, dst))[0]]
    assert len(hits) == 1, "expected one branch to %#x in [%#x,%#x), got %s" % (
        dst, lo, hi, [hex(h) for h in hits])
    return hits[0]


def main():
    text = symbol("_text")
    stext = symbol("stext")
    switched = symbol("__primary_switched")
    start_kernel = symbol("start_kernel")
    off = lambda s: s - text
    print("stext +%#x  __primary_switched +%#x  start_kernel +%#x"
          % (off(stext), off(switched), off(start_kernel)))

    img = bytearray(open(IMAGE, "rb").read())
    text_off, image_size = struct.unpack("<QQ", img[8:24])
    print("Image %d bytes, text_offset %#x, image_size %#x, magic %r"
          % (len(img), text_off, image_size, bytes(img[56:60])))
    assert img[56:60] == b"ARM\x64", "not an arm64 Image"
    assert text_off == 0x80000, "text_offset changed: %#x" % text_off

    a = (len(img) + 15) & ~15
    blob_len = len(open(RUNG, "rb").read())
    step = (blob_len + 15) & ~15
    o = a + step
    g = o + step
    halt = os.environ.get("HALT") == "1"
    ra = rung(a, CYAN, off(stext), 1, halt)
    ro = rung(o, ORANGE, off(symbol("__primary_switch")), 2, halt)
    rg = rung(g, GREEN, off(start_kernel), 3, halt)
    kernel = bytearray(bytes(img) + b"\x00" * (a - len(img)) + ra +
                       b"\x00" * (step - len(ra)) + ro +
                       b"\x00" * (step - len(ro)) + rg)

    # stext's last instruction is `b __primary_switch`; divert it.
    ps = find_branch(img, off(stext), off(stext) + 0x200,
                     off(symbol("__primary_switch")))
    # __primary_switched ends with `b start_kernel`; divert that too.
    sk = find_branch(img, off(switched), off(switched) + 0x400, off(start_kernel))
    print("diverting stext+%#x and __primary_switched+%#x"
          % (ps - off(stext), sk - off(switched)))

    kernel[ps:ps + 4] = branch(ps, o)
    kernel[sk:sk + 4] = branch(sk, g)

    # code1 now enters the cyan rung.
    assert struct.unpack("<I", kernel[0:4])[0] == 0x91005A4D, "code0 is not MZ"
    kernel[4:8] = branch(4, a)
    struct.pack_into("<Q", kernel, 16, len(kernel))
    assert struct.unpack("<Q", kernel[16:24])[0] == len(kernel)
    # mboot copies exactly kernel_size bytes, so a rung that spills past the
    # end would be silently truncated on the device rather than failing here.
    assert g + blob_len <= len(kernel), \
        "last rung ends at %#x, past kernel_size %#x" % (g + blob_len, len(kernel))
    print("kernel %d bytes, rungs at +%#x/+%#x/+%#x (step %#x, blob %d)"
          % (len(kernel), a, o, g, step, blob_len))

    plain = bytearray(bytes(img) + b"\x00" * (a - len(img)) + b"\x00" * (3 * step))
    allowed = set(range(4, 8)) | set(range(16, 24))
    allowed |= set(range(a, a + step)) | set(range(o, o + step))
    allowed |= set(range(g, g + step)) | set(range(ps, ps + 4))
    allowed |= set(range(sk, sk + 4))
    stray = [i for i in range(len(kernel))
             if kernel[i] != plain[i] and i not in allowed]
    assert not stray, "modified bytes outside the rungs: %s" % [hex(i) for i in stray[:8]]
    print("changes confined to the rungs, code1, two branches and image_size")

    src = open(SRC, "rb").read()
    page = struct.unpack("<I", src[36:40])[0]
    orig_ks = struct.unpack("<I", src[8:12])[0]
    ramdisk_size = struct.unpack("<I", src[16:20])[0]
    ramdisk_at = page + ((orig_ks + page - 1) // page) * page
    ramdisk = src[ramdisk_at:ramdisk_at + ramdisk_size]
    assert len(ramdisk) == ramdisk_size, "short ramdisk at %#x" % ramdisk_at

    hdr = bytearray(src[:page])
    struct.pack_into("<I", hdr, 8, len(kernel))

    def pad(d):
        rem = len(d) % page
        return d if not rem else d + b"\x00" * (page - rem)

    out = bytes(hdr) + pad(bytes(kernel)) + pad(ramdisk)
    # The recovery partition is 65536 sectors of 512 bytes; mboot has no
    # fallback if the image does not fit.
    assert len(out) <= 65536 * 512, "image does not fit in the recovery slot"
    os.makedirs(OUT, exist_ok=True)
    path = os.path.join(OUT, TAG)
    open(path, "wb").write(out)
    print("wrote %s  %d bytes (slot %d)" % (path, len(out), 65536 * 512))
    print(subprocess.run(["md5sum", path], capture_output=True, text=True).stdout.strip())


if __name__ == "__main__":
    main()
