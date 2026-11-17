import zlib, os

BLK = 0x4000
p = 'V8-T652T03-LF1V147.bin'
size = os.path.getsize(p)
with open(p, 'rb') as f:
    f.seek(-160, os.SEEK_END)
    t = f.read()
base = size - 160

# locate the 0xFF run that precedes the magic
i = t.rfind(b'\xff' * 16)
print("footer starts at 0x%x (file offset)" % (base + i))
print("footer hex:", t[i:i + 64].hex())
print("footer ascii:", t[i:i + 64])
with open(p, 'rb') as f:
    blk = f.read(BLK)
print("crc32(block) = %08x" % zlib.crc32(blk))
print("magic '12345678' at footer+%d" % t.find(b'12345678', i))
print("script copy starts at footer+%d, text %r" % (t.find(b'#----', i), t[t.find(b'#----', i):t.find(b'#----', i) + 34]))
