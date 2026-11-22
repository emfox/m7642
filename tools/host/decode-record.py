#!/usr/bin/env python3
"""Decode a probeRW dump of the handover record at 0x23080000.

Usage:
    decode-record.py record.txt        # a saved `cat probeRW.out`
    ... | decode-record.py -           # straight from the pipe

The record is written by probes/handoff/abort-postmmu.S, size 0xB0:

    0x00  "M764"          magic
    0x04  "MMMU"          tag
    0x08  u32 size        bytes written
    0x0c  u32 flags       unused
    0x10  x30             the checkpoint's return address
    0x18  x0 x1 x2        boot_args[0..2] as the kernel carries them
    0x30  x3 x4           (x3/x4 are zeroed for the handover)
    0x40  x21 x22 x23     the checkpoint's x8, x0, x1
    0x58  x24 x25 x26     the checkpoint's x2, x3, x4
    0x70  SCTLR_EL1       as the kernel had it, before the stub touched it
    0x78  MIDR_EL1        implementer / part / revision
    0x80  CTR_EL0         cache geometry
    0x88  REVIDR_EL1
    0x90  TCR_EL1         T0SZ / T1SZ / EPD0 -- page-table regime
    0x98  MAIR_EL1        memory attribute indirection
    0xa0  ID_AA64MMFR0_EL1  PARange etc.
    0xa8  MPIDR_EL1       which CPU ran the probe

The identity registers exist so the same fields can be read inside QEMU and
compared against the TV: page-table and cache-maintenance behaviour depends on
CTR/TCR/MAIR, not on which core the model is named after.
"""
import re
import sys

SIZE = 0xB0

IMPLEMENTERS = {0x41: "ARM", 0x4E: "NVIDIA", 0x48: "HiSilicon", 0x51: "Qualcomm",
                0x61: "Apple", 0x6D: "Microsoft", 0xC0: "Ampere"}

PARTS = {
    (0x41, 0xD03): "Cortex-A53", (0x41, 0xD04): "Cortex-A35",
    (0x41, 0xD05): "Cortex-A55", (0x41, 0xD07): "Cortex-A57",
    (0x41, 0xD08): "Cortex-A72", (0x41, 0xD09): "Cortex-A73",
    (0x41, 0xD0A): "Cortex-A75", (0x41, 0xD0B): "Cortex-A76",
    (0x41, 0xD0D): "Cortex-A77", (0x41, 0xD41): "Cortex-A78",
    (0x41, 0xD46): "Cortex-A510", (0x41, 0xD47): "Cortex-A710",
    (0x41, 0xD48): "Cortex-X2", (0x41, 0xD4D): "Cortex-A715",
}

PARANGE = {0: "32 bits", 1: "36 bits", 2: "40 bits", 3: "42 bits",
           4: "44 bits", 5: "48 bits", 6: "52 bits", 7: "56 bits"}


def parse(text):
    """Pull hex bytes out of `0000000023080000: 4d 37 ...` style output."""
    buf = bytearray()
    for line in text.splitlines():
        m = re.match(r"^\s*[0-9a-fA-F]{8,16}:\s*(.*)$", line)
        if not m:
            continue
        for tok in m.group(1).split():
            if re.fullmatch(r"[0-9a-fA-F]{2}", tok):
                buf.append(int(tok, 16))
    return bytes(buf)


def q(b, off):
    return int.from_bytes(b[off:off + 8], "little") if len(b) >= off + 8 else None


def main():
    src = sys.argv[1] if len(sys.argv) > 1 else "-"
    text = sys.stdin.read() if src == "-" else open(src).read()
    b = parse(text)
    if len(b) < 16:
        print("no record bytes found (%d)" % len(b))
        return 1

    magic, tag = b[0:4], b[4:8]
    size = int.from_bytes(b[8:12], "little")
    print("record: magic=%r tag=%r size=%#x (%d B parsed)"
          % (magic, tag, size, len(b)))
    if magic != b"M764" or tag != b"MMMU":
        print("  !! not a handover record (expected 'M764'/'MMMU')")
        return 1

    x30 = q(b, 0x10)
    print("  x30 (checkpoint return) = %#x" % x30)
    print("  boot_args x0/x1/x2      = %#x %#x %#x"
          % (q(b, 0x18), q(b, 0x20), q(b, 0x28)))
    print("  handover  x3/x4         = %#x %#x" % (q(b, 0x30), q(b, 0x38)))
    print("  checkpoint x8/x0/x1     = %#x %#x %#x"
          % (q(b, 0x40), q(b, 0x48), q(b, 0x50)))
    print("  checkpoint x2/x3/x4     = %#x %#x %#x"
          % (q(b, 0x58), q(b, 0x60), q(b, 0x68)))

    sctlr = q(b, 0x70)
    if sctlr is not None:
        print("  SCTLR_EL1               = %#x  (M=%d C=%d I=%d A=%d SA=%d)"
              % (sctlr, sctlr & 1, (sctlr >> 2) & 1, (sctlr >> 12) & 1,
                 (sctlr >> 1) & 1, (sctlr >> 3) & 1))

    midr = q(b, 0x78)
    if midr:
        imp = (midr >> 24) & 0xFF
        part = (midr >> 4) & 0xFFF
        print("  MIDR_EL1                = %#x  implementer=%#x %s part=%#x %s "
              "variant=%d rev=%d"
              % (midr, imp, IMPLEMENTERS.get(imp, "?"), part,
                 PARTS.get((imp, part), "(unknown)"),
                 (midr >> 20) & 0xF, midr & 0xF))

    ctr = q(b, 0x80)
    if ctr:
        print("  CTR_EL0                 = %#x  IminLine=%d B DminLine=%d B "
              "CWG=%d ERG=%d"
              % (ctr, 4 << ((ctr >> 0) & 0xF), 4 << ((ctr >> 16) & 0xF),
                 4 << ((ctr >> 24) & 0xF), 4 << ((ctr >> 20) & 0xF)))

    revidr = q(b, 0x88)
    if revidr is not None:
        print("  REVIDR_EL1              = %#x" % revidr)

    tcr = q(b, 0x90)
    if tcr:
        t0sz, t1sz = tcr & 0x3F, (tcr >> 16) & 0x3F
        print("  TCR_EL1                 = %#x  T0SZ=%d (%d-bit VA) "
              "T1SZ=%d (%d-bit VA) EPD0=%d EPD1=%d TG0=%d TG1=%d"
              % (tcr, t0sz, 64 - t0sz, t1sz, 64 - t1sz,
                 (tcr >> 7) & 1, (tcr >> 23) & 1,
                 (tcr >> 14) & 3, (tcr >> 30) & 3))

    mair = q(b, 0x98)
    if mair is not None:
        print("  MAIR_EL1                = %#x  attrs = %s"
              % (mair, " ".join("idx%d=%#04x" % (i, (mair >> (8 * i)) & 0xFF)
                                for i in range(8))))

    mmfr0 = q(b, 0xA0)
    if mmfr0 is not None:
        print("  ID_AA64MMFR0_EL1        = %#x  PARange=%d (%s) TGran4=%d TGran16=%d"
              % (mmfr0, mmfr0 & 0xF, PARANGE.get(mmfr0 & 0xF, "?"),
                 (mmfr0 >> 28) & 0xF, (mmfr0 >> 20) & 0xF))

    mpidr = q(b, 0xA8)
    if mpidr is not None:
        print("  MPIDR_EL1               = %#x  Aff0=%d Aff1=%d"
              % (mpidr, mpidr & 0xFF, (mpidr >> 8) & 0xFF))
    return 0


if __name__ == "__main__":
    sys.exit(main())
