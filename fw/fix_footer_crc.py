#!/usr/bin/env python3
"""Recompute the trailer checksum of a TCL/MStar upgrade .bin.

The file ends with: 16 x 0xff, b"12345678", crc32(first 0x4000) little-endian,
then four constant bytes. Only the 16 KB script block is covered, so a patched
script needs this field updated or mboot silently refuses the image.

  ./fix_footer_crc.py rom/foo.bin            # dry run, prints both values
  ./fix_footer_crc.py rom/foo.bin --apply    # write the new checksum
"""

import os
import sys
import zlib

BLOCK = 0x4000
MAGIC = b'12345678'
TAIL = 160


def main(argv):
    if len(argv) < 2:
        print(__doc__.strip())
        return 2
    path = argv[1]
    apply = '--apply' in argv[2:]

    size = os.path.getsize(path)
    with open(path, 'rb') as f:
        block = f.read(BLOCK)
        f.seek(-TAIL, os.SEEK_END)
        tail = f.read()

    pos = tail.rfind(MAGIC)
    if pos < 0:
        print('no trailer magic in last %d bytes' % TAIL)
        return 1

    want = zlib.crc32(block)
    have = int.from_bytes(tail[pos + 8:pos + 12], 'little')
    print('%s' % path)
    print('  script crc32 : %08x' % want)
    print('  stored crc32 : %08x  %s' % (have, 'ok' if have == want else 'MISMATCH'))

    if not apply:
        return 0 if have == want else 1
    if have == want:
        print('  nothing to do')
        return 0

    with open(path, 'r+b') as f:
        f.seek(size - TAIL + pos + 8)
        f.write(want.to_bytes(4, 'little'))
    print('  updated')
    return 0


if __name__ == '__main__':
    sys.exit(main(sys.argv))
