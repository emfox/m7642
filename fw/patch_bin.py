#!/usr/bin/env python3
"""Patch a property line into /system/etc/prop.default inside a TCL/MStar .bin.

Only two blocks are touched: the inode that carries i_size, and the file's
single data block (its slack space holds the new lines). Every length in the
container is preserved, so the mboot script needs no rewriting.
"""

import shutil
import struct
import sys

import mstarbin as M
from ext4 import Ext4

BIN = '../rom/V8-T652T03-LF1V147.bin'
PROP = '/system/etc/prop.default'
ADD = (b'persist.tcl.debug.installapk=1\n'
       b'persist.tcl.debug.installapk.enable=1\n'
       b'persist.tcl.installapk.enable=1\n')


def slice_index(bin_path, part):
    """[(segment_offset, SparseBytes)] for a sliced partition."""
    src = open(bin_path, 'rb')
    out = []
    for off, ln in part['chunks']:
        src.seek(off)
        out.append((off, M._SparseBytes(src.read(ln))))
    src.close()
    return out


def locate(slices, blk):
    """Canvas block -> list of (bin_offset_of_block_start) for RAW copies."""
    hits = []
    for seg_off, s in slices:
        for c in s.chunks:
            if c['blk_start'] <= blk < c['blk_start'] + c['blk_count']:
                if c['type'] == M.CHUNK_RAW:
                    hits.append(seg_off + c['file_off']
                                + (blk - c['blk_start']) * s.blk)
    return hits


def main():
    fs = Ext4('system_raw.img')
    ino_num = fs.resolve(PROP)
    ino = fs.inode(ino_num)
    data = fs.read_inode(ino)
    if ADD in data:
        print('already patched, nothing to do'); return
    new_len = len(data) + len(ADD)
    blk_data, nblk = fs.blocks_of(ino)[0][0], fs.blocks_of(ino)[0][1]
    assert nblk == 1, 'expected a single data block'
    assert new_len <= fs.block_size, 'would overflow the block, abort'

    # inode table location of this inode
    g = (ino_num - 1) // fs.inodes_per_group
    idx = (ino_num - 1) % fs.inodes_per_group
    ino_byte = fs.inode_table(g) * fs.block_size + idx * fs.inode_size
    ino_blk, ino_inner = divmod(ino_byte, fs.block_size)

    print('prop.default : inode=%d size=%d -> %d, block=%d (slack %d)'
          % (ino_num, len(data), new_len, blk_data, fs.block_size - len(data)))
    print('inode table  : block=%d +%#x' % (ino_blk, ino_inner))

    slices = slice_index(BIN, PART)
    patches = []           # (bin_offset, bytes)
    for base in locate(slices, blk_data):
        patches.append((base + len(data), ADD))
    for base in locate(slices, ino_blk):
        patches.append((base + ino_inner + 4, struct.pack('<I', new_len)))
    if not patches:
        raise SystemExit('no RAW slice covers the target blocks')

    print('patches: %d' % len(patches))
    for off, b in patches:
        print('  %#012x  %d bytes' % (off, len(b)))

    out_bin = '../rom/V8-T652T03-LF1V147-patched.bin'
    shutil.copyfile(BIN, out_bin)
    with open(out_bin, 'r+b') as f:
        for off, b in patches:
            f.seek(off)
            f.write(b)
    print('written:', out_bin)


if __name__ == '__main__':
    script, _ = M.read_script(BIN)
    PART = {p['name']: p for p in M.parse_partitions(script)}['system']
    main()
