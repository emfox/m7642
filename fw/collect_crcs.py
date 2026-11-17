#!/usr/bin/env python3
"""Collect the ABI a vendor module expects: vermagic, undefined symbols, symbol CRCs.

Modversions makes every imported symbol carry a __crc_<name> entry holding the
CRC the kernel must export. Those values are the ground truth a rebuilt kernel
has to reproduce.

  ./collect_crcs.py vendor-modules/modules > expect.tsv
"""

import os
import re
import subprocess
import sys

SYM = re.compile(r'^\s*\d+:\s+([0-9a-f]+)\s+([0-9a-f]+)\s+(\w+)\s+(\w+)\s+(\w+)\s+(\S+)\s*$')


def symbols(path):
    out = subprocess.run(['readelf', '-sW', path], capture_output=True, text=True).stdout
    for line in out.splitlines():
        m = SYM.match(line)
        if m:
            value, size, typ, bind, vis, name = m.groups()
            yield name, int(value, 16), typ, bind


def main(argv):
    root = argv[1] if len(argv) > 1 else 'vendor-modules/modules'
    vermagic = {}
    crcs = {}
    undefined = {}
    for name in sorted(os.listdir(root)):
        if not name.endswith('.ko'):
            continue
        path = os.path.join(root, name)
        raw = open(path, 'rb').read()
        m = re.search(rb'vermagic=([^\x00]+)', raw)
        vermagic[name] = m.group(1).decode() if m else '?'
        u = set()
        c = {}
        for sym, value, typ, bind in symbols(path):
            if typ == 'UND':
                u.add(sym)
            elif sym.startswith('__crc_'):
                c[sym[6:]] = value
        undefined[name] = u
        for k, v in c.items():
            crcs.setdefault(k, set()).add(v)

    print('# vermagic')
    for k, v in vermagic.items():
        print('%s\t%s' % (k, v))
    print('# crc\t<name>\t<value>\t<modules>')
    for k in sorted(crcs):
        vals = ','.join('%x' % v for v in sorted(crcs[k]))
        print('crc\t%s\t%s' % (k, vals))
    print('# undefined symbols per module')
    for k in sorted(undefined):
        print('und\t%s\t%d' % (k, len(undefined[k])))
    all_crc_missing = [s for s in set().union(*undefined.values())
                       if s.startswith('__') is False and s not in crcs]
    print('# imported symbols without a __crc entry: %d' % len(all_crc_missing))


if __name__ == '__main__':
    main(sys.argv)
