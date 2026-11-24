import os, re, glob
D=os.path.expanduser("~/Debian/m7642/Documentation/mstar/m7642")
# wdt-beacon.md 重写后的新编号：§一 实验 / §二 待机切电 / §三 ramoops / §四 boot 槽通道
MAP=[("wdt-beacon.md` §十六","wdt-beacon.md` §四"),
     ("wdt-beacon.md` §十四","wdt-beacon.md` §四"),
     ("wdt-beacon.md` §十五","wdt-beacon.md` §四"),
     ("wdt-beacon.md` §十三","wdt-beacon.md` §三"),
     ("wdt-beacon.md` §十二.1","wdt-beacon.md` §一"),
     ("wdt-beacon.md` §十二","wdt-beacon.md` §三"),
     ("wdt-beacon.md` §十一","wdt-beacon.md` §二"),
     ("wdt-beacon.md` §十","wdt-beacon.md` §三"),
     ("wdt-beacon.md` §九","wdt-beacon.md` §二"),
     ("wdt-beacon.md` §八","wdt-beacon.md` §一"),
     ("wdt-beacon.md` §六","wdt-beacon.md` §一"),
     ("wdt-beacon.md §十六","wdt-beacon.md §四"),
     ("wdt-beacon.md §十四","wdt-beacon.md §四"),
     ("wdt-beacon.md §十三","wdt-beacon.md §三"),
     ("wdt-beacon.md §十二.1","wdt-beacon.md §一"),
     ("wdt-beacon.md §十二","wdt-beacon.md §三"),
     ("wdt-beacon.md §十一","wdt-beacon.md §二"),
     ("wdt-beacon.md §十","wdt-beacon.md §三"),
     ("wdt-beacon.md §九","wdt-beacon.md §二")]
n=0
for p in glob.glob(os.path.join(D,"*.md")):
    if p.endswith("wdt-beacon.md"): continue
    s=open(p).read(); o=s
    # 先处理"§十三～§十五"这种区间写法
    s=re.sub(r"wdt-beacon\.md`? §十三～§十五", "wdt-beacon.md` §三～§四", s)
    for a,b in MAP: s=s.replace(a,b)
    if s!=o: open(p,"w").write(s); n+=1; print("refs fixed:", os.path.basename(p))
print("共改", n, "个文件")
