#!/usr/bin/env python3
"""Carve a subset of partitions out of a vendor upgrade BIN into a small BIN.

The vendor package carries ~20 partition sections in one 3.3 GB file. For a
partial upgrade we only want a few of them, and a 3.3 GB file on the USB stick
makes every experiment slow. This tool re-emits the requested sections in a
fresh, much smaller package:

    ./mk-partial.py --src V8-....bin --keep recovery,set_config -o out.bin

Only `filepartload` offsets are rewritten (payload is re-packed from 0x4000);
every other script line is copied verbatim, and the AllBinCRC field keeps the
vendor's value -- mboot does not enforce it (proved with the v5 package).

Package name on the stick must still match V8-*.bin, otherwise mboot never
reads the file at all; see Documentation/mstar/m7642/flash-and-recovery.md.
"""

import argparse
import os
import struct
import sys
import zlib

HEADER_SIZE = 0x4000
MAGIC = b"12345678"


def read_script(path):
    with open(path, "rb") as f:
        block = f.read(HEADER_SIZE)
    return block.split(b"\xff", 1)[0].decode("latin1")


def split_sections(text):
    """-> [(name, [lines])]; lines before the first header get name '__pre__'."""
    out = [("__pre__", [])]
    for ln in text.splitlines(keepends=True):
        if ln.startswith("# File Partition:"):
            out.append((ln.split(":", 1)[1].strip(), [ln]))
        else:
            out[-1][1].append(ln)
    return out


def blocks_of(lines):
    """-> [(offset, size)] for every filepartload in a section."""
    res = []
    for ln in lines:
        tok = ln.split()
        if tok and tok[0] == "filepartload":
            res.append((int(tok[3], 16), int(tok[4], 16)))
    return res


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--src", required=True)
    ap.add_argument("--keep", required=True,
                    help="comma separated partition names, in payload order")
    ap.add_argument("--extra", action="append", default=[],
                    help="extra script line appended before the end marker; repeatable")
    ap.add_argument("-o", "--out")
    ap.add_argument("--dry-run", action="store_true")
    a = ap.parse_args()

    size = os.path.getsize(a.src)
    text = read_script(a.src)
    sections = {n: l for n, l in split_sections(text)}
    if "__pre__" not in sections:
        sys.exit("no script found in %s" % a.src)

    with open(a.src, "rb") as f:
        f.seek(size - 32)
        foot = f.read(32)
    if foot[:8] != MAGIC:
        sys.exit("footer magic not at EOF-32")

    keep = [s.strip() for s in a.keep.split(",") if s.strip()]
    missing = [k for k in keep if k not in sections]
    if missing:
        sys.exit("no such section(s): %s" % ", ".join(missing))

    off = HEADER_SIZE
    plan = []           # [(src_offset, size)]
    lines = list(sections["__pre__"])
    for name in keep:
        for ln in sections[name]:
            tok = ln.split()
            if tok and tok[0] == "filepartload":
                src_off, blk = int(tok[3], 16), int(tok[4], 16)
                if src_off + blk > size - 32:
                    sys.exit("%s block past EOF" % name)
                tok[3] = "0x%x" % off
                ln = " ".join(tok) + "\n"
                plan.append((src_off, blk))
                off += blk
            lines.append(ln)

    body = "".join(lines).rstrip("\n") + "\n"
    MARK = "% <- this is end of script symbol"
    if MARK in body:
        body = body.split(MARK)[0].rstrip("\n") + "\n"
    for extra in a.extra:
        body += extra.rstrip("\n") + "\n"
    body += MARK + "\n"
    header = body.encode("latin1")
    if len(header) > HEADER_SIZE:
        sys.exit("script does not fit in 16 KiB")
    header += b"\xff" * (HEADER_SIZE - len(header))

    payload = sum(b for _, b in plan)
    print("sections  : %s" % ", ".join(keep))
    print("script    : %d bytes -> %d used / %d" % (len(text), len(body), HEADER_SIZE))
    print("payload   : %d bytes in %d block(s)" % (payload, len(plan)))
    print("total     : %d bytes" % (HEADER_SIZE + payload + 32))
    print("crc       : 0x%08x  allbincrc 0x%08x" %
          (zlib.crc32(header) & 0xFFFFFFFF, struct.unpack("<I", foot[12:16])[0]))
    if a.dry_run:
        print("---- script ----")
        print(body)
        return
    if not a.out:
        sys.exit("-o is required unless --dry-run")

    with open(a.src, "rb") as src, open(a.out, "wb") as dst:
        dst.write(header)
        for src_off, blk in plan:
            src.seek(src_off)
            left = blk
            while left:
                chunk = src.read(min(1 << 22, left))
                if not chunk:
                    sys.exit("short read at 0x%x" % src_off)
                dst.write(chunk)
                left -= len(chunk)
        footer = MAGIC + struct.pack("<I", zlib.crc32(header) & 0xFFFFFFFF) + foot[12:32]
        dst.write(footer)
    print("wrote %s" % a.out)


if __name__ == "__main__":
    main()
