/*
 * Entry memory snapshot: dump the three regions whose contents could plausibly
 * differ between runs, then hand over immediately (no kernel execution).
 *
 *   stash page 0: "M764" "SNAP" + 48 words
 *     +0x10..0x4c : dtb header, 16 words at 0x23000000
 *     +0x50..0x8c : __pi_init_idmap_pg_dir, 16 words at 0x20730000
 *     +0x90..0xcc : early init stack area, 16 words at 0x206ECF80
 *
 * Run it N times and diff: if these are identical every time, the entry memory
 * state is deterministic and the variation must come from execution.
 */
	.text
	.globl	_start
_start:
	movz	x6, #0x2308
	lsl	x6, x6, #16
	movz	w7, #0x374d
	movk	w7, #0x3436, lsl #16		/* "M764" */
	str	w7, [x6]
	movz	w7, #0x4e53
	movk	w7, #0x5041, lsl #16		/* "SNAP" */
	str	w7, [x6, #4]

	movz	x9, #0x2300
	lsl	x9, x9, #16			/* dtb */
	.set	R, 0
	.rept	16
	ldr	w10, [x9, #(R*4)]
	str	w10, [x6, #(0x10 + R*4)]
	.set	R, R+1
	.endr

	movz	x9, #0x2073
	lsl	x9, x9, #16			/* page-table pool */
	.set	R, 0
	.rept	16
	ldr	w10, [x9, #(R*4)]
	str	w10, [x6, #(0x50 + R*4)]
	.set	R, R+1
	.endr

	movz	x9, #0x206e
	lsl	x9, x9, #16
	movz	x10, #0xcf80
	add	x9, x9, x10			/* init stack area */
	.set	R, 0
	.rept	16
	ldr	w10, [x9, #(R*4)]
	str	w10, [x6, #(0x90 + R*4)]
	.set	R, R+1
	.endr
	dsb	sy

	/* handover */
	movz	x6, #0x3000
	lsl	x6, x6, #16
	add	x6, x6, #0x800
	movz	x7, #0x2028
	lsl	x7, x7, #16
	movz	x8, #0x4a00
	movk	x8, #0x012d, lsl #16
1:
	ldp	x9, x10, [x6], #16
	stp	x9, x10, [x7], #16
	subs	x8, x8, #16
	b.ne	1b
	dsb	sy
	mov	w3, wzr
	mov	w4, wzr
	movz	x9, #0x2122
	lsl	x9, x9, #16
	br	x9
