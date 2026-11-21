#!/usr/bin/env python3
"""List every U_BOOT_CMD registered in the MStar mboot tree."""
import re
import glob
import os

pat = re.compile(r"U_BOOT_CMD\s*\(\s*([A-Za-z0-9_]+)\s*,")
rows = []
for path in glob.glob(os.path.join(os.path.dirname(__file__),
                                   "../../ref/mstar-mboot/**/*.c"),
                      recursive=True):
    src = open(path, errors="ignore").read()
    for m in pat.finditer(src):
        tail = src[m.end():m.end() + 600]
        strs = re.findall(r'"([^"\n]*)"', tail)
        usage = strs[0] if strs else ""
        rows.append((m.group(1), usage, os.path.basename(path)))

seen = set()
for name, usage, fname in sorted(rows):
    if name in seen:
        continue
    seen.add(name)
    print("%-30s | %-62s | %s" % (name, usage[:62], fname))
print("total %d" % len(seen))
