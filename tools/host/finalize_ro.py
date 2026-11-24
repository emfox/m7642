import os
H = os.path.expanduser("~/Debian/m7642/probes/handoff")

# 默认符号集（明天第一发用）
p = os.path.join(H, "mk-multi.sh"); s = open(p).read()
s = s.replace('READOUT_SYMS=$(syms_to_vas "${READOUT_SYMS:-totalram_pages memblock+32 memblock+72 max_pfn}")',
              'READOUT_SYMS=$(syms_to_vas "${READOUT_SYMS:-memblock+16 memblock+32 memblock+56 memblock+72 max_pfn min_low_pfn}")')
open(p, "w").write(s)

# 解码器：打印 0xB0..0xEF 的读数值
p = os.path.expanduser("~/Debian/m7642/tools/host/decode-record.py"); s = open(p).read()
if "readout" not in s:
    s = s.replace('''    mpidr = q(b, 0xA8)''','''    # readout slots (only present when the record is 0xF0: the "readout" entry
    # parked kernel variables in the SAVE page and the stub rescued them)
    labels = ["memblock.memory.cnt", "memblock.memory.total_size",
              "memblock.reserved.cnt", "memblock.reserved.total_size",
              "max_pfn", "min_low_pfn", "SYM6", "SYM7"]
    vals = [(labels[i], q(b, 0xB0 + 8 * i)) for i in range(8)]
    if any(v is not None and v != 0 for _, v in vals):
        print("  readout:")
        for name, v in vals:
            if v is not None:
                print("    %-28s = %#x (%d)" % (name, v, v))

    mpidr = q(b, 0xA8)''')
    open(p, "w").write(s); print("decode-record.py: readout 槽已加")
