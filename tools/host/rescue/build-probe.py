#!/usr/bin/python3
"""
Build a boot hand-off probe: patch several candidate entry offsets of a real
kernel Image with branches into a colour-filling stub appended past the kernel.

If the bootloader jumps to any of the patched offsets, the screen turns that
colour before anything else runs.  No colour at all means it never jumped.

Usage: build-probe.py <kernel-Image> <probe.bin> <out-Image>
"""

import struct
import sys

PROBE_OFF = 0x600000          # where the stub lands inside the kernel image
TEXT_OFFSET = 0x80000         # vendor value, kept
IMAGE_SIZE = 0x700000         # must cover PROBE_OFF + stub

# file offset -> probe slot offset (slot spacing in probe.S is 0x10)
SLOTS = [
    (0x000004, 0x00),         # code1 -> magenta
    (0x080000, 0x10),         # text_offset target -> blue
    (0x100000, 0x20),         # -> white
    (0x200000, 0x30),         # -> yellow
]


def b_insn(from_off, to_off):
    """Encode `b to_off` located at file offset from_off (same 128MB window)."""
    delta = to_off - from_off
    if delta % 4 or not -(1 << 27) <= delta < (1 << 27):
        raise ValueError("branch out of range: 0x%x -> 0x%x" % (from_off, to_off))
    return 0x14000000 | ((delta >> 2) & 0x03FFFFFF)


def main():
    if len(sys.argv) != 4:
        print(__doc__)
        return 2
    kern = bytearray(open(sys.argv[1], "rb").read())
    stub = open(sys.argv[2], "rb").read()
    out = sys.argv[3]

    print("kernel   %d B (0x%x)" % (len(kern), len(kern)))
    print("stub     %d B, placed at 0x%x" % (len(stub), PROBE_OFF))
    if len(kern) > PROBE_OFF:
        print("ERROR: kernel larger than probe offset")
        return 1

    img = kern + b"\x00" * (PROBE_OFF - len(kern)) + stub
    img += b"\x00" * ((4 - len(img) % 4) % 4)
    print("image    %d B (0x%x)" % (len(img), len(img)))

    # arm64 Image header: keep a legal MZ at code0 so a bootloader that sniffs
    # for the EFI signature still recognises it, and branch from code1.
    struct.pack_into("<I", img, 0x00, 0x91005a4d)          # MZ magic, harmless add
    struct.pack_into("<Q", img, 0x08, TEXT_OFFSET)
    struct.pack_into("<Q", img, 0x10, IMAGE_SIZE)
    struct.pack_into("<I", img, 0x38, 0x644d5241)           # "ARM\x64"

    for foff, soff in SLOTS:
        struct.pack_into("<I", img, foff, b_insn(foff, PROBE_OFF + soff))

    open(out, "wb").write(img)

    print("\npatched branch slots:")
    for foff, soff in SLOTS:
        print("  0x%06x -> 0x%06x" % (foff, PROBE_OFF + soff))
    print("\nhdr: code0=0x%08x code1=0x%08x text_off=0x%x image_size=0x%x magic=%08x"
          % (struct.unpack_from("<I", img, 0)[0], struct.unpack_from("<I", img, 4)[0],
             struct.unpack_from("<Q", img, 8)[0], struct.unpack_from("<Q", img, 16)[0],
             struct.unpack_from("<I", img, 0x38)[0]))
    return 0


if __name__ == "__main__":
    sys.exit(main())
