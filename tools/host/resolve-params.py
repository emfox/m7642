#!/usr/bin/env python3
"""Resolve per-build constants for the probe instrument, without trusting
symbol names for the .pi.text (position independent head) code.
  ALIGN_OFF : offset of the unique `and x25,x19,#0x1fffff`
  BLOB_OFF  : offset of a zero-filled gap in .text big enough for tramp+stub,
              verified to contain no symbol
"""
import struct, sys

KADDR = 0xffffffc080000000
ALIGN_WORD = 0x92405279
BLOB_NEED = 0x880
KOFF = 2048

img, sysmap = sys.argv[1], sys.argv[2]
d = open(img, "rb").read()

syms = []
for line in open(sysmap):
    p = line.split()
    if len(p) >= 3:
        try: a = int(p[0], 16)
        except ValueError: continue
        syms.append((a - KADDR, p[2]))
syms.sort()
by_name = {}
for a, n in syms:
    by_name.setdefault(n, a)

stext = by_name.get("_stext", by_name.get("__init_begin", 0x10000))
etext = by_name["_etext"]

# --- 1. unique align instruction
hits, off = [], KOFF
while True:
    i = d.find(struct.pack("<I", ALIGN_WORD), off)
    if i < 0: break
    if (i - KOFF) % 4 == 0: hits.append(i - KOFF)
    off = i + 1
if len(hits) != 1:
    sys.exit("resolve: expected exactly one align instruction, found %d" % len(hits))
align = hits[0]

# --- 2a. the reserved probe slot (preferred: stable across configs)
slot = by_name.get("__m7642_probe_slot")
if slot is not None:
    end = by_name.get("__m7642_probe_slot_end", slot)
    # the slot is explicitly reserved by vmlinux.lds.S; only zero-size
    # section markers can legitimately carry an address inside it
    odd = [(a, n) for a, n in syms if slot < a < slot + (end - slot) and
           not (n.endswith("_start") or n.endswith("_end"))]
    if odd:
        sys.exit("resolve: probe slot unexpectedly contains %s" % odd[:3])
    print("ALIGN_OFF=0x%x" % align)
    print("SLOT_OFF=0x%x" % slot)
    sys.stderr.write("resolve: align %#x (unique instruction), slot %#x (%#x bytes, reserved)\n"
                     % (align, slot, end - slot))
    sys.exit(0)

# --- 2. a zero gap in .text (fallback when there is no reserved slot)
blob = None
best = 0
i = KOFF + stext
end = KOFF + etext
while i < end:
    if d[i] != 0:
        i += 1
        continue
    run_start = i
    while i < end and d[i] == 0:
        i += 1
    run = i - run_start
    if run > best:
        best = run
    if run >= BLOB_NEED:
        start = (run_start - KOFF + 0x3f) & ~0x3f
        if start + BLOB_NEED <= i - KOFF:
            blob = start          # zero-filled: whatever symbol sits here is a
                                  # section marker, not live code
if blob is None:
    sys.exit("resolve: no symbol-free zero gap >= %#x in .text (longest gap %#x)" % (BLOB_NEED, best))

near = [n for a, n in syms if blob <= a < blob + BLOB_NEED]
if near:
    sys.stderr.write("resolve: note: zero gap also carries markers %s\n" % ", ".join(near[:6]))

print("ALIGN_OFF=0x%x" % align)
print("SLOT_OFF=0x%x" % blob)
sys.stderr.write("resolve: align %#x (unique), blob %#x..%#x (zero gap, no symbols), _etext %#x\n"
                 % (align, blob, blob + BLOB_NEED, etext))
