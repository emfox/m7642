import os
p = os.path.expanduser("~/Debian/m7642/probes/handoff/build-postmmu.sh")
s = open(p).read()
old = "aarch64-buildroot-linux-gnu-gcc -c abort-postmmu.S -o abort-postmmu.o"
new = "aarch64-buildroot-linux-gnu-gcc -DSAVE_PA=${SAVE_PA:-0x20883000} -c abort-postmmu.S -o abort-postmmu.o"
if old in s and "-DSAVE_PA=${SAVE_PA" not in s:
    open(p, "w").write(s.replace(old, new, 1)); print("stub 编译加 -DSAVE_PA")
else:
    print("already or not found")
