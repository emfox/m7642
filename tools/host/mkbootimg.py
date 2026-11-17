#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-2.0
"""Build an Android boot image for the m7642 TCL 65S535D.

The defaults are the values read back from the vendor boot partition
(mmcblk0p8), not guesses from the Android documentation:

    kernel_addr   0x20280000
    tags_addr     0x20280100
    page_size     2048
    header v1, ramdisk and second stage empty

The device tree is NOT part of this image; the bootloader reads it from the
separate "dtb" partition.  See Documentation/mstar/m7642/boot-test.md.
"""

import argparse
import hashlib
import struct
import sys

PAGE = 2048
HEADER_V1 = 1648


def pad(data, page=PAGE):
    rem = len(data) % page
    return data if rem == 0 else data + b"\x00" * (page - rem)


def build(kernel, ramdisk, cmdline, kernel_addr, tags_addr, name):
    if len(kernel) + len(ramdisk) > 32 * 1024 * 1024:
        sys.exit("kernel+ramdisk larger than the 32 MB partition")

    hdr = bytearray(HEADER_V1)
    struct.pack_into("<8s", hdr, 0, b"ANDROID!")
    struct.pack_into("<I", hdr, 8, len(kernel))
    struct.pack_into("<I", hdr, 12, kernel_addr)
    struct.pack_into("<I", hdr, 16, len(ramdisk))  # ramdisk_size
    struct.pack_into("<I", hdr, 20, 0x21280000)  # ramdisk_addr
    struct.pack_into("<I", hdr, 24, 0)          # second_size
    struct.pack_into("<I", hdr, 28, 0x21180000)  # second_addr
    struct.pack_into("<I", hdr, 32, tags_addr)
    struct.pack_into("<I", hdr, 36, PAGE)
    struct.pack_into("<I", hdr, 40, 1)          # header_version
    struct.pack_into("<I", hdr, 44, 0x12000136)  # os_version, same as vendor
    hdr[48:48 + min(len(name), 15)] = name[:15].encode()
    hdr[64:64 + min(len(cmdline), 511)] = cmdline[:511].encode()
    struct.pack_into("<I", hdr, 1632, 0)        # recovery_dtbo_size
    struct.pack_into("<Q", hdr, 1636, 0)        # recovery_dtbo_offset
    struct.pack_into("<I", hdr, 1644, HEADER_V1)  # header_size

    # The id field is 32 bytes: a SHA1 over the payloads plus their sizes,
    # padded with zeros.  Slicing exactly 32 bytes matters -- assigning a
    # 20-byte digest to a 32-byte slice would shorten the header.
    digest = hashlib.sha1()
    digest.update(kernel)
    digest.update(struct.pack("<I", len(kernel)))
    digest.update(ramdisk)
    digest.update(struct.pack("<I", len(ramdisk)))
    digest.update(struct.pack("<I", 0))
    hdr[576:596] = digest.digest()

    out = pad(bytes(hdr)) + pad(kernel)
    return out + pad(ramdisk) if ramdisk else out


def main():
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("-k", "--kernel", required=True, help="arch/arm64/boot/Image")
    ap.add_argument("-r", "--ramdisk", default=None, help="ramdisk (none for a bare kernel)")
    ap.add_argument("-o", "--output", required=True)
    ap.add_argument("-c", "--cmdline",
                    default="console=tty0 earlycon ignore_loglevel maxcpus=1")
    ap.add_argument("--kernel-addr", type=lambda s: int(s, 0), default=0x20280000)
    ap.add_argument("--tags-addr", type=lambda s: int(s, 0), default=0x20280100)
    ap.add_argument("--name", default="m7642")
    args = ap.parse_args()

    with open(args.kernel, "rb") as f:
        kernel = f.read()
    ramdisk = b""
    if args.ramdisk:
        with open(args.ramdisk, "rb") as f:
            ramdisk = f.read()

    img = build(kernel, ramdisk, args.cmdline, args.kernel_addr, args.tags_addr, args.name)
    with open(args.output, "wb") as f:
        f.write(img)

    print("%s: %d bytes (kernel %d, ramdisk %d)" % (args.output, len(img), len(kernel), len(ramdisk)))


if __name__ == "__main__":
    main()
