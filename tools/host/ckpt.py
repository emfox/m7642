#!/usr/bin/env python3
"""Resolve the checkpoint ladder against a given System.map.

Every checkpoint we use is described *relative to a symbol*, never as a bare
image offset.  That makes a kernel upgrade mechanical: the functions we patch
keep their internal layout (same instruction at the same delta), only the
function's address moves.

    ckpt.py --sysmap <System.map> [name ...]     # resolve
    ckpt.py --sysmap <System.map> --env          # shell assignments
    ckpt.py --list                               # show the ladder

Verified on Linux 7.3 (c03c1a145) and 7.3.5 (753f54c3): every entry below
resolved to an offset whose instruction word matched 7.3 byte for byte.
"""
import argparse
import sys

# name -> (symbol, delta, what it is)
LADDER = {
    # --- patches applied to the image (not checkpoints) ---
    "zfix_align":   ("__pi_early_map_kernel", 0x3c,
                     "and x25,x19,#0x1fffff -> mov x25,xzr (2 MB alignment)"),
    "zfix_nop":     ("preserve_boot_args", 0x20,
                     "b __pi_dcache_inval_poc -> nop"),
    # --- checkpoints, in execution order ---
    "start_kernel": ("start_kernel", 0x0, "start_kernel entry"),
    "setup_arch":   ("setup_arch", 0x0, "setup_arch entry"),
    "su3":          ("setup_arch", 0xcc, "after early_init_dt_scan"),
    "su4":          ("setup_arch", 0x110, "after of_flat_dt_get_machine_name"),
    "su5":          ("setup_arch", 0x124, "at bl parse_early_param"),
    "d0":           ("setup_arch", 0x128, "after parse_early_param"),
    "f1":           ("setup_arch", 0x148, "cpu_uninstall_idmap: msr ttbr0_el1"),
    "e1":           ("setup_arch", 0x190, "after cpu_uninstall_idmap"),
    "c1":           ("setup_arch", 0x1d4, "after efi_init"),
    "d1":           ("setup_arch", 0x1e8, "after arm64_memblock_init"),
    "c2":           ("setup_arch", 0x1f4, "after paging_init"),
    "b1":           ("setup_arch", 0x368, "at bl smp_init_cpus"),
    "b1b":          ("setup_arch", 0x36c, "after smp_init_cpus returns"),
    "trap_init":    ("trap_init", 0x0, "trap_init entry"),
    "zonelists":    ("build_all_zonelists", 0x0, "build_all_zonelists entry"),
    "sort_extable": ("sort_main_extable", 0x0, "sort_main_extable entry"),
    # start_kernel's tail: setup_log_buf -> vfs_caches_init_early ->
    # sort_main_extable -> mm_core_init -> sched_init, all inlined in start_kernel
    "pre_logbuf":   ("start_kernel", 0x3a4, "at bl setup_log_buf"),
    "pre_vfsearly": ("start_kernel", 0x3a8, "at bl vfs_caches_init_early"),
    "pre_sortext":  ("start_kernel", 0x3ac, "at bl sort_main_extable"),
    "pre_mmcore":   ("start_kernel", 0x3b4, "at bl mm_core_init"),
    "post_mmcore":  ("start_kernel", 0x3b8, "after mm_core_init returns"),
    "pre_sched":    ("start_kernel", 0x3c0, "at bl sched_init"),
    # inside mm_core_init(): arch_mm_preinit, arch_setup_zero_pages,
    # build_all_zonelists, page_alloc_init_cpuhp, stack_depot_early_init,
    # memblock_free_all, mem_init, kmem_cache_init, pgtable_cache_init,
    # vmalloc_init, mm_cache_init ...
    "mm1":          ("mm_core_init", 0x58, "after build_all_zonelists"),
    "mm2":          ("mm_core_init", 0xc8, "at bl memblock_free_all"),
    "mm3":          ("mm_core_init", 0xcc, "at bl mem_init"),
    "mm4":          ("mm_core_init", 0xd0, "at bl kmem_cache_init"),
    "mm5":          ("mm_core_init", 0xd4, "at bl pgtable_cache_init"),
    "mm6":          ("mm_core_init", 0xdc, "at bl mm_cache_init"),
    "mm7":          ("mm_core_init", 0xd8, "at bl vmalloc_init"),
    "mm8":          ("mm_core_init", 0xe0, "after mm_cache_init, before ret"),
    # inside kmem_cache_init(): hash_pointers_finalize, create_boot_cache x2,
    # bootstrap x2, setup_kmalloc_cache_index_table, create_kmalloc_caches,
    # kmalloc paths, panic() on alloc failure, __cpuhp_setup_state
    "kc1":          ("kmem_cache_init", 0xc8, "at bl bootstrap"),
    "kc2":          ("kmem_cache_init", 0xe4, "at bl create_kmalloc_caches"),
    "kc3":          ("kmem_cache_init", 0xe8, "after create_kmalloc_caches"),
    "kc4":          ("kmem_cache_init", 0x298, "at bl __cpuhp_setup_state"),
    # 0x4774b8 = kmem_cache_init+0x238: the "Out of memory when creating
    # kmem_cache %s" panic setup.  A checkpoint here fires ONLY if kmalloc(48)
    # returned NULL, i.e. if we are about to panic.
    "panicpath":    ("kmem_cache_init", 0x238, "OOM panic setup (kmalloc returned NULL)"),
    # 0x477410 = after the first __kmalloc_cache_node() in the cache-creation loop
    "firstalloc":   ("kmem_cache_init", 0x190, "after the loop's first kmalloc returns"),
    "oom":          ("out_of_memory", 0x0, "out_of_memory entry (fires only if OOM)"),
    "sched_init":   ("sched_init", 0x0, "sched_init entry"),
    "console_init": ("console_init", 0x0, "console_init entry"),
}

# Instruction words we expect at each patched site (sanity check on upgrade).
EXPECT = {
    "zfix_align": 0x92405279,   # and x25, x19, #0x1fffff
    "f1":         0xd5182000,   # msr ttbr0_el1, x0
}


def load_symmap(path):
    syms = {}
    for line in open(path):
        p = line.split()
        if len(p) >= 3:
            syms[p[2]] = int(p[0], 16)
    return syms


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--sysmap", required=False)
    ap.add_argument("--kimage-vaddr", type=lambda x: int(x, 0), default=0xffffffc080000000)
    ap.add_argument("--image", help="also verify the instruction word at each site")
    ap.add_argument("--env", action="store_true", help="print KEY=0x.. assignments")
    ap.add_argument("--list", action="store_true")
    ap.add_argument("names", nargs="*")
    a = ap.parse_args()

    if a.list:
        for n, (s, d, why) in LADDER.items():
            print("%-14s %s+%#x\t%s" % (n, s, d, why))
        return 0
    if not a.sysmap:
        ap.error("--sysmap is required")

    syms = load_symmap(a.sysmap)
    img = open(a.image, "rb").read() if a.image else None
    names = a.names or list(LADDER)
    rc = 0
    for n in names:
        if n not in LADDER:
            print("unknown checkpoint %r (see --list)" % n, file=sys.stderr)
            rc = 1
            continue
        sym, delta, _ = LADDER[n]
        if sym not in syms:
            print("%s: symbol %s missing from %s" % (n, sym, a.sysmap), file=sys.stderr)
            rc = 1
            continue
        off = syms[sym] + delta - a.kimage_vaddr
        line = "%-14s off=%#08x" % (n, off)
        if img is not None and off + 4 <= len(img):
            word = int.from_bytes(img[off:off + 4], "little")
            want = EXPECT.get(n)
            flag = ""
            if want is not None:
                flag = "  word=%#010x %s" % (word, "OK" if word == want else "MISMATCH (want %#010x)" % want)
                if word != want:
                    rc = 1
            else:
                flag = "  word=%#010x" % word
            line += flag
        if a.env:
            print("%s_OFF=0x%x" % (n.upper(), off))
        else:
            print(line)
    return rc


if __name__ == "__main__":
    sys.exit(main())
