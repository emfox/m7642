import struct, sys

def elf(code, entry_off=0x100):
    # one PT_LOAD covering whole file, RX, vaddr 0x400000
    body = bytearray(b'\0' * entry_off) + code
    eh = b'\x7fELF' + bytes([2,1,1,0]) + b'\0'*8
    eh += struct.pack('<HHIQQQIHHHHHH',
        2, 183, 1,               # ET_EXEC, EM_AARCH64, ver
        0x400000 + entry_off,    # e_entry
        64, 0, 0,                # phoff, shoff, flags
        64, 56, 1,               # ehsize, phentsize, phnum
        0, 0, 0)                 # shentsize, shnum, shstrndx
    ph = struct.pack('<IIQQQQQQ',
        1, 5, 0, 0x400000, 0x400000, len(body), len(body), 0x1000)
    return bytes(eh) + ph + bytes(body[64+56:])

def w(*ins):
    return b''.join(struct.pack('<I', i) for i in ins)

EXIT = [0xD2800BA8, 0xD4000001]        # mov x8,#93 ; svc #0

cases = {
 # mrs x0, S3_0_C0_C7_0  (ID_AA64MMFR0_EL1) -- control, must work
 'mmfr0': w(0xD5380700, *EXIT),
 # mrs x0, S3_0_C0_C7_3  (ID_AA64MMFR3_EL1) -- the suspect
 'mmfr3': w(0xD5380760, *EXIT),
 # UDF #0 -- must SIGILL, control for the detector itself
 'udf':   w(0x00000000),
 # mrs x0, S3_0_C0_C7_7  (unallocated in ID space) -- forward-compat probe
 'idres7':w(0xD53807E0, *EXIT),
}
for n, c in cases.items():
    open(__import__('os').path.join(__import__('os').path.dirname(__import__('os').path.abspath(__file__)), n), 'wb').write(elf(c))
    print(n, len(elf(c)))
