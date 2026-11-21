/*
 * Physical handover code for checkpoints AFTER the MMU is on.
 *
 * Appended after the kernel at Image+0x1400000, so this code sits at
 * PA 0x21680000 -- outside 0x20280000..0x21554a00, the region the factory
 * kernel copy below overwrites.  It is reached from tramp-postmmu.S with the
 * MMU and the caches already off, so every address here is physical.
 *
 * It records "M764"/"MMMU", x30 (the checkpoint return address) and the boot
 * arguments into 0x23080000, copies the staged factory kernel
 * (0x30000800 -> 0x20280000, 0x12d4a00 bytes), clears x3/x4 so the factory
 * kernel does not pick up a ramdisk, and enters it at 0x21220000.
 */
	.text
	.org	0x200
	.globl	handover_phys
handover_phys:
	movz	x6, #0x2308
	lsl	x6, x6, #16		/* 0x23080000 */
	movz	w7, #0x374d
	movk	w7, #0x3436, lsl #16	/* "M764" */
	str	w7, [x6]
	movz	w7, #0x4d4d
	movk	w7, #0x554d, lsl #16	/* "MMMU" */
	str	w7, [x6, #4]
	mov	w7, #0x40
	str	w7, [x6, #8]
	str	wzr, [x6, #12]
	str	x30, [x6, #16]
	stp	x0, x1, [x6, #24]
	stp	x2, x3, [x6, #40]
	str	x4, [x6, #56]
	dsb	sy

	movz	x6, #0x3000
	lsl	x6, x6, #16
	add	x6, x6, #0x800		/* staged factory kernel */
	movz	x7, #0x2028
	lsl	x7, x7, #16		/* runtime image base */
	movz	x8, #0x4a00
	movk	x8, #0x012d, lsl #16	/* 0x12d4a00 bytes */
1:
	ldp	x9, x10, [x6], #16
	stp	x9, x10, [x7], #16
	subs	x8, x8, #16
	b.ne	1b
	dsb	sy

	mov	w3, wzr
	mov	w4, wzr
	movz	x9, #0x2122
	lsl	x9, x9, #16		/* factory entry 0x21220000 */
	br	x9
