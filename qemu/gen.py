#!/usr/bin/env python3
"""
gen.py -- single source of truth for the offline bench address space.

Usage:  gen.py <profile> <scenario> <variant>

Emits
  gen/layout.inc     .equ definitions consumed by boot.S / pad.S
  gen/banner.inc     the one-line banner string for this (profile, scenario)
  gen/tramp-defs.txt the -D arguments for the tramp (same shape as the real
                     build-postmmu.sh, plus the two bench-relocated PAs)
  gen/profile.sh     shell variables for run.sh (addresses, expected values)

Everything is derived from two inputs: where RAM starts (MEMSTART) and where the
fake kernel image is loaded (IMAGE_BASE).  The rest of the map is fixed by the
tramp itself: PAGE_OFFSET is hardcoded in it (0xffffff8000000000, 39-bit VA,
i.e. T0SZ = 25) and its 1 GB identity table lives at L1[0], so the handover
address MUST be below 1 GB.
"""
import os
import sys

# Which tramp generation is under test:
#   v1 = probes/handoff/tramp-postmmu.S as of 2026-11-22 22:02 (AT calibration)
#   v2 = ... as of 22:31 (build-time KIMAGE_OFFSET, TABLE_PA/TABLE_VA)
TRAMP_VERSIONS = {
    # entry_off = offset of _start_kva inside the blob; build.sh checks it
    # against the object's symbol table, so it cannot silently drift.
    "v1": dict(src="src/tramp-qemu.S", v2=0, entry_off=0x4),
    "v2": dict(src="src/tramp-v2.S", v2=1, entry_off=0x8),
}

PROFILES = {
    # RAM at physical 0 -- like the TV, and the only way to keep every address
    # the tramp touches below its 1 GB identity block.
    "zcu102": dict(MACHINE="xlnx-zcu102", MEMSTART=0x10000000, IMAGE_BASE=0x20000000),
    # RAM at 0x40000000 -- the QEMU 'virt' layout the task asked for first.
    # Kept because it demonstrates *why* virt cannot host this tramp.
    "virt": dict(MACHINE="virt", MEMSTART=0x40000000, IMAGE_BASE=0x40080000),
}

SCENARIOS = {
    #       name       description                        kill_idmap  entry x5
    1: ("P1",     "idmap ALIVE",                     0, 0x21),
    2: ("P2",     "idmap GONE (cpu_uninstall_idmap)", 1, 0x21),
    3: ("P1-x5z", "idmap ALIVE, entry x5 == 0",      0, 0x00),
    4: ("P2-x5z", "idmap GONE, entry x5 == 0",       1, 0x00),
}

VARIANTS = {
    "vanilla":      "",
    # bug ③ repaired (one-line PAGE_OFFSET fix), everything else untouched
    "fix-pgoff":    "-DFIX_PAGE_OFFSET=1",
    "badlin":       "-DINJECT_LIN_ERR=0x1000",
    "no-idmap":     "-DINJECT_NO_IDMAP=1",
    "pa-alias":     "-DINJECT_PA_ALIAS=1",
    "dbl-offset":   "-DINJECT_DBL_OFFSET=1",
}

# variants used on top of fix-pgoff for the P3 discrimination matrix
FIXED = "-DFIX_PAGE_OFFSET=1"

PAGE_OFFSET = 0xFFFFFF8000000000   # hardcoded in the tramp (39-bit VA)
KIMAGE_VA   = 0xFFFFFFC080000000   # arm64 KIMAGE_VADDR for a 39-bit VA kernel

# --- offsets inside the fake kernel image (the image base is "Image") ------
OFF_MEMSTART_VAR = 0x1000          # fake memstart_addr variable
OFF_BOOT_ARGS    = 0x1100          # fake boot_args[3]
OFF_BENCHSTR     = 0x1400          # bench banner / labels
OFF_TRAMP        = 0x20000         # tramp blob (patched in like its real home)
OFF_LANDING      = 0x30200         # landing pad == tramp's handover target
OFF_PADSTR       = 0x34000
OFF_IDMAP_TABLE  = 0x40000         # tramp's 1 GB identity table
OFF_L1T          = 0x80000         # TTBR1 L1
OFF_L2K          = 0x81000         # kimage L2 (2 MB blocks)
OFF_L2LIN        = 0x82000         # linear map L2 (2 MB blocks)
OFF_L1T0         = 0x83000         # TTBR0 L1 (identity map)
OFF_ZEROT        = 0x84000         # zero page used to kill the idmap (P2)
OFF_STACK        = 0x90000
IMAGE_SIZE       = 0x91000

DESC_KERNEL = 0x705                # block|AttrIdx1|SH inner|AF
DESC_UXN    = 1 << 54
MAIR_VAL    = 0x00 | (0xFF << 8)   # attr0 device-nGnRnE, attr1 normal WB RA/WA
# T0SZ=T1SZ=25 (39-bit VA), 4 KB granule, inner-shareable WB RA/WA, IPS=40-bit
TCR_VAL = (25 | (1 << 8) | (1 << 10) | (3 << 12)
           | (25 << 16) | (1 << 24) | (1 << 26) | (3 << 28) | (2 << 30)
           | (2 << 32))



def main():
    if len(sys.argv) < 4:
        print(__doc__)
        return 1
    prof, scen_arg, variant = sys.argv[1], sys.argv[2], sys.argv[3]
    tver = sys.argv[4] if len(sys.argv) > 4 else "v1"
    tv = TRAMP_VERSIONS[tver]
    scen = int(scen_arg)
    p = PROFILES[prof]
    sname, sdesc, kill_idmap, x5 = SCENARIOS[scen]
    inject = VARIANTS[variant]

    memstart = p["MEMSTART"]
    image_base = p["IMAGE_BASE"]
    lin = PAGE_OFFSET - memstart
    kblock = image_base & ~0x1FFFFF                 # kimage 2 MB block base
    kimage_offset = KIMAGE_VA - kblock
    idmap_block = image_base & ~0x3FFFFFFF           # 1 GB block base
    l1_idx = lambda va: (va >> 30) & 0x1FF
    l2_idx = lambda va: (va >> 21) & 0x1FF

    A = {
        "PROFILE": prof,
        "MACHINE": p["MACHINE"],
        "SCENARIO": scen,
        "SCENARIO_NAME": sname,
        "VAR": variant,
        "MEMSTART": memstart,
        "PAGE_OFFSET": PAGE_OFFSET,
        "LIN": lin,
        "KIMAGE_VA": KIMAGE_VA,
        "KIMAGE_BLOCK_PA": kblock,
        "KIMAGE_OFFSET": kimage_offset,
        "IMAGE_BASE": image_base,
        "IMAGE_START_PA": image_base,
        "IMAGE_END_PA": image_base + IMAGE_SIZE,
        "FAKE_MEMSTART_PA": image_base + OFF_MEMSTART_VAR,
        "FAKE_MEMSTART_VA": image_base + OFF_MEMSTART_VAR + kimage_offset,
        "BOOT_ARGS_PA": image_base + OFF_BOOT_ARGS,
        "BOOT_ARGS_VA": image_base + OFF_BOOT_ARGS + lin,
        "TRAMP_PA": image_base + OFF_TRAMP,
        "TRAMP_VA": image_base + OFF_TRAMP + kimage_offset,
        "TRAMP_VA_ENTRY": image_base + OFF_TRAMP + tv["entry_off"] + kimage_offset,
        "TRAMP_ENTRY_OFF": tv["entry_off"],
        "HANDOVER_PA": image_base + OFF_LANDING,
        "IDMAP_TABLE_PA": image_base + OFF_IDMAP_TABLE,
        "IDMAP_TABLE_VA": image_base + OFF_IDMAP_TABLE + lin,
        "ZEROT_PA": image_base + OFF_ZEROT,
        "L1T_PA": image_base + OFF_L1T,
        "L2K_PA": image_base + OFF_L2K,
        "L2LIN_PA": image_base + OFF_L2LIN,
        "L1T0_PA": image_base + OFF_L1T0,
        "STACK_TOP": image_base + OFF_STACK,
        "KIMAGE_L1_OFF": l1_idx(KIMAGE_VA) * 8,
        "KIMAGE_L2_OFF": l2_idx(KIMAGE_VA) * 8,
        "TMAP_L1_OFF": l1_idx(PAGE_OFFSET) * 8,
        "IDMAP_L1_OFF": l1_idx(image_base) * 8,
        "IDMAP_BLOCK_PA": idmap_block,
        "TMAP_STEP": 0x200000,
        "TMAP_COUNT": 512,
        "VEC_VA": image_base + 0x800 + lin,
        "DESC_KERNEL": DESC_KERNEL,
        "DESC_UXN": DESC_KERNEL | DESC_UXN,
        "MAIR_VAL": MAIR_VAL,
        "TCR_VAL": TCR_VAL,
        "IDMAP_DESC_EXPECTED": DESC_KERNEL | DESC_UXN,
        "EXPECTED_KIMAGE": kimage_offset & 0x0000FFFFFFFFFFFF,
        "EXPECTED_MEMSTART": memstart,
        "EXPECTED_LIN": lin,
        "CHECKPOINT_RET": KIMAGE_VA + 0x4680A0,
        "ARG1": 0x2222222222222222,
        "ARG2": 0x3333333333333333,
        "MODE_X5": x5,
        "ENTRY_X5_ZERO": 1 if x5 == 0 else 0,
        "KILL_IDMAP": kill_idmap,
        "EXPECT_IDMAP": 0 if variant == "no-idmap" else 1,
        "TRAMP_V2": tv["v2"],
        "TRAMP_VERSION": tver,
        "EXPECTED_KIMAGE_OFFSET": kimage_offset,
        "EXPECTED_TABLE_PA": image_base + OFF_IDMAP_TABLE,
        "EXPECTED_DESC_V2": 0x0040000000000701,
        "TABLE_PA": image_base + OFF_IDMAP_TABLE,
        "TABLE_VA": image_base + OFF_IDMAP_TABLE + kimage_offset,
        "PRIMARY_ENTRY_PA": 0x0,
        "MASK48": 0x0000FFFFFFFFFFFF,
        "AT_PROBE_PA": image_base + OFF_IDMAP_TABLE,
        "OFF_EXC_BUF": 0x1300,
    }

    here = os.path.dirname(os.path.abspath(__file__))
    gen = os.path.join(here, "gen")
    os.makedirs(gen, exist_ok=True)

    # names that are also passed to cpp (-D) must not appear as .equ
    CPP_ONLY = {"SCENARIO", "KILL_IDMAP", "PRIMARY_ENTRY_PA", "OFF_EXC_BUF",
                "ENTRY_X5_ZERO", "EXPECT_IDMAP", "TRAMP_V2"}
    with open(os.path.join(gen, "layout.inc"), "w") as f:
        f.write("/* generated by gen.py -- do not edit */\n")
        for k, v in A.items():
            if isinstance(v, int) and k not in CPP_ONLY:
                f.write(".equ %s, %#x\n" % (k, v))

    banner = "[bench] %s / %s / %s / variant=%s\n" % (prof, sname, sdesc, variant)
    with open(os.path.join(gen, "banner.inc"), "w") as f:
        f.write("/* generated by gen.py */\n")
        f.write("\t.section .benchstr, \"a\"\n")
        f.write("s_banner:\n\t.asciz\t\"%s\\n\"\n" % banner.rstrip("\n"))

    common = ("-DBOOT_ARGS_PA=%#x -DIMAGE_START_PA=%#x -DIMAGE_END_PA=%#x "
              "-DKIMAGE_OFFSET=%#x -DPRIMARY_ENTRY_PA=%#x "
              "-DHANDOVER_PA=%#x"
              % (A["BOOT_ARGS_PA"], A["IMAGE_START_PA"], A["IMAGE_END_PA"],
                 kimage_offset, 0x20280000, A["HANDOVER_PA"]))
    if tv["v2"]:
        defs = common + " -DTABLE_PA=%#x -DTABLE_VA=%#x" % (
            A["TABLE_PA"], A["TABLE_VA"])
    else:
        defs = common + " -DMEMSTART_VA=%#x -DIDMAP_TABLE_PA=%#x" % (
            A["FAKE_MEMSTART_VA"], A["IDMAP_TABLE_PA"])
    if inject:
        defs += " " + inject
    if os.environ.get("BASE_FIX", "0") not in ("", "0"):
        defs += " " + FIXED
    with open(os.path.join(gen, "tramp-defs.txt"), "w") as f:
        f.write(defs + "\n")

    with open(os.path.join(gen, "tramp-src.txt"), "w") as f:
        f.write(tv["src"] + "\n")

    with open(os.path.join(gen, "profile.sh"), "w") as f:
        for k, v in A.items():
            if isinstance(v, int):
                f.write("%s=%#x\n" % (k, v))
        f.write('MACHINE="%s"\n' % p["MACHINE"])
        f.write('TRAMP_VERSION="%s"\n' % tver)
        f.write('SCENARIO_NAME="%s"\n' % sname)
        f.write('PROFILE_NAME="%s"\n' % prof)
        f.write('VARIANT_NAME="%s"\n' % variant)
        f.write('BANNER_STR="%s"\n' % banner.rstrip("\n").replace('"', '\\"'))

    return 0


if __name__ == "__main__":
    sys.exit(main())
