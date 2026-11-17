#!/usr/bin/env python3
"""Compare our rebuilt kernel's exported symbol CRCs with what the vendor modules demand.

  ./abi_compare.py out/Module.symvers expect.tsv
"""

import sys


def load_expect(path):
    exp = {}
    for line in open(path, encoding='latin1'):
        if line.startswith('#') or '\t' not in line:
            continue
        name, crc = line.rstrip('\n').split('\t')[:2]
        exp[name] = crc
    return exp


def load_symvers(path):
    out = {}
    for line in open(path, encoding='latin1'):
        parts = line.split('\t')
        if len(parts) < 2:
            continue
        crc, name = parts[0], parts[1]
        out[name] = crc[2:].lstrip('0') or '0'
    return out


def norm(v):
    return v.lower().lstrip('0') or '0'


def main(argv):
    symvers, expect = argv[1], argv[2]
    exp = load_expect(expect)
    got = load_symvers(symvers)
    print('symbols demanded by vendor modules : %d' % len(exp))
    print('symbols exported by rebuilt kernel : %d' % len(got))

    same, diff, missing = [], [], []
    for name, crc in exp.items():
        if name not in got:
            missing.append(name)
        elif norm(got[name]) == norm(crc):
            same.append(name)
        else:
            diff.append((name, crc, got[name]))

    total = len(exp)
    print('crc match   : %d (%.1f%%)' % (len(same), 100.0 * len(same) / total))
    print('crc differ  : %d (%.1f%%)' % (len(diff), 100.0 * len(diff) / total))
    print('not exported: %d (%.1f%%)' % (len(missing), 100.0 * len(missing) / total))
    if diff:
        print('\nfirst differing symbols (want vs got):')
        for name, want, have in diff[:15]:
            print('  %-32s %s  %s' % (name, want, have))
    if missing:
        print('\nfirst missing symbols:')
        for name in missing[:15]:
            print('  %s' % name)


if __name__ == '__main__':
    main(sys.argv)
