import zlib, binascii

BLK = 0x4000
with open('V8-T652T03-LF1V147.bin', 'rb') as f:
    head = f.read(0x10000)
blk = head[:BLK]
te = blk.find(b'\xff')
text = blk[:te]

probes = {
    'crc32(text) LE': zlib.crc32(text).to_bytes(4, 'little'),
    'crc32(text) BE': zlib.crc32(text).to_bytes(4, 'big'),
    'crc32(blk) LE': zlib.crc32(blk).to_bytes(4, 'little'),
    'len(text) LE': len(text).to_bytes(4, 'little'),
    'len(blk) LE': BLK.to_bytes(4, 'little'),
}
for name, pat in probes.items():
    print("%-16s %s -> %s" % (name, pat.hex(), head.find(pat)))

with open('V8-T652T03-LF1V147.bin', 'rb') as f:
    f.seek(-64, 2)
    print("file tail 64B:", f.read().hex())
