#!/usr/bin/env python3
"""MStar/TCL .bin toolbox: parse the mboot upgrade script, extract partition
payloads, and address Android sparse images at raw-byte granularity."""

import re
import struct

SCRIPT_END = b'% <- this is end of script symbol'


def read_script(path):
    """Return (script_text, script_len). Data area starts after this."""
    with open(path, 'rb') as f:
        buf = f.read(1 << 20)
    end = 0
    while end < len(buf) and (32 <= buf[end] <= 126 or buf[end] in (9, 10, 13)):
        end += 1
    return buf[:end].decode('ascii'), end


def parse_partitions(script):
    """Ordered list of {name, chunks[(offset, length)], writes[]}."""
    out = []
    cur = None
    for line in script.splitlines():
        m = re.match(r'#\s*File Partition:\s*(\S+)', line)
        if m:
            cur = {'name': m.group(1), 'chunks': [], 'cmds': []}
            out.append(cur)
            continue
        if cur is None:
            continue
        m = re.match(r'filepartload\s+\S+\s+\$\(UpgradeImage\)\s+'
                     r'(0x[0-9a-fA-F]+)\s+(0x[0-9a-fA-F]+)', line)
        if m:
            cur['chunks'].append((int(m.group(1), 16), int(m.group(2), 16)))
            continue
        if line.startswith('mmc ') or line.startswith('setenv '):
            cur['cmds'].append(line)
    return out


def extract(path, part, dest):
    """Concatenate a partition's chunk payloads (chunks are 4K-aligned in file)."""
    n = 0
    with open(path, 'rb') as src, open(dest, 'wb') as dst:
        for off, length in part['chunks']:
            src.seek(off)
            left = length
            while left:
                buf = src.read(min(1 << 20, left))
                if not buf:
                    raise IOError('short read at %#x' % off)
                dst.write(buf)
                left -= len(buf)
            n += length
    return n


# ---- Android sparse image ----

SPARSE_MAGIC = 0xED26FF3A
CHUNK_RAW, CHUNK_FILL, CHUNK_DONT_CARE, CHUNK_CRC32 = 0xCAC1, 0xCAC2, 0xCAC3, 0xCAC4


class Sparse:
    def __init__(self, path):
        self.path = path
        with open(path, 'rb') as f:
            hdr = f.read(28)
        (magic, major, minor, fhsz, chsz, blk, total_blks,
         total_chunks, _chk) = struct.unpack('<IHHHHIIII', hdr)
        if magic != SPARSE_MAGIC:
            raise ValueError('not a sparse image')
        self.blk, self.total_blks, self.total_chunks = blk, total_blks, total_chunks
        self.chunks = []
        with open(path, 'rb') as f:
            f.seek(fhsz)
            raw_blk = 0
            for _ in range(total_chunks):
                ctype, _r, csz, tsz = struct.unpack('<HHII', f.read(chsz))
                data_off = f.tell()
                self.chunks.append({'type': ctype, 'blk_start': raw_blk,
                                    'blk_count': csz, 'file_off': data_off,
                                    'total_sz': tsz})
                raw_blk += csz
                f.seek(data_off + tsz - chsz)
        self.raw_size = total_blks * blk

    def map(self, raw_off):
        """Raw byte offset -> file offset. RAW chunks only."""
        blk = raw_off // self.blk
        inner = raw_off % self.blk
        for c in self.chunks:
            if c['blk_start'] <= blk < c['blk_start'] + c['blk_count']:
                if c['type'] != CHUNK_RAW:
                    raise ValueError('raw offset %#x lands in chunk type %#x'
                                     % (raw_off, c['type']))
                return c['file_off'] + (blk - c['blk_start']) * self.blk + inner
        raise ValueError('raw offset %#x out of range' % raw_off)

    def to_raw(self, dest):
        with open(self.path, 'rb') as src, open(dest, 'wb') as dst:
            for c in self.chunks:
                if c['type'] == CHUNK_RAW:
                    src.seek(c['file_off'])
                    left = c['blk_count'] * self.blk
                    while left:
                        buf = src.read(min(1 << 20, left))
                        dst.write(buf)
                        left -= len(buf)
                elif c['type'] == CHUNK_FILL:
                    src.seek(c['file_off'])
                    fill = src.read(4)
                    dst.write(fill * (c['blk_count'] * self.blk // 4))
                elif c['type'] == CHUNK_DONT_CARE:
                    dst.write(b'\x00' * (c['blk_count'] * self.blk))
                else:
                    continue
        return self.raw_size

    def describe(self):
        from collections import Counter
        cnt = Counter(c['type'] for c in self.chunks)
        return ('blk=%d total_blks=%d chunks=%d raw_size=%d types=%s'
                % (self.blk, self.total_blks, self.total_chunks,
                   self.raw_size, dict(cnt)))


def split_segments(path, part):
    """Yield (file_offset, length) payload segments. Each segment of a sliced
    partition is itself a whole sparse image describing the same address space."""
    for off, length in part['chunks']:
        yield off, length


def assemble_raw(bin_path, part, dest):
    """Overlay every sparse segment onto one zero canvas.

    Sliced partitions are stored as N sparse images that each cover the full
    address range but carry data only for their own slice (rest is DONT_CARE).
    Concatenating them is wrong; they must be overlaid.
    """
    canvas = None
    with open(bin_path, 'rb') as src, open(dest, 'wb') as out:
        for off, length in part['chunks']:
            src.seek(off)
            seg = src.read(length)
            s = _SparseBytes(seg)
            if canvas is None:
                canvas = s.raw_size
                out.truncate(canvas)          # sparse file of zeros
            elif canvas != s.raw_size:
                raise ValueError('segment raw_size mismatch %d vs %d'
                                 % (s.raw_size, canvas))
            for c in s.chunks:
                if c['type'] == CHUNK_RAW:
                    out.seek(c['blk_start'] * s.blk)
                    out.write(seg[c['file_off']:c['file_off'] + c['blk_count'] * s.blk])
                elif c['type'] == CHUNK_FILL:
                    fill = seg[c['file_off']:c['file_off'] + 4]
                    out.seek(c['blk_start'] * s.blk)
                    out.write(fill * (c['blk_count'] * s.blk // 4))
                # DONT_CARE: leave the canvas untouched
    return canvas


class _SparseBytes:
    """Same as Sparse but over an in-memory segment."""

    def __init__(self, seg):
        (magic, major, minor, fhsz, chsz, blk, tb, tc,
         _ck) = struct.unpack('<IHHHHIIII', seg[:28])
        if magic != SPARSE_MAGIC:
            raise ValueError('segment is not sparse')
        self.blk, self.total_blks, self.raw_size = blk, tb, tb * blk
        self.chunks = []
        pos, raw_blk = fhsz, 0
        for _ in range(tc):
            ctype, _r, csz, tsz = struct.unpack('<HHII', seg[pos:pos + chsz])
            self.chunks.append({'type': ctype, 'blk_start': raw_blk,
                                'blk_count': csz, 'file_off': pos + chsz})
            raw_blk += csz
            pos += tsz
