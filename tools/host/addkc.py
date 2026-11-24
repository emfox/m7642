import os
p = os.path.expanduser("~/Debian/m7642/tools/host/ckpt.py")
s = open(p).read()
if '"kc4"' not in s:
    s = s.replace('    "mm8":          ("mm_core_init", 0xe0, "after mm_cache_init, before ret"),',
'''    "mm8":          ("mm_core_init", 0xe0, "after mm_cache_init, before ret"),
    # inside kmem_cache_init(): hash_pointers_finalize, create_boot_cache x2,
    # bootstrap x2, setup_kmalloc_cache_index_table, create_kmalloc_caches,
    # kmalloc paths, panic() on alloc failure, __cpuhp_setup_state
    "kc1":          ("kmem_cache_init", 0xc8, "at bl bootstrap"),
    "kc2":          ("kmem_cache_init", 0xe4, "at bl create_kmalloc_caches"),
    "kc3":          ("kmem_cache_init", 0xe8, "after create_kmalloc_caches"),
    "kc4":          ("kmem_cache_init", 0x298, "at bl __cpuhp_setup_state"),''')
    open(p, "w").write(s); print("ckpt.py: kc1..kc4 已加")
