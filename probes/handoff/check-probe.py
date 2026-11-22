#!/usr/bin/env python3
"""Static sanity check for a handover probe blob.

Catches, offline, the two mistakes that each cost a power cycle on 2026-11-22:

  1. storing to the stash while the MMU is still on
     (with the MMU on the stash pages are not reachable; the store is what hangs)
  2. a forward branch that jumps *over* the `msr sctlr_el1` that turns the MMU off

Also warns when the blob would land on Image+0x36c0c0 (the code1 FDT shim) or
overlap the region the handover copies into.

Usage: check-probe.py <blob.bin> [--tramp-at 0x36c000]
Exit status 0 = clean, 1 = problems found.
"""
import subprocess, sys, os, re, argparse

OBJDUMP = os.path.expanduser(
    "~/Debian/m7642-build/toolchain/gcc13/bin/aarch64-buildroot-linux-gnu-objdump")
SHIM_AT = 0x36c0c0          # code1 FDT shim lives here
STASH_LO, STASH_HI = 0x23000000, 0x23200000


def disasm(blob, base=0):
    out = subprocess.run([OBJDUMP, "-D", "-b", "binary", "-m", "aarch64",
                          "--adjust-vma=%#x" % base, blob],
                         capture_output=True, text=True).stdout
    ins = []
    for line in out.splitlines():
        mo = re.match(r"\s*([0-9a-f]+):\s+([0-9a-f ]+)\t(.*)$", line)
        if mo:
            ins.append((int(mo.group(1), 16), mo.group(3).strip()))
    return ins


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("blob")
    ap.add_argument("--tramp-at", type=lambda s: int(s, 0), default=None,
                    help="image offset the blob is installed at")
    ap.add_argument("--allow-mmu-on-store", action="store_true",
                    help="the pre-MMU stash store IS the experiment (kva5)")
    a = ap.parse_args()

    ins = disasm(a.blob)
    if not ins:
        print("!! cannot disassemble", a.blob); return 1
    problems = []

    # locate the MMU-off sequence: msr sctlr_el1 preceded by a bic of #1
    mmu_off = None
    for i, (addr, txt) in enumerate(ins):
        if txt.startswith("msr") and "sctlr_el1" in txt:
            # the assembler may emit the M-bit clear as `bic xN, xN, #1` or,
            # equivalently, `and xN, xN, #0xfffffffffffffffe`
            window = [t for _, t in ins[max(0, i - 4):i]]
            if any(("bic" in t and ", #1" in t) or
                   ("and" in t and "0xfffffffffffffffe" in t) for t in window):
                mmu_off = i
                break

    if mmu_off is None:
        problems.append("no `msr sctlr_el1` that clears the M bit -- MMU never disabled")
    else:
        for i, (addr, txt) in enumerate(ins):
            if mmu_off is not None and i < mmu_off and re.match(r"strh?\b", txt):
                mo = re.search(r"\[x\d+,?\s*(#0x[0-9a-f]+)?\]", txt)
                # resolve a simple "movk xN, #0x2309" base register if we can
                reg = re.search(r"\[(x\d+)", txt)
                base_hi = None
                if reg:
                    for j in range(i - 1, max(-1, i - 6), -1):
                        mo2 = re.search(r"movk\s+%s, #0x([0-9a-f]+), lsl #16" % reg.group(1),
                                        ins[j][1])
                        if mo2:
                            base_hi = int(mo2.group(1), 16)
                            break
                if (base_hi is not None and (base_hi << 16) in range(STASH_LO, STASH_HI)
                        and not a.allow_mmu_on_store):
                    problems.append("store to the stash at instruction %d %#x before the MMU is off: %s"
                                    % (i, addr, txt))

    # any forward branch that lands beyond the MMU-off sequence
    if mmu_off is not None:
        for i, (addr, txt) in enumerate(ins):
            mo = re.match(r"b\s+([0-9a-f]+)", txt)
            if mo:
                tgt = int(mo.group(1), 16)
                if tgt > addr and tgt > ins[mmu_off][0] and i < mmu_off:
                    problems.append("forward branch at %#x -> %#x skips the MMU-off "
                                    "sequence at %#x" % (addr, tgt, ins[mmu_off][0]))

    # placement
    if a.tramp_at is not None:
        end = a.tramp_at + os.path.getsize(a.blob)
        if a.tramp_at <= SHIM_AT < end:
            problems.append("blob at Image+%#x would cover the code1 FDT shim at %#x"
                            % (a.tramp_at, SHIM_AT))

    if problems:
        print("FAIL %s" % a.blob)
        for p in problems:
            print("  -", p)
        return 1
    print("OK   %s (%d instructions, MMU-off at %#x)"
          % (a.blob, len(ins), ins[mmu_off][0] if mmu_off is not None else 0))
    return 0


if __name__ == "__main__":
    sys.exit(main())
