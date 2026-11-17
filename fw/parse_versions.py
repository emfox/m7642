#!/usr/bin/env python3
"""Parse the __versions section of an AArch64 .ko without binutils support.

Every record is 8-byte CRC + 56-byte symbol name (CONFIG_MODVERSIONS).

  ./parse_versions.py vendor-modules/modules > expect.tsv
"""

import os
import struct
import sys

REC = 64
NAME_LEN = 56


def sections(path):
    data = open(path, 'rb').read()
    if data[:4] != b'\x7fELF' or data[4] != 2:
        raise SystemExit('%s is not ELF64' % path)
    e_shoff, = struct.unpack_from('<Q', data, 0x28)
    e_shentsize, e_shnum, e_shstrndx = struct.unpack_from('<HHH', data, 0x3a)
    hdrs = []
    for i in range(e_shnum):
        off = e_shoff + i * e_shentsize
        name, typ, flags, addr, offset, size = struct.unpack_from('<IIQQQQ', data, off)
        hdrs.append((name, typ, offset, size))
    strtab_off = hdrs[e_shstrndx][2]
    out = {}
    for name_off, typ, offset, size in hdrs:
        end = data.index(b'\x00', strtab_off + name_off)
        name = data[strtab_off + name_off:end].decode()
        out[name] = data[offset:offset + size]
    return out


def versions(path):
    sec = sections(path)
    raw = sec.get('__versions', b'')
    res = {}
    for i in range(0, len(raw) - REC + 1, REC):
        crc, = struct.unpack_from('<Q', raw, i)
        name = raw[i + 8:i + 8 + NAME_LEN].split(b'\x00')[0].decode('latin1')
        if name:
            res[name] = crc
    return res, sorted(sec)


def main(argv):
    root = argv[1] if len(argv) > 1 else 'vendor-modules/modules'
    all_v = {}
    first = True
    for fn in sorted(os.listdir(root)):
        if not fn.endswith('.ko'):
            continue
        v, names = versions(os.path.join(root, fn))
        if first:
            print('# sections: %s' % ' '.join(n for n in names if n))
            first = False
        print('# %-24s %d versioned symbols' % (fn, len(v)))
        for name, crc in v.items():
            all_v.setdefault(name, set()).add(crc)

    print('# symbol\tcrc\tmodules')
    for name in sorted(all_v):
        print('%s\t%s' % (name, ','.join('%x' % c for c in sorted(all_v[name]))))
    clash = [n for n, s in all_v.items() if len(s) > 1]
    print('# unique symbols: %d, conflicting: %d' % (len(all_v), len(clash)))


if __name__ == '__main__':
    main(sys.argv)
