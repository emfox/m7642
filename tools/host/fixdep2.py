import os
p=os.path.expanduser("~/Debian/m7642-build/kernel/linux-git/arch/arm64/kernel/Makefile")
s=open(p).read()
old = """# m7642-dtb.S .incbin's the compiled board DTB, so it has to exist first.  Without
# this the build only succeeded when a stale .dtb was left over from an earlier
# in-tree build -- found by building this very tree out-of-tree (2026-11-23).
DTB_M7642 := $(objtree)/arch/arm64/boot/dts/mstar/m7642-tcl-65s535d.dtb
$(obj)/m7642-dtb.o: $(DTB_M7642)
"""
new = """# m7642-dtb.S .incbin's the compiled board DTB, so it has to exist first.  Without
# this the build only succeeded when a stale .dtb was left over from an earlier
# in-tree build -- found by building this very tree out-of-tree (2026-11-23).
# Order-only on the top-level "dtbs" target: it knows how to invoke dtc, and being
# order-only keeps a phony prerequisite from forcing a relink every time.
$(obj)/m7642-dtb.o: | dtbs
"""
assert old in s, "anchor missing"
open(p,"w").write(s.replace(old,new,1))
print("改成 order-only dtbs")
