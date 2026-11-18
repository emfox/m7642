#!/usr/bin/python3
"""
Build a USB upgrade package that sets a bootloader env var and writes our
kernel into the recovery partition in one shot.

Script is the vendor recovery section verbatim, with extra `setenv` lines
prepended so the flag is in place before the write and saveenv commits it.
Payload must be exactly as large as the recovery section it replaces.

Usage: mk-setenv-bin.py <kernel-boot-image> <out.bin> [--set K=V]...
"""

import argparse
import os
import struct
import sys
import zlib

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from mkbin import HEADER_SIZE, MAGIC, PRODUCT_TAG, build  # noqa: E402

RECOVERY_LEN = 0x1A33000


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("image")
    ap.add_argument("out")
    ap.add_argument("--set", action="append", default=[], metavar="K=V")
    a = ap.parse_args()

    size = os.path.getsize(a.image)
    if size != RECOVERY_LEN:
        sys.exit("payload is %d bytes, recovery section needs %d" % (size, RECOVERY_LEN))

    lines = [
        "#-------------USB Upgrade Bin Info----------------",
        "# Device : tcl_m7642",
        "# Build PATH : local rescue image",
        "",
        "# File Partition: recovery",
        "filepartload 0x55000000 $(UpgradeImage) 0x4000 0x%x" % RECOVERY_LEN,
        "mmc erase.p misc",
        "mmc erase.p recovery",
        "mmc write.p 0x55000000 recovery 0x%X 1" % RECOVERY_LEN,
        "setenv recoverycmd mmc read.p 0x23000000 dtb 0x00100000\\; "
        "mmc read.p 0x25000000 recovery 0x02000000\\; bootm 0x25000000",
        "saveenv",
    ]

    # Env vars go last: an early saveenv aborts the script on this platform,
    # which silently skipped the partition write in the first attempt.
    for kv in a.set:
        k, _, v = kv.partition("=")
        lines.append("setenv %s %s" % (k, v))
    if a.set:
        lines.append("saveenv")

    n = build(lines, [a.image], a.out)
    print("built %s (%d bytes)" % (a.out, n))
    print("---- script ----")
    for l in lines:
        print("   " + l)
    return 0


if __name__ == "__main__":
    sys.exit(main())
