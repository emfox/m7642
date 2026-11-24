import os, re
p=os.path.expanduser("~/Debian/m7642/probes/handoff/abort-postmmu.S")
s=open(p).read()
n=s.count("add\tx6, x6, x5")+s.count("add\tx7, x7, x5")+s.count("add\tx9, x9, x5")
for ln in ["\tadd\tx6, x6, x5\n", "\tadd\tx7, x7, x5\n", "\tadd\tx9, x9, x5\n"]:
    s=s.replace(ln,"")
open(p,"w").write(s)
print("去掉的 x5 偏移行数:", n)
print("剩余 x5 引用:")
for i,l in enumerate(s.split("\n"),1):
    if "x5" in l: print(" %3d: %s" % (i, l.strip()))
