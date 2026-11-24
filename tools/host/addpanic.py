import os
p = os.path.expanduser("~/Debian/m7642/tools/host/ckpt.py")
s = open(p).read()
if '"panicpath"' not in s:
    s = s.replace('    "kc4":          ("kmem_cache_init", 0x298, "at bl __cpuhp_setup_state"),',
'''    "kc4":          ("kmem_cache_init", 0x298, "at bl __cpuhp_setup_state"),
    # 0x4774b8 = kmem_cache_init+0x238: the "Out of memory when creating
    # kmem_cache %s" panic setup.  A checkpoint here fires ONLY if kmalloc(48)
    # returned NULL, i.e. if we are about to panic.
    "panicpath":    ("kmem_cache_init", 0x238, "OOM panic setup (kmalloc returned NULL)"),''')
    open(p, "w").write(s); print("ckpt.py: panicpath 已加")
