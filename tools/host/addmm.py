import os
p = os.path.expanduser("~/Debian/m7642/tools/host/ckpt.py")
s = open(p).read()
if '"mm2"' not in s:
    s = s.replace('    "pre_sched":    ("start_kernel", 0x3c0, "at bl sched_init"),',
'''    "pre_sched":    ("start_kernel", 0x3c0, "at bl sched_init"),
    # inside mm_core_init(): arch_mm_preinit, arch_setup_zero_pages,
    # build_all_zonelists, page_alloc_init_cpuhp, stack_depot_early_init,
    # memblock_free_all, mem_init, kmem_cache_init, pgtable_cache_init,
    # vmalloc_init, mm_cache_init ...
    "mm1":          ("mm_core_init", 0x58, "after build_all_zonelists"),
    "mm2":          ("mm_core_init", 0xc8, "at bl memblock_free_all"),
    "mm3":          ("mm_core_init", 0xcc, "at bl mem_init"),
    "mm4":          ("mm_core_init", 0xd0, "at bl kmem_cache_init"),
    "mm5":          ("mm_core_init", 0xd4, "at bl pgtable_cache_init"),
    "mm6":          ("mm_core_init", 0xdc, "at bl mm_cache_init"),''')
    open(p, "w").write(s); print("ckpt.py: mm_core_init 内部阶梯已加")
