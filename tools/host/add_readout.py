import os
p = os.path.expanduser("~/Debian/m7642/probes/handoff/tramp-postmmu.S")
s = open(p).read()
if "_start_readout" in s:
    print("already"); raise SystemExit
addition = """
/* --------------------------------------------------------------------- *
 * World (B) readout entry: put the kernel's TCR_EL1/TTBR0_EL1 back (so the
 * physical path works), then read a handful of *kernel variables* through the
 * kernel VA map and park them in the SAVE page.  The handover stub copies that
 * block into the record before its 32 MB copy wipes the image, so one run tells
 * us what the kernel believes about itself -- and this run RETURNS, so it costs
 * no power cycle.
 *
 * The variables are passed at build time as -DSYM0_VA=... (a VA, i.e. the link
 * address, which equals the runtime VA) .. -DSYM7_VA=...
 * --------------------------------------------------------------------- */
	.org	0x600
	.globl	_start_readout
_start_readout:
	movz	x16, #(SAVE_VA & 0xffff)
	movk	x16, #((SAVE_VA >> 16) & 0xffff), lsl #16
	movk	x16, #((SAVE_VA >> 32) & 0xffff), lsl #32
	movk	x16, #((SAVE_VA >> 48) & 0xffff), lsl #48
	ldr	x17, [x16, #0x18]	/* TCR as the kernel had it before the teardown */
	msr	tcr_el1, x17
	isb
	ldr	x17, [x16, #0x20]	/* the kernel's own init idmap */
	msr	ttbr0_el1, x17
	dsb	nsh
	isb
	tlbi	vmalle1
	dsb	nsh
	isb
#ifdef SYM0_VA
	ldr	x17, [SYM0_VA] & 0xffff]	/* placeholder, replaced below */
#endif
	mov	x16, x16			/* keep */
	b	9f
9:
	movz	x16, #(SAVE_VA & 0xffff)
	movk	x16, #((SAVE_VA >> 16) & 0xffff), lsl #16
	movk	x16, #((SAVE_VA >> 32) & 0xffff), lsl #32
	movk	x16, #((SAVE_VA >> 48) & 0xffff), lsl #48
"""
# The per-symbol reads are generated here to keep the assembler syntax simple:
for i in range(8):
    addition += """#ifdef SYM%d_VA
	movz	x17, #(SYM%d_VA & 0xffff)
	movk	x17, #((SYM%d_VA >> 16) & 0xffff), lsl #16
	movk	x17, #((SYM%d_VA >> 32) & 0xffff), lsl #32
	movk	x17, #((SYM%d_VA >> 48) & 0xffff), lsl #48
	ldr	x18, [x17]
	str	x18, [x16, #%d]
#endif
""" % (i, i, i, i, i, 0x40 + 8 * i)
addition += """	dsb	sy
	adr	x16, 1b			/* the common path (it precedes us) */
	movz	x17, #(KIMAGE_OFFSET & 0xffff)
	movk	x17, #((KIMAGE_OFFSET >> 16) & 0xffff), lsl #16
	movk	x17, #((KIMAGE_OFFSET >> 32) & 0xffff), lsl #32
	movk	x17, #((KIMAGE_OFFSET >> 48) & 0xffff), lsl #48
	sub	x16, x16, x17
	mov	x5, xzr
	br	x16
"""
# drop the messy placeholder lines
addition = addition.replace("""#ifdef SYM0_VA
	ldr	x17, [SYM0_VA] & 0xffff]	/* placeholder, replaced below */
#endif
	mov	x16, x16			/* keep */
	b	9f
9:
	movz	x16, #(SAVE_VA & 0xffff)
	movk	x16, #((SAVE_VA >> 16) & 0xffff), lsl #16
	movk	x16, #((SAVE_VA >> 32) & 0xffff), lsl #32
	movk	x16, #((SAVE_VA >> 48) & 0xffff), lsl #48
""", "")
s = s.rstrip("\n") + "\n" + addition
open(p, "w").write(s)
print("tramp: _start_readout(0x600) 已加，8 个符号槽")
