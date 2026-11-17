#!/usr/bin/env python3
"""Build the patched TCL/MStar .bin.

Three edits, all inside system.img:

  1. /system/etc/prop.default  - append the install switches (slack space)
  2. /init.rc                  - append the setuid-root block (slack space)
  3. /system/bin/su            - a new fast symlink -> /factory/su

(1) and (2) grow i_size inside existing blocks. (3) allocates one free inode,
sets its bit in the inode bitmap, decrements the group's free counter and
recomputes the gdt checksum, then splits the last directory entry. No data
block is allocated: a symlink whose target fits 60 bytes lives in i_block.
"""

import shutil
import struct

import ext4write as W
import mstarbin as M
from ext4 import Ext4

BIN = '../rom/V8-T652T03-LF1V147.bin'
OUT = '../rom/V8-T652T03-LF1V147-root.bin'

PROP = '/system/etc/prop.default'
PROP_ADD = (b'persist.tcl.debug.installapk=1\n'
            b'persist.tcl.debug.installapk.enable=1\n'
            b'persist.tcl.installapk.enable=1\n')

RC = '/init.rc'
RC_ADD = (b'\n'
          b'# offline patch: setuid root shell at /factory/su\n'
          b'on property:sys.boot_completed=1\n'
          b'    rm /factory/su\n'
          b'    copy /system/bin/sh /factory/su\n'
          b'    chown root root /factory/su\n'
          b'    chmod 6755 /factory/su\n')

LINK_DIR = '/system/bin'
LINK_NAME = b'su'
LINK_TARGET = b'/factory/su'
EXT4_FT_SYMLINK = 7


def slice_index(bin_path, part):
    out = []
    with open(bin_path, 'rb') as src:
        for off, ln in part['chunks']:
            src.seek(off)
            out.append((off, M._SparseBytes(src.read(ln))))
    return out


def locate(slices, blk):
    hits = []
    for seg_off, s in slices:
        for c in s.chunks:
            if c['blk_start'] <= blk < c['blk_start'] + c['blk_count']:
                if c['type'] == M.CHUNK_RAW:
                    hits.append(seg_off + c['file_off']
                                + (blk - c['blk_start']) * s.blk)
    return hits


def write_fs(fs, slices, fs_off, data):
    """Patch `data` at an absolute filesystem offset (may span blocks)."""
    patches = []
    pos, i = fs_off, 0
    while i < len(data):
        blk, inner = divmod(pos, fs.block_size)
        n = min(fs.block_size - inner, len(data) - i)
        hits = locate(slices, blk)
        if not hits:
            raise SystemExit('block %d has no RAW copy' % blk)
        for base in hits:
            patches.append((base + inner, data[i:i + n]))
        pos += n
        i += n
    return patches


def blocks_flat(fs, ino):
    out = []
    for e in fs.blocks_of(ino):
        out.extend(range(e[0], e[0] + e[1]))
    return out


def append_to_file(fs, slices, path, add):
    ino_num = fs.resolve(path)
    ino = fs.inode(ino_num)
    data = fs.read_inode(ino)
    if add in data:
        print('%-26s already patched, skipped' % path)
        return []

    flat = blocks_flat(fs, ino)
    cap = len(flat) * fs.block_size
    old_len, new_len = len(data), len(data) + len(add)
    if new_len > cap:
        raise SystemExit('%s: needs %d B, block capacity is %d B'
                         % (path, new_len, cap))

    patches = []
    pos, i = old_len, 0
    while i < len(add):
        bi, bo = divmod(pos, fs.block_size)
        chunk = min(fs.block_size - bo, len(add) - i)
        hits = locate(slices, flat[bi])
        if not hits:
            raise SystemExit('%s: block %d has no RAW copy' % (path, flat[bi]))
        for base in hits:
            patches.append((base + bo, add[i:i + chunk]))
        i += chunk
        pos += chunk

    g = (ino_num - 1) // fs.inodes_per_group
    idx = (ino_num - 1) % fs.inodes_per_group
    ino_byte = fs.inode_table(g) * fs.block_size + idx * fs.inode_size
    ino_blk, ino_inner = divmod(ino_byte, fs.block_size)
    hits = locate(slices, ino_blk)
    if not hits:
        raise SystemExit('%s: inode table block has no RAW copy' % path)
    for base in hits:
        patches.append((base + ino_inner + 4, struct.pack('<I', new_len)))

    print('%-26s inode=%-5d %5d -> %5d B  (slack %d)  %d patches'
          % (path, ino_num, old_len, new_len, cap - new_len, len(patches)))
    return patches


def gd(fs, g):
    return fs._read(fs.gdt_off + g * fs.desc_size, fs.desc_size)


def first_free_inode(fs):
    groups = (fs.inodes_count + fs.inodes_per_group - 1) // fs.inodes_per_group
    for g in range(groups):
        d = gd(fs, g)
        free, = struct.unpack_from('<H', d, 14)
        if not free:
            continue
        bm, = struct.unpack_from('<I', d, 4)
        bits = fs._read(bm * fs.block_size, fs.block_size)
        for i, byte in enumerate(bits):
            if byte != 0xFF:
                for bit in range(8):
                    if not (byte >> bit) & 1:
                        return g, i * 8 + bit, bm
    raise SystemExit('no free inode in any group')


def add_symlink(fs, slices, dirpath, name, target):
    """Create a fast symlink; returns patches."""
    dir_ino = fs.resolve(dirpath)
    if name.decode() in fs.ls(fs.inode(dir_ino)):
        print('%-26s already exists, skipped'
              % (dirpath + '/' + name.decode()))
        return []

    g, idx, bm_blk = first_free_inode(fs)
    ino_num = g * fs.inodes_per_group + idx + 1
    free_before, = struct.unpack_from('<H', gd(fs, g), 14)

    # template: an existing fast symlink keeps osd2/extra fields sane
    tmpl_off = fs.inode(fs.ls(fs.inode(2))['default.prop'])['inode_off']
    buf = bytearray(fs._read(tmpl_off, fs.inode_size))
    struct.pack_into('<H', buf, 0, 0o120777)     # i_mode
    struct.pack_into('<H', buf, 2, 0)            # i_uid
    struct.pack_into('<H', buf, 24, 0)           # i_gid
    struct.pack_into('<I', buf, 4, len(target))  # i_size_lo
    struct.pack_into('<I', buf, 108, 0)          # i_size_high
    struct.pack_into('<H', buf, 26, 1)           # i_links_count
    struct.pack_into('<I', buf, 28, 0)           # i_blocks_lo
    struct.pack_into('<I', buf, 32, 0)           # i_flags
    struct.pack_into('<I', buf, 104, 0)          # i_file_acl_lo
    buf[40:100] = target.ljust(60, b'\0')        # i_block: fast symlink

    patches = write_fs(fs, slices,
                       fs.inode_table(g) * fs.block_size + idx * fs.inode_size,
                       bytes(buf))

    bit_off = bm_blk * fs.block_size + idx // 8
    old = fs._read(bit_off, 1)[0]
    patches += write_fs(fs, slices, bit_off, bytes([old | (1 << (idx % 8))]))

    d = bytearray(gd(fs, g))
    struct.pack_into('<H', d, 14, free_before - 1)
    struct.pack_into('<H', d, 0x1E, W.gdt_csum(fs.sb[104:120], g, d))
    patches += write_fs(fs, slices, fs.gdt_off + g * fs.desc_size, bytes(d))

    need = 8 + ((len(name) + 3) // 4) * 4
    best = None
    for blk in reversed(blocks_flat(fs, fs.inode(dir_ino))):
        data = fs._read(blk * fs.block_size, fs.block_size)
        off, last = 0, None
        while off + 8 <= fs.block_size:
            inum, rec, nl, ft = struct.unpack_from('<IHBB', data, off)
            if rec < 8 or off + rec > fs.block_size:
                break
            last = (off, inum, rec, nl, ft)
            off += rec
        if not last:
            continue
        o, inum, rec, nl, ft = last
        used = 8 + ((nl + 3) // 4) * 4
        if rec - used >= need:
            best = (blk, o, rec, used, rec - used)
            break
    if not best:
        raise SystemExit('%s: no directory block with %d bytes of slack'
                         % (dirpath, need))

    blk, o, rec, used, slack = best
    patches += write_fs(fs, slices, blk * fs.block_size + o + 4,
                        struct.pack('<H', used))
    entry = struct.pack('<IHBB', ino_num, slack, len(name),
                        EXT4_FT_SYMLINK) + name
    patches += write_fs(fs, slices, blk * fs.block_size + o + used, entry)

    print('%-26s inode=%-5d (g%d)  -> %s  [dir slack %d -> %d]'
          % (dirpath + '/' + name.decode(), ino_num, g,
             target.decode(), slack, slack - need))
    return patches


def main():
    script, _ = M.read_script(BIN)
    part = {p['name']: p for p in M.parse_partitions(script)}['system']
    fs = Ext4('system_raw.img')
    slices = slice_index(BIN, part)

    patches = append_to_file(fs, slices, PROP, PROP_ADD)
    patches += append_to_file(fs, slices, RC, RC_ADD)
    patches += add_symlink(fs, slices, LINK_DIR, LINK_NAME, LINK_TARGET)
    if not patches:
        print('nothing to do')
        return

    print('\ntotal patches: %d' % len(patches))
    for off, b in patches:
        print('  %#012x  %4d bytes' % (off, len(b)))

    shutil.copyfile(BIN, OUT)
    with open(OUT, 'r+b') as f:
        for off, b in patches:
            f.seek(off)
            f.write(b)
    print('\nwritten:', OUT)


if __name__ == '__main__':
    main()
