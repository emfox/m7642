#!/usr/bin/env python3
"""Split probe5.out into per-function binaries and disassemble them."""
import os
import re
import subprocess
import sys

OUT = "/home/emfox/Debian/tv/kernel-lab/disasm"
OBJDUMP = "/home/emfox/kbuild/aarch64--glibc--stable-2018.11-1/bin/aarch64-linux-objdump"

src = sys.argv[1] if len(sys.argv) > 1 else "/home/emfox/Debian/tv/kernel-lab/probe5.out"
os.makedirs(OUT, exist_ok=True)

# parse: FUNC <name> <addr> <len> then hex lines until next marker
entries = []
name = None
addr = 0
hexbuf = []

def flush():
    if name and hexbuf:
        data = bytes.fromhex("".join(hexbuf))
        entries.append((name, addr, data))

with open(src, "r", encoding="latin1") as f:
    for line in f:
        line = line.strip()
        m = re.match(r"^FUNC (\S+) ([0-9a-f]+) (\d+)$", line)
        if m:
            flush()
            name, addr, hexbuf = m.group(1), int(m.group(2), 16), []
            continue
        if line == "END" or line.startswith("MISS"):
            flush()
            name, hexbuf = None, []
            continue
        if line and re.fullmatch(r"[0-9a-f]+", line):
            hexbuf.append(line)
flush()

for nm, ad, data in entries:
    binp = os.path.join(OUT, nm + ".bin")
    with open(binp, "wb") as f:
        f.write(data)
    r = subprocess.run([OBJDUMP, "-D", "-b", "binary", "-m", "aarch64",
                        "--start-address=0", "--stop-address=%d" % len(data), binp],
                       capture_output=True, text=True)
    lines = [l for l in r.stdout.splitlines() if re.match(r"^\s+[0-9a-f]+:", l)]
    asmp = os.path.join(OUT, nm + ".s")
    with open(asmp, "w") as f:
        f.write("// %s @ %#x\n" % (nm, ad))
        f.write("\n".join(lines) + "\n")
    print("%-46s %5d bytes -> %s.s" % (nm, len(data), nm))
