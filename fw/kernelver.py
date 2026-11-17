#!/usr/bin/env python3
"""Print the kernel version / build stamp embedded in a TCL (MStar) .bin firmware.

Usage: kernelver.py <firmware.bin> [more.bin ...]

The .bin is a flat container: the 16 KB script region at offset 0 lists every
partition as `filepartload <dst> <src> <file_offset> <size>`, so boot can be
cut out by offset alone -- no extraction tool needed.
"""
import gzip
import bz2
import lzma
import re
import sys


def boot_blob(path):
    with open(path, 'rb') as f:
        head = f.read(0x4000)
    txt = head.split(b'\x00')[0].decode('latin1')
    m = re.search(r'# File Partition: boot\s*\nfilepartload\s+\S+\s+\S+\s+'
                  r'(0x[0-9a-fA-F]+)\s+(0x[0-9a-fA-F]+)', txt)
    if not m:
        return None, None
    off, size = int(m.group(1), 16), int(m.group(2), 16)
    with open(path, 'rb') as f:
        f.seek(off)
        return f.read(size), (off, size)


def kernel_part(img):
    if img[:8] != b'ANDROID!':
        return img
    ksize = int.from_bytes(img[8:12], 'little')
    return img[2048:2048 + ksize]


def find_version(blob):
    for name, dec in (('gzip', gzip.decompress), ('xz', lzma.decompress),
                      ('bzip2', bz2.decompress)):
        try:
            data = dec(blob)
        except Exception:
            continue
        hit = re.search(rb'Linux version [^\x00\n]{0,160}', data)
        if hit:
            return name, hit.group(0).decode('latin1')
    hit = re.search(rb'Linux version [^\x00\n]{0,160}', blob)
    if hit:
        return 'raw', hit.group(0).decode('latin1')
    return None, None


def main(paths):
    for p in paths:
        blob, where = boot_blob(p)
        print('==', p)
        if blob is None:
            print('   no boot partition in script region')
            continue
        kind, line = find_version(kernel_part(blob))
        print('   boot @ 0x%x, %d bytes (%s)' % (where[0], where[1], kind or 'unknown'))
        print('   ' + (line or 'kernel version string not found'))


if __name__ == '__main__':
    if len(sys.argv) < 2:
        sys.exit(__doc__)
    main(sys.argv[1:])
