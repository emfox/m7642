import os
p=os.path.expanduser("~/Debian/m7642-build/kernel/linux-git/arch/arm64/kernel/Makefile")
s=open(p).read()
i=s.index("obj-$(CONFIG_MSTAR_M7642_BUILTIN_DTB)")
j=s.index("\n# for cleaning", i)
s = s[:i] + """obj-$(CONFIG_MSTAR_M7642_BUILTIN_DTB)\t+= m7642-dtb.o

# m7642-dtb.S .incbin's the compiled board DTB, so `make dtbs` has to run before
# the kernel is linked -- build with "make dtbs Image".  A kbuild dependency was
# tried and dropped: the dtc rules live in the dts sub-make, so a prerequisite
# here is "no rule to make target" (2026-11-23).
""" + s[j:]
open(p,"w").write(s); print("Makefile 回到 2 行 + 说明")
