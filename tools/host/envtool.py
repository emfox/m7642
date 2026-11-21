#!/usr/bin/env python3
"""Read and rewrite an mboot environment block.

The m7642 keeps its environment in two 64 KiB blocks on the eMMC, at byte
offsets 0x9e0000 (primary) and 0x9f0000 (backup).  Both were byte-identical
when captured.  The cmdline the bootloader hands to Linux says so itself:

	ENV=EMMC ENV_VAR_OFFSET=0x0 ENV_VAR_SIZE=0x10000

Layout of one block:

	0x0000  crc32 of bytes [0x0004:0x10000], little endian
	0x0004  key=value, NUL separated, zero padded to 0x10000

The CRC was found by brute force, not guessed: zlib.crc32 over the whole
64 KiB minus the first four bytes reproduces the stamp exactly on both
copies.  Rewriting is therefore safe as long as the CRC is recomputed.

	envtool.py list  <block>
	envtool.py get   <block> <key>
	envtool.py set   <block> <key>=<value> [<key>=<value> ...]
	envtool.py verify <block>
"""
import struct
import sys
import zlib

BODY = 0x10000
DATA = 4


def stamp(blk):
    return struct.pack("<I", zlib.crc32(bytes(blk[DATA:BODY])) & 0xFFFFFFFF)


def parse(blk):
    items = []
    for tok in bytes(blk[DATA:BODY]).split(b"\0"):
        if not tok:
            continue
        key, _, val = tok.partition(b"=")
        items.append((key, val))
    return items


def build(items):
    blk = bytearray(BODY)
    off = DATA
    for key, val in items:
        ent = key + b"=" + val + b"\0"
        if off + len(ent) > BODY:
            raise SystemExit("environment overflows 64 KiB")
        blk[off:off + len(ent)] = ent
        off += len(ent)
    blk[0:DATA] = stamp(blk)
    return blk


def load(path):
    blk = bytearray(open(path, "rb").read())
    if len(blk) != BODY:
        raise SystemExit("%s is %d bytes, expected %d" % (path, len(blk), BODY))
    return blk


def main(argv):
    if len(argv) < 3:
        raise SystemExit(__doc__)
    cmd, path = argv[1], argv[2]
    blk = load(path)

    if cmd == "list":
        for i, (k, v) in enumerate(parse(blk), 1):
            print("%3d  %-34s %s" % (i, k.decode("latin1"), v.decode("latin1")))
        print("crc %s  %d entries" % (blk[0:DATA].hex(), len(parse(blk))))

    elif cmd == "get":
        want = argv[3].encode()
        hit = [v for k, v in parse(blk) if k == want]
        if not hit:
            raise SystemExit("no such key: %s" % argv[3])
        print(hit[0].decode("latin1"))

    elif cmd == "set":
        items = parse(blk)
        for arg in argv[3:]:
            key, _, val = arg.partition("=")
            kb, vb = key.encode(), val.encode()
            for i, (k, _) in enumerate(items):
                if k == kb:
                    items[i] = (kb, vb)
                    break
            else:
                items.append((kb, vb))
        new = build(items)
        open(path, "wb").write(new)
        print("wrote %s  crc %s" % (path, new[0:DATA].hex()))

    elif cmd == "verify":
        ok = bytes(blk[0:DATA]) == stamp(blk)
        print("%s  stamp %s" % ("OK" if ok else "MISMATCH", blk[0:DATA].hex()))
        raise SystemExit(0 if ok else 1)

    else:
        raise SystemExit(__doc__)


if __name__ == "__main__":
    main(sys.argv)
