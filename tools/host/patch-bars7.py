import os, sys, hashlib, struct

OUT  = os.path.expanduser("~/kbuild/m7642-out/m7642-ladder9-ciim3.img")
BASE = os.path.expanduser("~/kbuild/m7642-out/m7642-ladder9.img")
RUNG = os.path.expanduser("~/kbuild/ciim/rung7.bin")


def md5(b):
    return hashlib.md5(b).hexdigest()


PAGE      = 0x800
KERNEL_AT = 0x465E5C          # .init.text, create_init_idmap prologue
RUNG_AT   = 0x4A7000          # gap between .altinstructions end and .init.data
EXPECT_ORIG = 0xD10143FF      # sub sp, sp, #0x50

# Hard limits from `readelf -SW vmlinux`.  Anything at or past _edata is not the
# kernel any more: the Image body ends there and the vendor blob follows, which
# mboot does not map where we expect.  rung6 died in that dead zone.
EDATA         = 0x5F3200      # _edata, end of the Image body
INITTEXT_END  = 0x4B0000      # __inittext_end

img = bytearray(open(BASE, "rb").read())
assert md5(img) == "7090e41c1f1fbb62ca8ea13fac6ee10d", "unexpected base image"

rung = open(RUNG, "rb").read()
print("rung7.bin %d bytes" % len(rung))
assert len(rung) % 4 == 0
assert RUNG_AT + len(rung) <= EDATA, "landing zone runs past _edata"
assert RUNG_AT + len(rung) <= INITTEXT_END, "landing zone runs past __inittext_end"

dst = KERNEL_AT + PAGE
orig = struct.unpack_from("<I", img, dst)[0]
print("orig @%#x = %#010x" % (KERNEL_AT, orig))
assert orig == EXPECT_ORIG, "prologue not where expected"

# b RUNG_AT from KERNEL_AT
delta = RUNG_AT - KERNEL_AT
assert delta % 4 == 0
imm26 = (delta >> 2) & 0x03FFFFFF
branch = 0x14000000 | imm26
struct.pack_into("<I", img, dst, branch)
print("patch +%#x  %#010x -> %#010x (b +%#x)" % (KERNEL_AT, orig, branch, RUNG_AT))
print("  verify: %#x + %#x = %#x" % (KERNEL_AT, delta, KERNEL_AT + delta))

# landing zone must be empty and inside the image body
roff = RUNG_AT + PAGE
old = bytes(img[roff:roff + len(rung)])
if any(old):
    sys.exit("destination +%#x is not empty: %s" % (RUNG_AT, old.hex()))
img[roff:roff + len(rung)] = rung
print("rung  +%#x  %d bytes (stays below image body end 0x%X)" % (RUNG_AT, len(rung), 0x5F3200))

open(OUT, "wb").write(img)
print("size %d" % len(img))
print("wrote %s  md5=%s" % (OUT, md5(img)))
