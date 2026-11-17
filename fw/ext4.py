#!/usr/bin/env python3
"""Minimal read-only ext4 parser: locate files, read them, report their blocks.
Only what is needed to patch a property file inside a raw system image."""

import struct

EXT4_MAGIC = 0xEF53
EXTENTS_FL = 0x80000
INCOMPAT_64BIT = 0x80


class Ext4:
    def __init__(self, path):
        self.path = path
        self.f = open(path, 'rb')
        sb = self._read(1024, 1024)
        self.sb = sb
        self.inodes_count, = struct.unpack_from('<I', sb, 0)
        self.blocks_count, = struct.unpack_from('<I', sb, 4)
        self.first_data_block, = struct.unpack_from('<I', sb, 20)
        log_bs, = struct.unpack_from('<I', sb, 24)
        self.block_size = 1024 << log_bs
        self.blocks_per_group, = struct.unpack_from('<I', sb, 32)
        self.inodes_per_group, = struct.unpack_from('<I', sb, 40)
        magic, = struct.unpack_from('<H', sb, 56)
        if magic != EXT4_MAGIC:
            raise ValueError('no ext4 magic')
        self.inode_size, = struct.unpack_from('<H', sb, 88)
        self.incompat, = struct.unpack_from('<I', sb, 96)
        self.desc_size = 32
        if self.incompat & INCOMPAT_64BIT:
            self.desc_size = struct.unpack_from('<H', sb, 254)[0] or 64
        self.gdt_off = (self.first_data_block + 1) * self.block_size
        self.is64 = bool(self.incompat & INCOMPAT_64BIT)

    def _read(self, off, n):
        self.f.seek(off)
        return self.f.read(n)

    def inode_table(self, group):
        d = self._read(self.gdt_off + group * self.desc_size, self.desc_size)
        lo, = struct.unpack_from('<I', d, 8)
        hi = 0
        if self.is64 and self.desc_size >= 64:
            hi, = struct.unpack_from('<I', d, 0x28)
        return (hi << 32) | lo

    def inode(self, n):
        group = (n - 1) // self.inodes_per_group
        idx = (n - 1) % self.inodes_per_group
        off = self.inode_table(group) * self.block_size + idx * self.inode_size
        raw = self._read(off, self.inode_size)
        mode, = struct.unpack_from('<H', raw, 0)
        size_lo, = struct.unpack_from('<I', raw, 4)
        size_hi, = struct.unpack_from('<I', raw, 108)
        flags, = struct.unpack_from('<I', raw, 32)
        size = (size_hi << 32) | size_lo if self.is64 else size_lo
        return {'num': n, 'mode': mode, 'size': size, 'flags': flags,
                'iblock': raw[40:100], 'inode_off': off}

    def _extents(self, iblock, out):
        magic, entries, _max, depth = struct.unpack_from('<HHHH', iblock, 0)
        if magic != 0xF30A:
            raise ValueError('not an extent tree (magic %#x)' % magic)
        if depth == 0:
            for i in range(entries):
                o = 12 + i * 12
                _lb, elen, hi, lo = struct.unpack_from('<IHHI', iblock, o)
                out.append((lo | (hi << 32), elen & 0x7FFF, elen > 32768))
        else:
            for i in range(entries):
                o = 12 + i * 12
                _lb, leaf_lo, leaf_hi, _u = struct.unpack_from('<IIHH', iblock, o)
                blk = leaf_lo | (leaf_hi << 32)
                self._extents(self._read(blk * self.block_size, self.block_size), out)
        return out

    def blocks_of(self, ino):
        if ino['flags'] & EXTENTS_FL:
            return self._extents(ino['iblock'], [])
        return self._classic(ino['iblock'], ino['size'])

    def _classic(self, iblock, size):
        """Old-style i_block[15]: 12 direct + single/double/triple indirect."""
        ptrs = struct.unpack('<15I', iblock)
        need = (size + self.block_size - 1) // self.block_size
        out = []

        def add(blk):
            if blk and len(out) < need:
                out.append((blk, 1, False))

        for i in range(12):
            add(ptrs[i])
        per = self.block_size // 4

        def walk(blk, depth):
            if not blk or len(out) >= need:
                return
            tbl = struct.unpack('<%dI' % per,
                                self._read(blk * self.block_size, self.block_size))
            for v in tbl:
                if len(out) >= need:
                    return
                if depth == 1:
                    add(v)
                else:
                    walk(v, depth - 1)

        walk(ptrs[12], 1)
        walk(ptrs[13], 2)
        walk(ptrs[14], 3)
        return out

    def read_inode(self, ino):
        if (ino['mode'] & 0xF000) == 0xA000 and ino['size'] <= 60:
            return ino['iblock'][:ino['size']]          # fast symlink
        data = b''.join(self._read(b * self.block_size, ln * self.block_size)
                        for b, ln, _u in self.blocks_of(ino))
        return data[:ino['size']]

    def ls(self, ino):
        data = self.read_inode(ino)
        out = {}
        off = 0
        while off + 8 <= len(data):
            inum, rec_len, name_len, _ft = struct.unpack_from('<IHBB', data, off)
            if rec_len < 8 or off + rec_len > len(data):
                # dx_root or padding: jump to next block
                off = (off // self.block_size + 1) * self.block_size
                continue
            if inum and 0 < name_len <= 255:
                name = data[off + 8:off + 8 + name_len]
                out[name.decode('utf-8', 'replace')] = inum
            off += rec_len
        return out

    def resolve(self, path, depth=0):
        if depth > 8:
            raise IOError('symlink loop at %s' % path)
        cur = 2
        parts = [p for p in path.split('/') if p]
        for i, part in enumerate(parts):
            entries = self.ls(self.inode(cur))
            if part not in entries:
                raise FileNotFoundError('%s (in %s, have: %s)'
                                        % (part, '/'.join(parts[:i]) or '/',
                                           ', '.join(sorted(entries)[:40])))
            cur = entries[part]
            ino = self.inode(cur)
            if (ino['mode'] & 0xF000) == 0xA000:
                target = self.read_inode(ino).decode()
                rest = '/'.join(parts[i + 1:])
                joined = target + ('/' + rest if rest else '')
                return self.resolve(joined, depth + 1)
        return cur
