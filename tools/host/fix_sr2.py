import os
p = os.path.expanduser("~/Debian/m7642/probes/handoff/tramp-postmmu.S")
lines = open(p).read().split("\n")
# 找 restore 块起点（.org 0x500）与 shim（.org 0xc0）
i500 = next(i for i,l in enumerate(lines) if l.strip() == ".org\t0x500")
for i, l in enumerate(lines):
    if "adr\tx16, 1" in l:
        want = "1b" if i > i500 else "1f"
        new = l.split("\t")[0] + "\tadr\tx16, " + want + ("\t\t\t/* the common path (it precedes us) */" if want=="1b" else "")
        print("line %d: %r -> %r" % (i+1, l.strip(), new.strip()))
        lines[i] = new
open(p, "w").write("\n".join(lines))
