#!/usr/bin/env python3
"""Decode adrp+ldr pairs from the probe5 disassembly to locate data symbols."""
import re
import sys

FUNC = 0xffffff8008896550  # MDrv_SYS_RegOP
ASM = "/home/emfox/Debian/tv/kernel-lab/disasm/MDrv_SYS_RegOP.s"


def sign_extend(v, bits):
    if v & (1 << (bits - 1)):
        return v - (1 << bits)
    return v


def decode_adrp(insn, pc):
    assert (insn >> 24) & 0x1F == 0x10, "not an adrp"
    immlo = (insn >> 29) & 0x3
    immhi = (insn >> 5) & 0x7FFFF
    imm = sign_extend((immhi << 2) | immlo, 21)
    return (pc & ~0xFFF) + (imm << 12)


lines = open(ASM).read().splitlines()
prev = None
for ln in lines:
    m = re.match(r"\s+([0-9a-f]+):\s+([0-9a-f]{8})\s+(\w+)\s*(.*)", ln)
    if not m:
        continue
    off = int(m.group(1), 16)
    insn = int(m.group(2), 16)
    asm = m.group(3)
    args = m.group(4).strip()
    pc = FUNC + off
    if asm == "adrp":
        try:
            tgt = decode_adrp(insn, pc)
            prev = (off, tgt)
            print("0x%03x adrp -> %#x" % (off, tgt))
        except AssertionError:
            pass
    elif asm == "ldr" and prev:
        mm = re.match(r"x\d+, \[(x\d+), #(\d+)\]", args)
        if mm:
            print("0x%03x ldr  [page+%s]  => data @ %#x"
                  % (off, mm.group(2), prev[1] + int(mm.group(2))))
