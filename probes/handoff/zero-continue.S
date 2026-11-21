/*
 * Zero the page-table pool, then continue into the kernel.
 *
 * create_init_idmap builds its tables at 0x20730000, which is .bss -- and mboot
 * neither loads nor clears .bss, so the pool holds whatever the previous boot
 * left there.  map_range treats a non-zero entry as an existing table and
 * follows it, so garbage there is fatal and the outcome depends on the leftover
 * contents: the run-to-run variation.
 *
 * x0..x3 (mboot's boot arguments) must survive; only x6/x7/x9 are used.
 */
	.text
	.globl	_start
_start:
	movz	x6, #0x2073
	lsl	x6, x6, #16			/* 0x20730000 */
	movz	x7, #0x8000			/* 32 KiB */
1:
	str	xzr, [x6], #8
	subs	x7, x7, #8
	b.ne	1b
	dsb	sy
	/* original code1 target: image_base + 0xb70000 */
	movz	x9, #0x20df
	lsl	x9, x9, #16
	br	x9
