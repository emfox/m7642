import os
p = os.path.expanduser("~/Debian/m7642/tools/host/ckpt.py")
s = open(p).read()
if '"mm8"' not in s:
    s = s.replace('    "mm6":          ("mm_core_init", 0xdc, "at bl mm_cache_init"),',
'''    "mm6":          ("mm_core_init", 0xdc, "at bl mm_cache_init"),
    "mm7":          ("mm_core_init", 0xd8, "at bl vmalloc_init"),
    "mm8":          ("mm_core_init", 0xe0, "after mm_cache_init, before ret"),''')
    open(p, "w").write(s); print("ckpt.py: mm7/mm8 已加")
