#!/usr/bin/env python3
"""Dump the symbol CRCs a vendor module demands (__versions section).

With CONFIG_MODVERSIONS every imported symbol carries a 64-byte record:
8-byte CRC (unsigned long on arm64) followed by a 56-byte name.

  ./collect_versions.py vendor-modules/modules > expect.tsv
"""

import os
import struct
import subprocess
import sys
import tempfile

REC = 64
NAME_LEN = 56


def section(path, name):
    with tempfile.NamedTemporaryFile() as tmp:
        r = subprocess.run(['objcopy', '-O', 'binary', '--only-section=' + name,
                            path, tmp.name], capture_output=True)
        if r.returncode != 0:
            return b''
        return open(tmp.name, 'rb').read()


def versions(path):
    raw = section(path, '__versions')
    out = {}
    for i in range(0, len(raw) - REC + 1, REC):
        crc = struct.unpack('<Q', raw[i:i + 8])[0]
        name = raw[i + 8:i + 8 + NAME_LEN].split(b'\x00')[0].decode('latin1')
        if name:
            out[name] = crc
    return out


def main(argv):
    root = argv[1] if len(argv) > 1 else 'vendor-modules/modules'
    all_v = {}
    for fn in sorted(os.listdir(root)):
        if not fn.endswith('.ko'):
            continue
        v = versions(os.path.join(root, fn))
        print('# %s: %d versioned symbols' % (fn, len(v)))
        for name, crc in v.items():
            all_v.setdefault(name, set()).add(crc)

    print('# symbol\tcrc\tmodules')
    clash = 0
    for name in sorted(all_v):
        crcs = sorted(all_v[name])
        if len(crcs) > 1:
            clash += 1
        print('%s\t%s' % (name, ','.join('%x' % c for c in crcs)))
    print('# unique symbols: %d' % len(all_v))
    print('# symbols with conflicting crc across modules: %d' % clash)


if __name__ == '__main__':
    main(sys.argv)
