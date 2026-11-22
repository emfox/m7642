/* tramp-blob.S -- patches the assembled tramp blob into the fake image at
 * IMAGE_BASE+0x20000, which is exactly how the real build injects it into the
 * kernel Image (blob offset 0xc0 == _start_fdt etc. stay intact). */
	.section .tramp, "ax"
	.incbin "gen/tramp.bin"
