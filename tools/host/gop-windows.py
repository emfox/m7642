#!/usr/bin/env python3
"""Decode a probeRW hexdump of the GOP register window into windows.

The GOP register block is a flat array of per-window slots.  For gop idx, bank,
window widx the STR_L register lives at

    0x1f200000 + (0x02 + 0x20200 + (idx * 3 + bank) * 0x100 + (widx << 5)) * 2

so each slot is 0x20 RIU words = 0x40 bytes, the control word sits 4 bytes
before STR_L, and STR_L/STR_H/STR_EX are three consecutive 16-bit halves of a
32-bit address.  Rather than trusting that arithmetic, this walks every 0x20
boundary in the dumped range and prints whatever looks like a slot: that also
catches slots whose index we did not predict.
"""
import re
import sys

BASE = 0x1f240000


def load(path):
    mem = {}
    for line in open(path):
        m = re.match(r"^([0-9a-f]{16}):((?: [0-9a-f]{2})+)", line.strip())
        if not m:
            continue
        at = int(m.group(1), 16)
        for i, b in enumerate(int(x, 16) for x in m.group(2).split()):
            mem[at + i] = b
    return mem


def u16(mem, a):
    try:
        return mem[a] | (mem[a + 1] << 8)
    except KeyError:
        return None


def u32(mem, a):
    lo = u16(mem, a)
    hi = u16(mem, a + 2)
    return None if lo is None or hi is None else lo | (hi << 16)


def main(path):
    mem = load(path)
    if not mem:
        raise SystemExit("empty dump: %s" % path)
    lo, hi = min(mem), max(mem)
    print("dump covers %#x..%#x" % (lo, hi))

    live = []
    for a in range(lo & ~0x1F, (hi + 1) & ~0x1F, 0x20):
        ctrl = u32(mem, a)
        sl, sh, ex = u16(mem, a + 4), u16(mem, a + 8), u16(mem, a + 12)
        if ctrl is None or sl is None or sh is None:
            continue
        if ctrl == 0 and sl == 0 and sh == 0:
            continue
        addr = (sh << 16) | sl
        on = bool(ctrl & 1)
        print("%#012x ctrl=%#010x en=%d addr=%#010x%s"
              % (a, ctrl, on, addr, "  <== ENABLED" if on else ""))
        if on:
            live.append((a, ctrl, addr))

    print()
    print("enabled windows: %d" % len(live))
    for a, ctrl, addr in live:
        print("  %#012x ctrl=%#010x scans %#010x" % (a, ctrl, addr))


if __name__ == "__main__":
    main(sys.argv[1] if len(sys.argv) > 1 else "-")
