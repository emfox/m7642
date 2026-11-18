#!/usr/bin/env python3
"""Give primary_entry's first beacon a colour of its own.

The blob at +0x600000 floods 0x00ff00ff before branching to primary_entry, and
primary_entry's first beacon used exactly the same value -- so the panel cannot
say whether the branch landed.  Cyan here, magenta there, and the screen
separates "blob only" from "blob plus primary_entry".
"""
import sys

p = "arch/arm64/kernel/head.S"
s = open(p).read()

old = """\tmovz\tw1, #0x00ff
\tmovk\tw1, #0x00ff, lsl #16\t\t// 0x00ff00ff magenta"""

new = """\tmovz\tw1, #0xff00
\tmovk\tw1, #0x00ff, lsl #16\t\t// 0x00ffff00 cyan"""

if old not in s:
    sys.exit("pattern not found")

s = s.replace(old, new, 1)
open(p, "w").write(s)
print("primary_entry first beacon -> cyan")
