#!/usr/bin/env python3
"""
check-images.py -- check the *actual* checkpoint images against the tramp blob
they embed, without booting them.

For every image: find the embedded tramp blob (its _start signature), work out
where _start_kva really is inside it, then find the patched `bl` that the image
build wrote and see which blob offset it lands on.  If the two disagree, the TV
will jump into the middle of _start -- that is the 2026-11-22 night failure.

usage: check-images.py [image.img ...]     (default: $OUT/m7642-rec-73-*.img)
"""
import glob
import hashlib
import os
import struct
import sys

SIG = struct.pack("<I", 0xAA1F03E5) + struct.pack("<I", 0x14000043)  # _start


def find_blob(d):
    i = d.find(SIG)
    return i if i >= 0 else None


def kva_offset(d, base):
    """_start_kva is the first non-zero word after the `b` at _start+4."""
    for off in (0x8, 0x10):
        if struct.unpack_from("<I", d, base + off)[0] != 0:
            return off
    return None


def bl_targets(d, base, span=0x228):
    hits = []
    for off in range(0, min(len(d), 0x4000000) - 4, 4):
        w = struct.unpack_from("<I", d, off)[0]
        if (w >> 26) == 0x25:                      # BL
            disp = ((w & 0x3FFFFFF) ^ 0x2000000) - 0x2000000
            t = off + disp * 4
            if base <= t < base + span:
                hits.append((off, t - base))
    return hits


def main():
    outs = sys.argv[1:] or sorted(glob.glob(os.path.expanduser(
        "~/Debian/m7642-build/out/m7642-rec-73-*.img")))
    ref = {}
    for name, path in (("v1..v4 pinned", "gen/ident/bench-default.bin"),
                       ("v4", "gen/ident/v4-copy.bin"),
                       ("v5", "gen/ident/v5-copy.bin"),
                       ("repo tramp-postmmu.bin",
                        "/home/emfox/Debian/m7642/probes/handoff/tramp-postmmu.bin")):
        if os.path.exists(path):
            ref[name] = hashlib.md5(open(path, "rb").read()).hexdigest()
    bad = 0
    for f in outs:
        d = open(f, "rb").read()
        base = find_blob(d)
        name = os.path.basename(f)
        if base is None:
            print("%-28s no tramp blob found" % name)
            continue
        kva = kva_offset(d, base)
        calls = bl_targets(d, base)
        blob = d[base:base + 0x228]
        h = hashlib.md5(blob).hexdigest()
        which = [k for k, v in ref.items() if v == h]
        verdict = "?"
        for off, tgt in calls:
            if tgt == 0xc0:
                continue                                # the _start_fdt shim
            verdict = "OK" if tgt == kva else "POISONED"
            if tgt != kva:
                bad += 1
                print("%-28s blob@%#x (%s) _start_kva@%#x  bl@%#x -> blob+%#x  %s"
                      % (name, base, which[0] if which else "unknown", kva, off, tgt, verdict))
                print("      ^ this bl lands on _start+%#x, not on _start_kva: the TV "
                      "would jump into the middle of _start" % tgt)
            else:
                print("%-28s blob@%#x (%s) _start_kva@%#x  bl@%#x -> blob+%#x  %s"
                      % (name, base, which[0] if which else "unknown", kva, off, tgt, verdict))
    print()
    print("POISONED images: %d" % bad)
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main())
