/*
 * Single-step tracer, rung 0: "checkpoint -> hand over to the factory kernel".
 *
 * The recovery and boot partitions hold the SAME kernel binary (md5
 * 6c650b9c2ffcfa43d1e11615d1bb286a), so after writing a checkpoint there is
 * nothing to copy: just drop the recovery ramdisk arguments (x3/x4, written by
 * mboot) and fall through to the injected branch into the factory entry.  The
 * kernel then has no ramdisk and boots /system exactly like bootcmd does, so
 * the checkpoint is readable in the SAME boot -- no reset, no WDT, no screen.
 *
 * x0/x1/x2/x5 are left untouched: they are mboot's handoff values.
 */
	.text
	.globl	_start
_start:
	movz	x6, #0x2308
	lsl	x6, x6, #16			/* stash page 0 */
	movz	w7, #0x374d
	movk	w7, #0x3436, lsl #16		/* "M764" */
	str	w7, [x6]
	movz	w7, #0x5453
	movk	w7, #0x5045, lsl #16		/* "STEP" */
	str	w7, [x6, #4]
	mov	w7, #2				/* rung 0 = this mechanism test */
	str	w7, [x6, #8]
	dsb	sy

	/* no ramdisk: let the kernel mount /system and boot Android */
	mov	w3, wzr
	mov	w4, wzr
	dsb	sy

	/* last word: mk-boot-beacon patches it to `b image_base + 0xfa0000` */
	.word	0x14000000
