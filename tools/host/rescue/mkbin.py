#!/usr/bin/env python3
"""Build an MStar USB upgrade BIN (MstarUpgrade.bin) from a script and payloads.

Layout, checked byte for byte against the vendor package
V8-T652T03-LF1V147.bin:

    0x0000  16 KiB script, text then 0xFF filler
    0x4000  payload, concatenated in script order
    EOF-32  footer

Footer (32 bytes):

    "12345678" | u32 crc32(header) | u32 product tag | header[0:16]

Offsets in the script are absolute file offsets, so the first payload block
starts at 0x4000.  The product tag is a constant the vendor puts in every
package of this model; it is not a checksum of the payload (two packages with
different system images share it).
"""

import argparse
import os
import struct
import sys
import zlib

HEADER_SIZE = 0x4000
MAGIC = b"12345678"
PRODUCT_TAG = 0xB74AABBA


def script_for(parts):
    """parts: [(partition, path, keep_flag)] -> script lines."""
    lines = ["#-------------USB Upgrade Bin Info----------------",
             "# Device : tcl_m7642",
             "# Build PATH : local rescue image",
             ""]
    off = HEADER_SIZE
    for name, path, flag in parts:
        size = os.path.getsize(path)
        lines.append("# File Partition: %s" % name)
        lines.append("filepartload 0x55000000 $(UpgradeImage) 0x%x 0x%x" % (off, size))
        lines.append("mmc erase.p %s" % name)
        lines.append("mmc write.p 0x55000000 %s 0x%x%s" %
                     (name, size, " 1" if flag else ""))
        lines.append("")
        off += size
    return lines


def build(lines, payload_paths, out, tag=PRODUCT_TAG):
    header = ("\n".join(lines) + "\n% <- this is end of script symbol\n").encode()
    if len(header) > HEADER_SIZE:
        sys.exit("script does not fit in 16 KiB")
    header += b"\xff" * (HEADER_SIZE - len(header))

    payload = b"".join(open(p, "rb").read() for p in payload_paths)
    footer = (MAGIC + struct.pack("<I", zlib.crc32(header) & 0xFFFFFFFF) +
              struct.pack("<I", tag) + header[:16])

    with open(out, "wb") as f:
        f.write(header)
        f.write(payload)
        f.write(footer)
    return len(header) + len(payload) + len(footer)


def main():
    ap = argparse.ArgumentParser(
        description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("-o", "--out", required=False, help="output file (not needed with --dry-run)")
    ap.add_argument("-p", "--part", action="append", default=[],
                    metavar="NAME=FILE[:1]",
                    help="partition to erase and write; append :1 for the vendor's trailing flag")
    ap.add_argument("--tag", type=lambda s: int(s, 0), default=PRODUCT_TAG)
    ap.add_argument("--dry-run", action="store_true")
    a = ap.parse_args()

    parts, paths = [], []
    for spec in a.part:
        name, rest = spec.split("=", 1)
        flag = rest.endswith(":1")
        path = rest[:-2] if flag else rest
        if not os.path.exists(path):
            sys.exit("missing payload: %s" % path)
        parts.append((name, path, flag))
        paths.append(path)

    lines = script_for(parts)
    if a.dry_run:
        print("\n".join(lines))
        return
    if not a.out:
        sys.exit("-o is required unless --dry-run")
    total = build(lines, paths, a.out, a.tag)
    print("%s: %d bytes (payload %d)" %
          (a.out, total, sum(os.path.getsize(p) for p in paths)))


if __name__ == "__main__":
    main()
