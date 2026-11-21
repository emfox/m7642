/*
 * Handoff dump: capture the state mboot hands over and leave it in the pstore
 * pmsg zone, so it can be read from Android once the boot finishes.
 *
 * Runs via code1 of the boot image (probe appended to the factory kernel), so
 * it executes before the vendor stub at 0xfa0000 -- x0..x5 are whatever mboot
 * left behind, not the arm64 boot arguments the stub will pass on.  Nothing is
 * written back to x0..x5, and no stack is used: a fault here means a rescue
 * stick, not a warm reset.
 *
 * Record layout, as fs/pstore/ram_core.c expects it (zone registered with
 * sig=0, post_init xors in PERSISTENT_RAM_SIG):
 *
 *   +0x00 u32 sig   = 0x43474244 "DBGC"
 *   +0x04 u32 start = 0          no wrap, oldest byte first
 *   +0x08 u32 size  = 136        valid data bytes that follow
 *   +0x0c data[136]
 */

	.equ	PAYLOAD, 136

	.text
	.globl	_start
_start:
	movz	x6, #0x419c
	lsl	x6, x6, #16			/* x6 = ZONE */
	movz	w7, #0x4244
	movk	w7, #0x4347, lsl #16		/* 0x43474244 "DBGC" */
	str	w7, [x6]
	str	wzr, [x6, #4]			/* start = 0 */
	mov	w7, #PAYLOAD
	str	w7, [x6, #8]			/* size = PAYLOAD */

	add	x6, x6, #12			/* data area */
	movz	w7, #0x3736
	movk	w7, #0x344d, lsl #16		/* "M764" */
	str	w7, [x6], #4
	movz	w7, #0x4e48
	movk	w7, #0x4432, lsl #16		/* "2HND" */
	str	w7, [x6], #4

	str	x0, [x6], #8
	str	x1, [x6], #8
	str	x2, [x6], #8
	str	x3, [x6], #8
	str	x4, [x6], #8
	str	x5, [x6], #8
	mov	x7, sp
	str	x7, [x6], #8
	mrs	x7, SCTLR_EL1
	str	x7, [x6], #8
	mrs	x7, TTBR0_EL1
	str	x7, [x6], #8
	mrs	x7, TCR_EL1
	str	x7, [x6], #8
	mrs	x7, MAIR_EL1
	str	x7, [x6], #8
	mrs	x7, CurrentEL
	str	x7, [x6], #8
	mrs	x7, MPIDR_EL1
	str	x7, [x6], #8
	mrs	x7, ID_AA64MMFR0_EL1
	str	x7, [x6], #8
	mrs	x7, CNTFRQ_EL0
	str	x7, [x6], #8

	/* Clean the three lines the record covers; the kernel maps this as
	 * normal cacheable memory and reads it through its own mapping. */
	movz	x7, #0x419c
	lsl	x7, x7, #16
	dc	cvac, x7
	add	x8, x7, #64
	dc	cvac, x8
	add	x8, x7, #128
	dc	cvac, x8
	dsb	sy

	/* Must be the last word: mk-boot-beacon.py patches it into `b 0xfa0000`
	 * and asserts this placeholder is still here. */
	.word	0x14000000
