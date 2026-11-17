#!/usr/bin/env python3
"""Build ext4 primitives needed to add one fast symlink: crc16 (gdt_csum),
inode bitmap bookkeeping and directory entry splitting.
Verified against the on-disk checksums before any write happens."""

import struct

# CRC-16/IBM (poly 0xA001, reflected), same table ext4 uses for gdt_csum.
_TABLE = []
for _i in range(256):
    _c = _i
    for _ in range(8):
        _c = (_c >> 1) ^ 0xA001 if _c & 1 else _c >> 1
    _TABLE.append(_c)


def crc16(crc, data):
    for b in data:
        crc = (crc >> 8) ^ _TABLE[(crc ^ b) & 0xFF]
    return crc & 0xFFFF


def gdt_csum(sb_uuid, group, gd_bytes):
    """ext4_group_desc_csum() with s_feature_ro_compat GDT_CSUM set."""
    c = crc16(0xFFFF, sb_uuid)
    c = crc16(c, struct.pack('<I', group))
    return crc16(c, gd_bytes[:0x1E])


def verify(fs, groups=5):
    """Compare computed checksums with what is stored on disk."""
    ok = True
    for g in range(groups):
        off = fs.gdt_off + g * fs.desc_size
        d = fs._read(off, fs.desc_size)
        stored, = struct.unpack_from('<H', d, 0x1E)
        calc = gdt_csum(fs.sb[104:120], g, d)
        flag = 'OK' if calc == stored else 'MISMATCH'
        if calc != stored:
            ok = False
        print('  group %d: stored=%#06x calc=%#06x  %s' % (g, stored, calc, flag))
    return ok
