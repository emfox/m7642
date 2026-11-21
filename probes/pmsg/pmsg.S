/*
 * Leave a mark in the pmsg ramoops zone.
 *
 * Three colour attempts in a row failed on the boot path -- 0x2d100000 (the
 * GWIN ring buffer), the gop0/bank1/win0 control word plus 0x2d100000, and
 * 0x24e00000 (MI_BOOTLOGO_BUF_ADR from mboot's environment).  The logo never
 * flickered once, while the probe's 8-second hold showed up every time, so
 * the code runs and nothing we write reaches the panel.  Either mboot stops
 * scanning before it jumps to the kernel, or the logo is not scanned out of
 * DDR at all.
 *
 * So stop asking the screen and use the channel the kernel itself provides.
 * Measured on this box with the vendor 4.9 kernel:
 *
 *   /sys/module/ramoops/parameters/mem_address = 0x41900000  (1 MiB)
 *   record_size = console_size = pmsg_size = 262144, ecc = 0
 *   /proc/iomem shows four 256K zones at 0x4190/0x4194/0x4198/0x419c
 *
 * Writing "M7642PROBE" to /dev/pmsg0 changed only 0x419c0000, so that is the
 * pmsg zone.  A zone whose signature matches is kept across a warm boot
 * instead of being zapped, and pstore exports it as
 * /sys/fs/pstore/pmsg-ramoops-0 -- a plain `adb cat`, no probeRW, no panel.
 *
 * Layout is struct persistent_ram_buffer:
 *
 *   +0  u32 sig    0x43474244 ("DBDC")
 *   +4  u32 start
 *   +8  u32 size
 *   +12 data
 */

	.section .text, "ax"
	.global _start
_start:
	movz	x16, #0x419c
	lsl	x16, x16, #16			// 0x419c0000: pmsg zone
	movz	w17, #0x4244
	movk	w17, #0x4347, lsl #16		// 0x43474244: RAMOOPS_SIG
	str	w17, [x16]
	str	wzr, [x16, #4]			// start = 0
	mov	w17, #8
	str	w17, [x16, #8]			// size = 8
	movz	w17, #0x374d
	movk	w17, #0x3436, lsl #16		// "M764"
	str	w17, [x16, #12]
	movz	w17, #0x5032
	movk	w17, #0x0a31, lsl #16		// "2P1\n"
	str	w17, [x16, #16]

	/* the kernel will invalidate the cache early; push both lines out */
	dc	cvac, x16
	add	x16, x16, #64
	dc	cvac, x16
	dsb	sy

	.word	0x14000000			// patched: b 0xFA0000
