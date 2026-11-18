#!/usr/bin/env python3
"""Static analysis helper for the m7642 (MT9652) mboot blob.

mboot is an ARM32 position-independent U-Boot derived from MStar's tree.
Two facts make naive analysis fail and are encoded here:

  * The blob starts with a 0x2400-byte header; the body is linked at
    0x27400000, so   VA = 0x27400000 + (fileoff - 0x2400).
    Using VA = base + fileoff is off by 0x2400 and silently finds nothing.
  * String addresses are computed as
        ldr rN, [pc, #imm]   ; N <- offset
        add rX, pc, rN       ; pc = addr_of_add + 8
    i.e. target = add_addr + 8 + offset.  Absolute literals are absent.

Usage:
    mboot-an.py strings <mboot.raw> <substr> [<substr> ...]
    mboot-an.py cmds <mboot.raw>
    mboot-an.py dis <mboot.raw> <hex-va> [count]
    mboot-an.py callers <mboot.raw> <hex-va>
"""

import struct
import sys

try:
    from capstone import Cs, CS_ARCH_ARM, CS_MODE_ARM
except ImportError:
    Cs = None

HDR = 0x2400
BASE = 0x27400000


def load(path):
    with open(path, 'rb') as f:
        return f.read()


def to_va(off):
    return BASE + (off - HDR)


def to_off(va):
    return va - BASE + HDR


def cstr(d, va):
    o = to_off(va)
    if not (0 <= o < len(d)):
        return None
    e = o
    while e < len(d) and 32 <= d[e] < 127:
        e += 1
    if e - o < 2:
        return None
    return d[o:e].decode('latin1')


def find_string(d, substr):
    """Return (file_offset, va) of the first match, walking back to its start."""
    b = substr.encode() if isinstance(substr, str) else substr
    off = d.find(b)
    if off < 0:
        return None
    s = off
    while s > HDR and 32 <= d[s - 1] < 127:
        s -= 1
    return s, to_va(s)


def find_refs(d, va_target):
    """All code sites that materialise va_target via ldr-literal + add-pc."""
    hits = []
    for i in range(HDR, len(d) - 4, 4):
        w = struct.unpack_from('<I', d, i)[0]
        if (w >> 28) != 0xE:
            continue
        if (w & 0x0F7F0000) != 0x051F0000:      # ldr rN, [pc, #imm]
            continue
        imm = w & 0xFFF
        lit = i + 8 + imm
        if lit + 4 > len(d):
            continue
        off_val = struct.unpack_from('<I', d, lit)[0]
        if (to_va(i) + 12 + off_val) & 0xFFFFFFFF == va_target:
            hits.append(to_va(i))
    return hits


def cmd_table(d):
    """Walk U-Boot's cmd_tbl array. Entry layout (0x1c bytes):
         +0x00 name  +0x04 maxargs  +0x08 repeatable
         +0x0c func  +0x10 usage     +0x14 help
    """
    out = []
    for off in range(HDR, len(d) - 0x1c, 4):
        w = struct.unpack_from('<I', d, off)[0]
        if not (BASE <= w <= BASE + 0x2d0040):
            continue
        name = cstr(d, w)
        if not name or len(name) > 30 or ' ' in name:
            continue
        maxargs, rep, fn = struct.unpack_from('<3I', d, off + 4)
        if maxargs > 20 or rep > 4:
            continue
        if not (BASE <= fn <= BASE + 0x2d0040):
            continue
        usage = cstr(d, struct.unpack_from('<I', d, off + 0x10)[0]) or ''
        out.append((name, maxargs, fn, usage))
    return out


def disasm(d, va, count):
    if Cs is None:
        sys.exit('capstone not installed')
    md = Cs(CS_ARCH_ARM, CS_MODE_ARM)
    off = to_off(va)
    n = 0
    for i in md.disasm(d[off:off + count * 4], va):
        print('  0x%08x  %-8s %s' % (i.address, i.mnemonic, i.op_str))
        n += 1
        if n >= count:
            break


def callers(d, target):
    out = []
    for i in range(HDR, len(d) - 4, 4):
        w = struct.unpack_from('<I', d, i)[0]
        if (w >> 24) != 0xEB:                   # bl
            continue
        rel = w & 0xFFFFFF
        if rel & 0x800000:
            rel -= 0x1000000
        if ((to_va(i) + 8 + rel * 4) & 0xFFFFFFFF) == target:
            out.append(to_va(i))
    return out


def main(argv):
    if len(argv) < 3:
        sys.exit(__doc__)
    cmd, path = argv[1], argv[2]
    d = load(path)

    if cmd == 'strings':
        for sub in argv[3:]:
            r = find_string(d, sub)
            if not r:
                print('%-34s not found' % sub)
                continue
            off, va = r
            refs = find_refs(d, va)
            print('%-34s file 0x%06x  VA 0x%08x  refs: %s'
                  % (sub, off, va, ' '.join('0x%08x' % x for x in refs) or 'none'))
    elif cmd == 'cmds':
        for name, maxargs, fn, usage in cmd_table(d):
            print('%-30s %-3d 0x%08x  %s' % (name, maxargs, fn, usage[:58]))
    elif cmd == 'dis':
        va = int(argv[3], 16)
        n = int(argv[4]) if len(argv) > 4 else 40
        disasm(d, va, n)
    elif cmd == 'callers':
        va = int(argv[3], 16)
        print(' '.join('0x%08x' % x for x in callers(d, va)) or 'none')
    else:
        sys.exit(__doc__)


if __name__ == '__main__':
    main(sys.argv)
