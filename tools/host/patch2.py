#!/usr/bin/env python3
"""Drop the dcache-disable sequence from primary_entry's first beacon.

Every beacon that ever appeared on this panel came from a blob with no
mrs/msr sctlr_el1 in it.  Every beacon that stayed invisible had those four
instructions in front of it.  The bootloader is expected to leave the dcache off
anyway, so the sequence protects nothing -- but if SCTLR_EL1.C cannot be touched
at whatever EL we are entered at, those instructions are the first thing that
faults, and nothing after them ever runs.
"""
import sys

p = "arch/arm64/kernel/head.S"
s = open(p).read()

old = """\t/*
\t * The bootloader is supposed to leave the dcache off; nothing outside the
\t * board can confirm this one does.  With the dcache on, the stores below
\t * would sit in cache and never reach DRAM, so the scanout engine -- which
\t * reads DRAM -- would keep showing the logo and the beacon would silently
\t * lie.
\t */
\tmrs\tx10, sctlr_el1
\tbic\tx10, x10, #(1 << 2)\t\t// SCTLR_EL1.C
\tmsr\tsctlr_el1, x10
\tisb
"""

new = """\t/*
\t * No dcache dance here.  Every beacon that ever showed up on this panel
\t * came from a blob without mrs/msr sctlr_el1 in it, and every beacon that
\t * stayed invisible had those instructions in front of it -- if SCTLR_EL1
\t * cannot be touched at the EL we are entered at, they fault and nothing
\t * after them ever runs.  The bootloader is supposed to leave the dcache
\t * off anyway.
\t */
"""

if old not in s:
    sys.exit("pattern not found")

s = s.replace(old, new, 1)
open(p, "w").write(s)
print("dcache-disable removed")
