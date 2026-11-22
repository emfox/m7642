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
    "b1":           ("setup_arch", 0x368, "smp_init_cpus"),
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
