#!/usr/bin/env python3
"""Disassemble a range of an mboot image with pc-relative string resolution.

mboot is AArch32/U-Boot derived and links its body at 0x27400000 behind a
0x2400-byte header, so   VA = 0x27400000 + (fileoff - 0x2400).  Every string
reference is pc-relative:

    ldr rN, [pc, #imm]      ; N <- offset
    add rX, pc, rN          ; pc = addr_of_add + 8

This tool resolves those pairs and prints the string, which mboot-an.py's
`strings` subcommand cannot do when the ldr and the add are not adjacent.

usage: mbdis.py <image> <start-fileoff> <end-fileoff>
"""
import struct
import sys

from capstone import Cs, CS_ARCH_ARM, CS_MODE_ARM
from capstone.arm import ARM_REG_PC, CS_OP_REG

HDR = 0x2400
BASE = 0x27400000


def cstr(img, fo, limit=200):
    if not 0 <= fo < len(img):
        return None
    end = img.find(b'\0', fo)
    if end < 0 or end - fo > limit or end - fo < 3:
        return None
    return img[fo:end].decode('utf-8', 'replace')[:80]


def dis(img, lo, hi):
    md = Cs(CS_ARCH_ARM, CS_MODE_ARM)
    md.detail = True
    cur = {}
    for ins in md.disasm(img[lo:hi], lo):
        note = ''
        ops = ins.op_str
        if ins.mnemonic in ('ldr', 'ldrh', 'ldrb') and '[pc' in ops:
            tail = ops.rsplit('#', 1)[-1].rstrip(']')
            try:
                disp = int(tail, 0)
            except ValueError:
                disp = None
            if disp is not None:
                lit = ins.address + 8 + disp
                if 0 <= lit <= len(img) - 4:
                    val = struct.unpack_from('<I', img, lit)[0]
                    note = f'  ; L[{lit:#x}]={val:#010x}'
                    if ins.mnemonic == 'ldr':
                        cur[ins.reg_name(ins.operands[0].reg)] = val
        if ins.mnemonic == 'add' and len(ins.operands) == 3:
            o = ins.operands
            if (o[0].type == CS_OP_REG and o[1].type == CS_OP_REG
                    and o[2].type == CS_OP_REG and o[1].reg == ARM_REG_PC):
                src = ins.reg_name(o[2].reg)
                if src in cur:
                    tgt = ins.address + 8 + cur[src]
                    text = cstr(img, tgt)
                    note = f'  ; -> {tgt:#x}'
                    if text is not None:
                        note += f' "{text}"'
        print(f'  {ins.address:#08x} {BASE + ins.address - HDR:#010x}  '
              f'{ins.bytes.hex():8s} {ins.mnemonic:8s} {ops}{note}')
        for reg in ins.regs_access()[1]:
            if ins.mnemonic == 'ldr' and reg == ins.operands[0].reg:
                continue
            cur.pop(md.reg_name(reg), None)


def main():
    img = open(sys.argv[1], 'rb').read()
    dis(img, int(sys.argv[2], 0), int(sys.argv[3], 0))


if __name__ == '__main__':
    main()
