import hashlib

BLK = 0x4000


def block(p):
    with open(p, 'rb') as f:
        return f.read(BLK)


def text_end(b):
    i = 0
    while i < len(b) and b[i] != 0xFF:
        i += 1
    return i


orig = block('V8-T652T03-LF1V147.bin')
te = text_end(orig)
print("script text ends at 0x%x (%d B), block 0x%x, pad byte 0x%02x" % (te, te, BLK, orig[te]))
print("first 0x20 of block:", orig[:0x20].hex())

# look for a stored digest of the script text anywhere in the first 64 KB
with open('V8-T652T03-LF1V147.bin', 'rb') as f:
    head64k = f.read(0x10000)

cands = {
    'md5(text)': hashlib.md5(orig[:te]).digest(),
    'sha1(text)': hashlib.sha1(orig[:te]).digest(),
    'sha256(text)': hashlib.sha256(orig[:te]).digest(),
    'md5(blk)': hashlib.md5(orig).digest(),
    'sha256(blk)': hashlib.sha256(orig).digest(),
}
for name, d in cands.items():
    pos = head64k.find(d)
    print("%-14s -> %s" % (name, ("found at 0x%x" % pos) if pos >= 0 else "not present"))

v4 = block('V8-T652T03-LF1V147-v4.bin')
diff = [k for k in range(BLK) if orig[k] != v4[k]]
print("v4: %d bytes differ, range 0x%x..0x%x" % (len(diff), diff[0], diff[-1]))
print("v4 text end 0x%x (delta %+d)" % (text_end(v4), text_end(v4) - te))
