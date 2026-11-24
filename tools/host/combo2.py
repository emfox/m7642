import os
p = os.path.expanduser("~/Debian/m7642/tools/host/ckpt.py")
s = open(p).read()
if '"oom"' not in s:
    s = s.replace('    "panicpath":    ("kmem_cache_init", 0x238, "OOM panic setup (kmalloc returned NULL)"),',
'''    "panicpath":    ("kmem_cache_init", 0x238, "OOM panic setup (kmalloc returned NULL)"),
    # 0x477410 = after the first __kmalloc_cache_node() in the cache-creation loop
    "firstalloc":   ("kmem_cache_init", 0x190, "after the loop's first kmalloc returns"),
    "oom":          ("out_of_memory", 0x0, "out_of_memory entry (fires only if OOM)"),''')
    open(p, "w").write(s); print("ckpt.py: firstalloc / oom 已加")
