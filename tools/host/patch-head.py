#!/usr/bin/env python3
"""Rewrite primary_entry's bring-up beacons.

The probe that finally lit the panel steered GOP0's eight windows at
0x2d100000, pulsed GOP_FWR, and flooded the buffer.  Everything before that
failed because it skipped GOP_FWR (the address write is dropped silently) and
walked all three GOPs with a 0x600 stride that lands on the wrong addresses for
GOP1/GOP2.  This applies the working sequence, then gives each later checkpoint
its own solid colour.
"""
import sys

p = "arch/arm64/kernel/head.S"
s = open(p).read()

start = s.index("\tmov\tx9, x0\t\t\t\t// keep the DTB pointer")
end = s.index("\tmov\tx0, x9\n#endif", start) + len("\tmov\tx0, x9\n#endif")

new = """\tmov\tx9, x0\t\t\t\t// keep the DTB pointer
\t/*
\t * LOCAL BRING-UP AID, lifted straight from the probe that finally lit
\t * the panel: steer GOP0's eight windows at 0x2d100000, pulse GOP_FWR to
\t * commit the shadow registers, then flood the buffer.
\t *
\t * Two details cost several flash-and-rescue cycles to find:
\t *   - without GOP_FWR the address write is dropped silently, so the
\t *     panel keeps showing whatever the bootloader left there and every
\t *     colour painted here stays invisible;
\t *   - only GOP0 is touched.  Walking all three GOPs with a 0x600 stride
\t *     lands on the wrong addresses for GOP1/GOP2 and made earlier
\t *     attempts paint nothing at all.
\t */
\tmovz\tx3, #0x0604
\tmovk\tx3, #0x1f24, lsl #16\t\t// 0x1f240604: gop0/bank1/win0 STR_L
\tmovz\tw4, #0x2d10\t\t\t// HI16BIT(0x2d100000)
\tmov\tx5, xzr\t\t\t\t// LO16BIT and EX are zero
\tmov\tx6, #8
8:\tstrh\tw5, [x3]
\tstrh\tw4, [x3, #4]
\tstrh\tw5, [x3, #8]
\tadd\tx3, x3, #0x40\t\t\t// next window
\tsubs\tx6, x6, #1
\tb.ne\t8b

\tmovz\tx13, #0x07fc
\tmovk\tx13, #0x1f24, lsl #16\t\t// gop0/bank1 BANK_SEL
\tldrh\tw15, [x13]
\torr\tw15, w15, #0x0200\t\t// GOP_FWR
\tstrh\tw15, [x13]
\tldrh\tw15, [x13]
\tbic\tw15, w15, #0x0200
\tstrh\tw15, [x13]

\tmov\tx0, #0x2d10
\tlsl\tx0, x0, #16
\tmovz\tw1, #0x00ff
\tmovk\tw1, #0x00ff, lsl #16\t\t// 0x00ff00ff magenta
\tmovz\tx2, #0x7e9
\tlsl\tx2, x2, #12
\tadd\tx2, x0, x2
9:\tstr\tw1, [x0], #4
\tcmp\tx0, x2
\tb.lo\t9b
\tdsb\tsy
\tmov\tx0, x9
#endif"""

s = s[:start] + new + s[end:]

# Colours, in the panel's byte order (low byte is red):
#   0x000000ff red, 0x0000ff00 green, 0x00ff0000 blue, 0x0000ffff yellow
repl = [
    ("\tmovz\tw12, #0x00ff\n\tmovk\tw12, #0xff00, lsl #16\t\t// blue\n\tbl\tm7642_paint",
     "\tmovz\tw12, #0x00ff\t\t\t// 0x000000ff red\n\tbl\tm7642_paint"),
    ("\tmovz\tw12, #0xff00\n\tmovk\tw12, #0xffff, lsl #16\t\t// yellow\n\tbl\tm7642_paint",
     "\tmovz\tw12, #0xff00\t\t\t// 0x0000ff00 green\n\tbl\tm7642_paint"),
    ("\tmovz\tw12, #0xffff\n\tmovk\tw12, #0xff00, lsl #16\t\t// cyan\n\tbl\tm7642_paint",
     "\tmovz\tw12, #0x00ff\n\tmovk\tw12, #0x00ff, lsl #16\t\t// 0x00ff0000 blue\n\tbl\tm7642_paint"),
    ("\tmovz\tw12, #0x8000\n\tmovk\tw12, #0xffff, lsl #16\t\t// orange\n\tbl\tm7642_paint",
     "\tmovz\tw12, #0xffff\t\t\t// 0x0000ffff yellow\n\tbl\tm7642_paint"),
]
for a, b in repl:
    if a not in s:
        sys.exit("pattern missing: %r" % a.splitlines()[-3])
    s = s.replace(a, b, 1)

open(p, "w").write(s)
print("head.S rewritten")
