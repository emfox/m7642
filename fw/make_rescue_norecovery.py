#!/usr/bin/env python3
"""Comment out the recovery writes in a MStar rescue .bin, keeping offsets intact.

Why: after a crash the only way back to Android is the USB rescue package, but
that package rewrites the recovery slot with the vendor image, which destroys
the very evidence we need ("was our image still in the slot after the boot?").
Dropping only the recovery lines lets the slot survive the rescue.

Every replacement is the same length as the original line, so the payload
offsets in the file do not move and only the trailer CRC changes.

  python3 make_rescue_norecovery.py IN.bin OUT.bin
"""

import os
import shutil
import subprocess
import sys
import zlib

BLOCK = 0x4000
MAGIC = b'12345678'


def comment(line: bytes) -> bytes:
    """Turn a line into a comment of exactly the same length."""
    body = line.rstrip(b'\r\n')
    crlf = line[len(body):]
    return b'#' + b' ' * (len(body) - 1) + crlf


def main(argv):
    if len(argv) < 3:
        print(__doc__.strip())
        return 2
    src, dst = argv[1], argv[2]

    data = bytearray(open(src, 'rb').read())
    block = bytes(data[:BLOCK])

    lines = block.split(b'\n')
    hit = 0
    out = []
    for ln in lines:
        s = ln.strip()
        if s.startswith(b'filepartload') and b'0xA000' in s and b'0x1A33000' in s:
            out.append(comment(ln)); hit += 1
        elif s.startswith(b'mmc erase.p recovery'):
            out.append(comment(ln)); hit += 1
        elif s.startswith(b'mmc write.p') and b'recovery' in s:
            out.append(comment(ln)); hit += 1
        else:
            out.append(ln)

    if hit != 3:
        print("expected to comment 3 recovery lines, got %d -- aborting" % hit)
        return 1

    new_block = b'\n'.join(out)
    assert len(new_block) == len(block), "block length changed (%d != %d)" % (len(new_block), len(block))
    data[:BLOCK] = new_block

    # trailer: 16 x 0xff, b"12345678", crc32(first 0x4000) little-endian, 4 const
    tail = bytes(data[-160:])
    pos = tail.rfind(MAGIC)
    if pos < 0:
        print("no trailer magic")
        return 1
    crc = zlib.crc32(new_block) & 0xFFFFFFFF
    off = len(data) - 160 + pos + 8
    old = int.from_bytes(data[off:off + 4], 'little')
    data[off:off + 4] = crc.to_bytes(4, 'little')
    print("commented %d recovery lines" % hit)
    print("script crc32 %08x -> %08x" % (old, crc))

    open(dst, 'wb').write(bytes(data))
    print("size  %d (unchanged: %s)" % (len(data), len(data) == os.path.getsize(src)))
    print("wrote %s" % dst)
    return 0


if __name__ == '__main__':
    sys.exit(main(sys.argv))
