#!/usr/bin/env python3
"""
locate.py -- map a guest exception ELR back to a tramp instruction.

usage: locate.py <tramp.dis> <tramp_va> <tramp_pa> <elr>

The tramp is entered at _start_kva (blob offset 0x4) and executes either at its
kernel VA (normal path) or at its physical alias (the x5 == 0 hazard), so an ELR
can be relative to either base.
"""
import re
import sys

DIS_RE = re.compile(r"^\s+([0-9a-f]+):\s+([0-9a-f ]+?)\s{2,}(.*)$")


def load(dis_path):
    insns = {}
    for line in open(dis_path):
        m = DIS_RE.match(line.rstrip("\n"))
        if m:
            insns[int(m.group(1), 16)] = (m.group(2).strip(), m.group(3).strip())
    return insns


def main():
    dis_path, tramp_va, tramp_pa, elr = sys.argv[1:5]
    handover = int(sys.argv[5], 0) if len(sys.argv) > 5 else None
    va, pa, elr = int(tramp_va, 0), int(tramp_pa, 0), int(elr, 0)
    if handover is not None and elr == handover:
        print("    faulting instruction: the tramp's `br x16` target (handover PA "
              "0x%x) -- the fetch through TTBR0 faulted" % handover)
        return
    off, route = None, None
    for base, name in ((va, "VA"), (pa, "PA alias")):
        if base <= elr < base + 0x800:
            off, route = elr - base, name
            break
    if off is None:
        print("    ELR 0x%x is not inside the tramp (not a tramp fault)" % elr)
        return
    insns = load(dis_path)
    near = [o for o in insns if o <= off]
    txt = insns[max(near)] if near else ("?", "?")
    print("    faulting instruction: tramp+0x%03x (%s route)  %s  %s"
          % (off, route, txt[0], txt[1]))


if __name__ == "__main__":
    main()
