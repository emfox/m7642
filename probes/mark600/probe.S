/*
 * Is the PM wakeup-source word actually writable from the kernel's early boot?
 *
 * Every WakeupSource reading so far has been 1.  That could be our checkpoint
 * being written, or it could be the hardware default, and nothing has ever
 * distinguished the two.  This probe settles it by writing a value that no
 * default would plausibly be: 0xAA55.
 *
 * It sits at +0x600000, the one address proved to execute on this board (the
 * dual2 blob painted the whole panel from there), and code1 is pointed at it,
 * so nothing else about the image layout is in play.
 *
 * Writes then halts; it never returns, because there is nothing to return to.
 */
	.text
	.globl	_start
_start:
	movz	x9, #0x1ce4
	movk	x9, #0x1f00, lsl #16		// 0x1f001ce4: PM wakeup-source word
	movz	w11, #0xaa55
	strh	w11, [x9]
	dsb	sy
	wfe
	b	.
