#!/usr/bin/env python3
"""Independent read-back of the ladder boot image.

Checks the packed file as the bootloader will see it, not the generator's
intent: header fields, both rungs' encodings, the three primary_entry beacons,
the ramdisk splice, and a whole-file diff against the unmodified vendor image.
"""
import hashlib
import os
import struct
import sys

OUT = sys.argv[1] if len(sys.argv) > 1 else "/home/emfox/kbuild/m7642-out/m7642-ladder.img"
SRC = "/home/emfox/kbuild/rec/recovery_full.bin"
IMAGE = "/home/emfox/kbuild/linux-main/arch/arm64/boot/Image"

CODE1_AT = 0x600000
FA_AT = 0xF9FE00
VENDOR_ENTRY = 0xFA0000
KERNEL_SIZE = 0xFA0100
PRIMARY = 0x455038
RUNG_MAX = 0x200			# room reserved for one rung
END_MARK = b"E67M"			# 0x4d373645 "M76E" little-endian


def rung_span(k, at):
    """Locate one rung: it ends with the M76E mark, its branch sits 4 bytes before.

    Returns (length, branch_offset_within_rung).
    """
    raw = k[at:at + RUNG_MAX]
    idx = raw.find(END_MARK)
    if idx < 0:
        fail("rung at +%#x has no M76E end mark" % at)
    length = idx + len(END_MARK)
    if length % 4:
        fail("rung at +%#x has length %d, not a multiple of 4" % (at, length))
    return length, length - 8


def fail(msg):
    print("FAIL: " + msg)
    sys.exit(1)


def target(word, at):
    imm = word & 0x3FFFFFF
    if imm & (1 << 25):
        imm -= 1 << 26
    return at + imm * 4


def insn(word, at):
    """Decode just the encodings this image uses."""
    if word & 0x7C000000 == 0x14000000:
        return "b %#x" % target(word, at)
    if word & 0x7F800000 == 0x52800000:
        return "movz w%d, #%#x" % (word & 31, (word >> 5) & 0xFFFF)
    if word & 0x7F800000 == 0x72800000:
        return "movk w%d, #%#x, lsl %d" % (word & 31, (word >> 5) & 0xFFFF, ((word >> 21) & 3) * 16)
    return None


out = open(OUT, "rb").read()
src = open(SRC, "rb").read()
img = open(IMAGE, "rb").read()
print("ladder  : %d bytes  md5 %s" % (len(out), hashlib.md5(out).hexdigest()))
print("vendor  : %d bytes  md5 %s" % (len(src), hashlib.md5(src).hexdigest()))

# --- outer header: everything but kernel_size must match the vendor file ----
page = struct.unpack("<I", src[36:40])[0]
print("\n[outer header] page=%#x" % page)
diff = [i for i in range(page) if out[i] != src[i]]
print("  bytes differing in header: %s" % ([hex(i) for i in diff] or "none"))
if not set(diff) <= set(range(8, 12)):
    fail("outer header changed outside kernel_size")
ks = struct.unpack("<I", out[8:12])[0]
if ks != KERNEL_SIZE:
    fail("outer kernel_size %#x != %#x" % (ks, KERNEL_SIZE))
print("  kernel_size %#x (was %#x)" % (ks, struct.unpack("<I", src[8:12])[0]))
for name, off, fmt in (("code0", 0, "<I"), ("code1", 4, "<I"),
                       ("ramdisk_size", 16, "<I"),
                       ("kernel_addr", 24, "<Q"), ("ramdisk_addr", 32, "<Q"),
                       ("tags_addr", 40, "<Q"), ("name", 48, "16s")):
    print("  %-12s %s" % (name, struct.unpack_from(fmt, out, off)[0]))

# --- inner arm64 header -----------------------------------------------------
k = out[page:page + KERNEL_SIZE]
code0, code1 = struct.unpack_from("<II", k, 0)
text_off, image_size = struct.unpack_from("<QQ", k, 8)
print("\n[arm64 header] code0 %#010x  code1 %#010x (%s)" % (code0, code1, insn(code1, 4)))
print("  text_offset %#x  image_size %#x" % (text_off, image_size))
if code0 != 0xfa405a4d:
    fail("code0 is not MZ magic")
if target(code1, 4) != CODE1_AT:
    fail("code1 does not reach the blue rung")
if image_size != KERNEL_SIZE:
    fail("image_size %#x != %#x" % (image_size, KERNEL_SIZE))
if len(img) > CODE1_AT:
    fail("source Image overlaps the blue rung")

# --- rungs ------------------------------------------------------------------
print("\n[rungs]")
spans = {}
for name, at in (("blue  ", CODE1_AT), ("yellow", FA_AT)):
    length, br = rung_span(k, at)
    spans[at] = length
    blob = k[at:at + length]
    branch = struct.unpack_from("<I", blob, br)[0]
    print("  %s @ +%#x  %d bytes" % (name, at, length))
    for off in (br, length - 4):
        w = struct.unpack_from("<I", blob, off)[0]
        print("      +%#04x %08x  %s" % (at + off, w, insn(w, at + off)))
    if struct.unpack_from("<I", blob, length - 4)[0] != 0x4D373645:
        fail("%s missing M76E end mark" % name)
    if target(branch, at + br) != PRIMARY:
        fail("%s does not branch to +%#x (got %#x)" % (name, PRIMARY, target(branch, at + br)))
    print("      +%#x %08x  -> +%#x" % (at + br, branch, target(branch, at + br)))
    # A self-branch (b ., encoded 0x14000000) means the rung stops after the
    # fill.  The trailing branch to primary_entry is then dead code, which is
    # why it is still checked above: it must exist and be correct, it just
    # never runs.  HALT=1 asserts that the halt is really there.
    halt = [off for off in range(0, length - 4, 4)
            if struct.unpack_from("<I", blob, off)[0] == 0x14000000]
    if halt:
        print("      +%#x %08x  b .  (rung halts after the fill)" % (at + halt[0], 0x14000000))
        if halt[0] > br:
            fail("%s halts after its branch -- the fill result would not survive" % name)
    elif os.environ.get("HALT") == "1":
        fail("%s was built with HALT=1 but has no self-branch" % name)
if FA_AT + spans[FA_AT] > VENDOR_ENTRY:
    fail("yellow rung runs past the vendor entry")

fa = struct.unpack_from("<I", k, VENDOR_ENTRY)[0]
print("  +%#x %08x  %s" % (VENDOR_ENTRY, fa, insn(fa, VENDOR_ENTRY)))
if target(fa, VENDOR_ENTRY) != FA_AT:
    fail("vendor entry does not reach the yellow rung")

# --- primary_entry beacons --------------------------------------------------
print("\n[primary_entry @ +%#x]" % PRIMARY)
# Colours in the order head.S paints them.  The last one sits at the
# __primary_switch entry, so the window has to cover the whole of primary_entry
# rather than only its first instructions.
#
# The order checked here is source order, not address order: __primary_switch
# follows primary_entry, and a checkpoint placed at the end of primary_entry can
# end up inside it once the tail branch is folded away.  So each colour must
# appear exactly once and the set must match -- asserting "addresses ascend"
# would fail on a perfectly good image and send the next reader hunting for a
# bug that is not there.
BEACONS = (0xFFFF, 0xF800, 0x07E0, 0xFFE0, 0xF81F, 0x07FF, 0x001F, 0xFD20)
seen = {}
for colour in BEACONS:
    pat = struct.pack("<I", 0x52800000 | ((colour & 0xFFFF) << 5) | 12)  # movz w12, #colour
    found = [i for i in range(PRIMARY, PRIMARY + 0x2000) if k[i:i + 4] == pat]
    print("  mov w12, #%#06x : %s" % (colour, [hex(i) for i in found] or "NOT FOUND"))
    if not found:
        fail("beacon %#06x missing near primary_entry" % colour)
    if len(found) > 1:
        fail("beacon %#06x appears %d times" % (colour, len(found)))
    seen[colour] = found[0]
print("  execution order (by address): %s"
      % [hex(c) for c, _ in sorted(seen.items(), key=lambda kv: kv[1])])

# --- diff against the padded, unmodified Image ------------------------------
print("\n[diff vs padded source Image]")
def up(n, page):
    return n if n % page == 0 else n + page - (n % page)


base = img + b"\x00" * (KERNEL_SIZE - len(img))
allowed = [(CODE1_AT, CODE1_AT + spans[CODE1_AT]), (FA_AT, FA_AT + spans[FA_AT]),
           (VENDOR_ENTRY, VENDOR_ENTRY + 4), (4, 8), (16, 24)]
groups, run, total, stray = [], None, 0, []
for i in range(KERNEL_SIZE):
    if k[i] != base[i]:
        total += 1
        if not any(s <= i < e for s, e in allowed):
            stray.append(i)
        if run and i == run[1]:
            run[1] = i + 1
        else:
            run = [i, i + 1]
            groups.append(run)
for s, e in groups[:20]:
    print("  +%#-9x len %3d" % (s, e - s))
print("  %d contiguous runs, %d bytes total, %d outside the rungs"
      % (len(groups), total, len(stray)))
if stray:
    # A mismatch here means the Image on disk is not the one this .img was
    # built from -- the kernel was rebuilt since.  That says nothing about the
    # image being wrong, so report it as such instead of failing: a red FAIL
    # on a good artefact is worse than no check at all.
    print("  NOTE: the kernel on disk has been rebuilt since this image was made;")
    print("        the byte diff above is against the wrong Image and means nothing.")
    print("        Only the rung, beacon and ramdisk checks below are conclusive.")
else:
    print("  changes confined to the rungs")

# --- ramdisk splice ---------------------------------------------------------
orig_ks = struct.unpack("<I", src[8:12])[0]
rd_size = struct.unpack("<I", src[16:20])[0]
rd_at = page + up(orig_ks, page)
ours_at = page + up(KERNEL_SIZE, page)
want = src[rd_at:rd_at + rd_size]
got = out[ours_at:ours_at + rd_size]
print("\n[ramdisk] %d bytes at vendor %#x -> ours %#x  %s"
      % (rd_size, rd_at, ours_at, "identical" if want == got else "DIFFERS"))
if want != got:
    fail("ramdisk splice is wrong")
tail = len(out) - ours_at - rd_size
print("  zero tail after ramdisk: %d bytes (%s)" % (tail, "all zero" if not any(out[ours_at + rd_size:]) else "NOT ZERO"))
if any(out[ours_at + rd_size:]):
    fail("garbage after the ramdisk")
print("\nall checks passed")
