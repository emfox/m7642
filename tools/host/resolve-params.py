#!/usr/bin/env python3
"""Per-build constants for the m7642 probe instrument.

  ALIGN_OFF : file offset of the 2 MB-alignment instruction, taken from
              ckpt.py's symbol-relative definition (__pi_early_map_kernel+0x3c)
              and content-checked.  Never search for the byte pattern: it has a
              coincidental match elsewhere (2026-11-25).
  SLOT_OFF  : file offset of a zero-filled gap in .text big enough for the
              trampoline (>= 0x880), preferring the highest one (the .text tail
              padding).  The caller re-checks that the region is really zero.

Both are file offsets into the kernel payload.  The payload starts at 0 for a
bare arm64 Image and at page_size for an ANDROID! container, so detect it.
"""
import os
import struct
import subprocess
import sys

KADDR = 0xffffffc080000000
ALIGN_WORD = 0x92405279          # and x25, x19, #0x1fffff
BLOB_NEED = 0x880

img, sysmap = sys.argv[1], sys.argv[2]
d = open(img, "rb").read()
KOFF = (struct.unpack_from("<I", d, 36)[0] or 2048) if d[:8] == b"ANDROID!" else 0
payload = d[KOFF:]

syms = []
for line in open(sysmap):
    p = line.split()
    if len(p) >= 3:
        try:
            a = int(p[0], 16)
        except ValueError:
            continue
        syms.append((a - KADDR, p[2]))
syms.sort()
by_name = {}
for a, n in syms:
    by_name.setdefault(n, a)

# --- align site: symbol-relative, content-checked
here = os.path.dirname(os.path.abspath(__file__))
out = subprocess.check_output(["python3", os.path.join(here, "ckpt.py"),
                               "--sysmap", sysmap, "--env", "zfix_align"], text=True)
align = int(out.strip().split("=")[1], 0)
got = struct.unpack_from("<I", payload, align)[0]
if got != ALIGN_WORD:
    sys.exit("resolve: align site %#x holds %#010x, expected %#010x"
             % (align, got, ALIGN_WORD))

# --- trampoline slot: highest zero gap in .text
etext = by_name["_etext"]
stext = by_name.get("_stext", 0)
slot = None
best = 0
i = stext
while i < etext:
    if payload[i] != 0:
        i += 1
        continue
    s = i
    while i < etext and payload[i] == 0:
        i += 1
    run = i - s
    best = max(best, run)
    if run >= BLOB_NEED:
        cand = s if (s % 64) == 0 else s + (64 - s % 64)
        if cand + BLOB_NEED <= i:
            slot = cand
if slot is None:
    sys.exit("resolve: no zero gap >= %#x in .text (longest %#x)" % (BLOB_NEED, best))
if any(payload[slot:slot + BLOB_NEED]):
    sys.exit("resolve: slot %#x is not zero-filled" % slot)

print("ALIGN_OFF=0x%x" % align)
print("SLOT_OFF=0x%x" % slot)
sys.stderr.write("resolve: payload base %#x, align %#x, slot %#x..%#x, _etext %#x\n"
                 % (KOFF, align, slot, slot + BLOB_NEED, etext))
