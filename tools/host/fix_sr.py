import os
p = os.path.expanduser("~/Debian/m7642/probes/handoff/tramp-postmmu.S")
s = open(p).read()
s = s.replace("\t.org\t0x200\n\t.globl\t_start_save", "\t.org\t0x400\n\t.globl\t_start_save")
s = s.replace("\t.org\t0x240\n\t.globl\t_start_restore", "\t.org\t0x500\n\t.globl\t_start_restore")
# restore 里的 adr 指向公共路径的 1:（在它之前），用 1b
s = s.replace("""	adr	x16, 1f
	movz	x17, #(KIMAGE_OFFSET & 0xffff)
	movk	x17, #((KIMAGE_OFFSET >> 16) & 0xffff), lsl #16
	movk	x17, #((KIMAGE_OFFSET >> 32) & 0xffff), lsl #32
	movk	x17, #((KIMAGE_OFFSET >> 48) & 0xffff), lsl #48
	sub	x16, x16, x17
	mov	x5, xzr
	br	x16
""", """	adr	x16, 1b			/* the common path (it precedes us) */
	movz	x17, #(KIMAGE_OFFSET & 0xffff)
	movk	x17, #((KIMAGE_OFFSET >> 16) & 0xffff), lsl #16
	movk	x17, #((KIMAGE_OFFSET >> 32) & 0xffff), lsl #32
	movk	x17, #((KIMAGE_OFFSET >> 48) & 0xffff), lsl #48
	sub	x16, x16, x17
	mov	x5, xzr
	br	x16
""")
open(p, "w").write(s)
print("offsets 0x400/0x500，adr 改 1b")
