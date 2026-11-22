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
	/* The tramp may enter here with the MMU still on (it installs a 1 GB
	 * identity block just before jumping, so this physical address is
	 * addressable).  Clear M/C/I now that we are identity-mapped and never
	 * come back: from here on everything is plain physical addressing, which
	 * is the state mboot hands the factory kernel. */
	mrs	x16, sctlr_el1
	mov	x27, x16		/* keep the kernel's own SCTLR for the record */
	tbz	x16, #0, 9f		/* M == 0 -> the MMU is already off */
				/* (test the hardware, not a value we passed in:
				 * trusting a register once put us here with the MMU
				 * on while the code believed it was off) */
	bic	x16, x16, #1
	bic	x16, x16, #4
	bic	x16, x16, #0x1000
	msr	sctlr_el1, x16
	isb
	mov	x5, xzr
9:
	movz	x6, #0x2308
	lsl	x6, x6, #16		/* 0x23080000 */
	movz	w7, #0x374d
	movk	w7, #0x3436, lsl #16	/* "M764" */
	str	w7, [x6]
	movz	w7, #0x4d4d
	movk	w7, #0x554d, lsl #16	/* "MMMU" */
	str	w7, [x6, #4]
	mov	w7, #0xB0
	str	w7, [x6, #8]
	str	wzr, [x6, #12]
	str	x30, [x6, #16]
	stp	x0, x1, [x6, #24]
	stp	x2, x3, [x6, #40]
	str	x4, [x6, #56]
	str	x21, [x6, #64]		/* br x8 target */
	str	x22, [x6, #72]		/* SCTLR_EL1 */
	str	x23, [x6, #80]
	str	x24, [x6, #88]
	str	x25, [x6, #96]
	str	x26, [x6, #104]
	str	x27, [x6, #112]		/* SCTLR_EL1 as the kernel had it */
	/* Hardware identity.  Read on the TV and in QEMU so that we can say how
	 * faithful the emulation is for the parts we exercise (page tables and
	 * cache maintenance depend on CTR/TCR/MAIR, not on the core's marketing
	 * name).  These need no MMU, so they are safe here. */
	mrs	x17, midr_el1
	str	x17, [x6, #120]
	mrs	x17, ctr_el0
	str	x17, [x6, #128]
	mrs	x17, revidr_el1
	str	x17, [x6, #136]
	mrs	x17, tcr_el1
	str	x17, [x6, #144]
	mrs	x17, mair_el1
	str	x17, [x6, #152]
	mrs	x17, id_aa64mmfr0_el1
	str	x17, [x6, #160]
	mrs	x17, mpidr_el1
	str	x17, [x6, #168]
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
