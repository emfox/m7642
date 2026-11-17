import zlib, os

BLK = 0x4000
FILES = ['V8-T652T03-LF1V147.bin', 'V8-T652T03-LF1V147-patched.bin',
         'V8-T652T03-LF1V147-v3.bin', 'V8-T652T03-LF1V147-v4.bin',
         'V8-T652T03-LF1V147-v5.bin']


def tail56(p):
    with open(p, 'rb') as f:
        f.seek(-56, os.SEEK_END)
        return f.read()


def blk(p):
    with open(p, 'rb') as f:
        return f.read(BLK)


ref = None
for p in FILES:
    if not os.path.exists(p):
        print(p, "missing")
        continue
    b = blk(p)
    t = tail56(p)
    stored = t[36:40]
    print("%-34s size=%d  crc32(blk)=%s  tail[32:56]=%s  match=%s"
          % (p, os.path.getsize(p), zlib.crc32(b).to_bytes(4, 'little').hex(),
             t[32:56].hex(), stored == zlib.crc32(b).to_bytes(4, 'little')))
