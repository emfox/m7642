/*
 * Transition stub for checkpoints AFTER the MMU is on.
 *
 * Injected into the padding at the end of .text (Image+0x36c000), i.e. inside
 * the range that map_kernel() maps ROX at the kernel VA and that
 * create_init_idmap() maps ROX identity.  The checkpoint is patched with
 * "bl tramp"; the handover body itself lives outside the region the factory
 * kernel copy overwrites (see abort-postmmu.S).
 *
 * Two entry points, chosen per checkpoint:
 *   _start      the checkpoint already executes at its physical address
 *               (__pi_early_map_kernel and earlier); the idmap VA == PA.
 *   _start_kva  the checkpoint executes at the kernel VA (__primary_switched,
 *               start_kernel, setup_arch); hop to the idmap alias first.
 *
 * Then: x0..x2 = the entry registers 7.3 preserved in boot_args[], x3/x4 = 0
 * (no ramdisk), drop dirty D-cache lines over the image, turn the MMU and the
 * caches off, and jump to the physical handover at 0x21680200.
 *
 * _start_fdt is the pre-MMU entry shim (patched over code1).  MStar's
 * bootloader leaves x0 = 0 while the factory kernel hardcodes the tree at
 * 0x23000000; early_map_kernel() parses that pointer before setup_arch() can
 * substitute the built-in tree, so x0 must be valid.  It records the
 * bootloader's registers at 0x23090000 first.
 *
 * All addresses are passed in by build-postmmu.sh from System.map.
 */
#ifndef BOOT_ARGS_PA
#define BOOT_ARGS_PA 0x207d4000
#endif
#ifndef IMAGE_START_PA
#define IMAGE_START_PA 0x20290000
#endif
#ifndef IMAGE_END_PA
#define IMAGE_END_PA 0x208f0000
#endif
#ifndef KIMAGE_OFFSET
#define KIMAGE_OFFSET 0xffffffc05fd80000
#endif
#ifndef PRIMARY_ENTRY_PA
#define PRIMARY_ENTRY_PA 0x206d5038
#endif

	.text
	.globl	_start
_start:
	b	1f

	.globl	_start_kva
_start_kva:
	adr	x16, 1f
	movz	x17, #(KIMAGE_OFFSET & 0xffff)
	movk	x17, #((KIMAGE_OFFSET >> 16) & 0xffff), lsl #16
	movk	x17, #((KIMAGE_OFFSET >> 32) & 0xffff), lsl #32
	movk	x17, #((KIMAGE_OFFSET >> 48) & 0xffff), lsl #48	/* KIMAGE_VADDR - PA(_text) */
	sub	x16, x16, x17
	br	x16

1:
	mov	x21, x8			/* the `br x8` target, for the record */
	mrs	x22, sctlr_el1		/* was the MMU really on? */

	movz	x16, #(BOOT_ARGS_PA & 0xffff)
	movk	x16, #((BOOT_ARGS_PA >> 16) & 0xffff), lsl #16
	ldp	x0, x1, [x16]
	ldr	x2, [x16, #16]
	mov	x3, xzr
	mov	x4, xzr

	movz	x19, #(IMAGE_START_PA & 0xffff)
	movk	x19, #((IMAGE_START_PA >> 16) & 0xffff), lsl #16
	movz	x20, #(IMAGE_END_PA & 0xffff)
	movk	x20, #((IMAGE_END_PA >> 16) & 0xffff), lsl #16
2:
	dc	civac, x19
	add	x19, x19, #64
	cmp	x19, x20
	b.lo	2b
	dsb	sy
	ic	iallu
	dsb	sy
	isb

	mov	x16, xzr
	mov	sp, x16
	mrs	x16, sctlr_el1
	bic	x16, x16, #1		/* M */
	bic	x16, x16, #4		/* C */
	bic	x16, x16, #0x1000	/* I */
	msr	sctlr_el1, x16
	isb
	movz	x16, #0x2168
	lsl	x16, x16, #16
	add	x16, x16, #0x200
	br	x16

	.org	0xc0
	.globl	_start_fdt
_start_fdt:
	movz	x6, #0x0000
	movk	x6, #0x2309, lsl #16	/* 0x23090000 */
	movz	w7, #0x374d
	movk	w7, #0x3436, lsl #16	/* "M764" */
	str	w7, [x6]
	movz	w7, #0x4446
	movk	w7, #0x2054, lsl #16	/* "FDT " */
	str	w7, [x6, #4]
	str	wzr, [x6, #8]
	str	wzr, [x6, #12]
	str	x30, [x6, #16]
	stp	x0, x1, [x6, #24]
	stp	x2, x3, [x6, #40]
	stp	x4, x5, [x6, #56]
	dsb	sy

	movz	x0, #0x2300
	lsl	x0, x0, #16		/* 0x23000000: factory DTB */
	movz	x6, #(PRIMARY_ENTRY_PA & 0xffff)
	movk	x6, #((PRIMARY_ENTRY_PA >> 16) & 0xffff), lsl #16
	br	x6
