import os
p=os.path.expanduser("~/Debian/m7642/tools/host/mk-mainline-abort.py"); s=open(p).read()
if "--word" not in s:
    s=s.replace('''    ap.add_argument("--patch", action="append", default=[],''','''    ap.add_argument("--word", action="append", default=[],
                    help="OFF=VALUE: write a raw 32-bit instruction")
    ap.add_argument("--patch", action="append", default=[],''')
    s=s.replace('''    if a.patch:''','''    for spec in a.word:
        off, _, val = spec.partition("=")
        o, v = int(off, 0), int(val, 0)
        assert 0 <= o < len(code)
        struct.pack_into("<I", code, o, v)
        print("word at %#x = %#010x" % (o, v))
    if a.patch:''')
    open(p,"w").write(s); print("patcher: --word")
