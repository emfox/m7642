import os
p=os.path.expanduser("~/Debian/m7642/probes/handoff/build-postmmu.sh")
s=open(p).read()
if "WORLD_VA" not in s:
    s=s.replace('aarch64-buildroot-linux-gnu-gcc $DEFS -c tramp-postmmu.S -o tramp-postmmu.o',
                'aarch64-buildroot-linux-gnu-gcc $DEFS -DWORLD_VA=${WORLD_VA:-0} -c tramp-postmmu.S -o tramp-postmmu.o')
    s=s.replace('echo "defs: $DEFS"','echo "defs: $DEFS  WORLD_VA=${WORLD_VA:-0}"')
    open(p,"w").write(s); print("build: 支持 WORLD_VA")
