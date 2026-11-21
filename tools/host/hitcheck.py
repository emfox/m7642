#!/usr/bin/env python3
"""Locate 32-bit constants in a raw binary and tell real constants from
cross-word-boundary coincidences.

A movw/movt pair or a literal-pool entry is word aligned, so an occurrence
that starts at offset % 4 != 0 cannot be the constant itself.  Print the
surrounding words so the caller can eyeball the context instead of trusting
a bare grep.
"""
import struct
import sys


def hits(buf, pat):
    out = []
    i = buf.find(pat)
    while i >= 0:
        out.append(i)
        i = buf.find(pat, i + 1)
    return out


def ctx(buf, off, before=16, after=16):
    lo = max(0, off - before) & ~3
    hi = min(len(buf), off + after)
    rows = []
    for a in range(lo, hi, 4):
        if a + 4 > len(buf):
            break
        w = struct.unpack_from("<I", buf, a)[0]
        mark = " <<<" if a <= off < a + 4 else ""
        rows.append("  %08x: %08x%s" % (a, w, mark))
    return "\n".join(rows)


def main():
    path = sys.argv[1]
    vals = [int(x, 0) for x in sys.argv[2:]]
    buf = open(path, "rb").read()
    print("file %s  size 0x%x" % (path, len(buf)))
    for v in vals:
        pat = struct.pack("<I", v)
        hs = hits(buf, pat)
        print("\n=== 0x%08x  pattern %s  hits=%d ===" %
              (v, pat.hex(" "), len(hs)))
        real = [h for h in hs if h % 4 == 0]
        fake = [h for h in hs if h % 4]
        print("aligned (candidate real): %d %s" %
              (len(real), " ".join("0x%x" % h for h in real)))
        print("unaligned (impossible):  %d %s" %
              (len(fake), " ".join("0x%x" % h for h in fake)))
        for h in hs[:12]:
            print("\n-- hit 0x%x  (mod4=%d)" % (h, h % 4))
            print(ctx(buf, h))


if __name__ == "__main__":
    main()
