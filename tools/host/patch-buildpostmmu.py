#!/usr/bin/env python3
"""build-postmmu.sh: also emit abort-rung.bin (the ctl/paint stub)."""
import os
p = os.path.expanduser("~/Debian/m7642/probes/handoff/build-postmmu.sh")
s = open(p).read()
if "abort-rung" in s:
    print("already")
    raise SystemExit(0)

s = s.replace(
    "aarch64-buildroot-linux-gnu-gcc -c abort-postmmu.S -o abort-postmmu.o\n"
    "for f in tramp-postmmu abort-postmmu; do",
    "aarch64-buildroot-linux-gnu-gcc -c abort-postmmu.S -o abort-postmmu.o\n"
    "# abort-rung.bin is the plain record+handover stub the fcie build scripts\n"
    "# patch in for the ctl/paint images; it needs no kernel constants.\n"
    "aarch64-buildroot-linux-gnu-gcc -c abort-rung.S -o abort-rung.o\n"
    "for f in tramp-postmmu abort-postmmu abort-rung; do")
s = s.replace("ls -l tramp-postmmu.bin abort-postmmu.bin",
              "ls -l tramp-postmmu.bin abort-postmmu.bin abort-rung.bin")
s = s.replace("md5sum tramp-postmmu.bin abort-postmmu.bin",
              "md5sum tramp-postmmu.bin abort-postmmu.bin abort-rung.bin")
open(p, "w").write(s)
print("patched")
