
spin_boot_cpu.bin:     file format binary


Disassembly of section .data:

ffffff8008cb2c60 <.data>:
ffffff8008cb2c60:	a9bd7bfd 	stp	x29, x30, [sp, #-48]!
ffffff8008cb2c64:	90002962 	adrp	x2, 0xffffff80091de000
ffffff8008cb2c68:	d2800101 	movz	x1, #0x8
ffffff8008cb2c6c:	910003fd 	add	x29, sp, #0x0
ffffff8008cb2c70:	91318042 	add	x2, x2, #0xc60
ffffff8008cb2c74:	a90153f3 	stp	x19, x20, [sp, #16]
ffffff8008cb2c78:	f90013f5 	str	x21, [sp, #32]
ffffff8008cb2c7c:	d0003513 	adrp	x19, 0xffffff8009354000
ffffff8008cb2c80:	f8605842 	ldr	x2, [x2, w0, uxtw #3]
ffffff8008cb2c84:	91200260 	add	x0, x19, #0x800
ffffff8008cb2c88:	f9040262 	str	x2, [x19, #2048]
ffffff8008cb2c8c:	97d02c51 	bl	0xffffff80080bddd0
ffffff8008cb2c90:	d503209f 	hint	#0x4
ffffff8008cb2c94:	900028c0 	adrp	x0, 0xffffff80091ca000
ffffff8008cb2c98:	aa0003f5 	orr	x21, xzr, x0
ffffff8008cb2c9c:	f9454014 	ldr	x20, [x0, #2688]
ffffff8008cb2ca0:	9103ea94 	add	x20, x20, #0xfa
ffffff8008cb2ca4:	f94542a1 	ldr	x1, [x21, #2688]
ffffff8008cb2ca8:	d294f8c0 	movz	x0, #0xa7c6
ffffff8008cb2cac:	cb140021 	sub	x1, x1, x20
ffffff8008cb2cb0:	b6f800c1 	tbz	x1, #63, 0xffffff8008cb2cc8
ffffff8008cb2cb4:	f9440261 	ldr	x1, [x19, #2048]
ffffff8008cb2cb8:	b100043f 	adds	xzr, x1, #0x1
ffffff8008cb2cbc:	54000060 	b.eq	0xffffff8008cb2cc8  // b.none
ffffff8008cb2cc0:	97e34b46 	bl	0xffffff80085859d8
ffffff8008cb2cc4:	17fffff8 	b	0xffffff8008cb2ca4
ffffff8008cb2cc8:	f9440260 	ldr	x0, [x19, #2048]
ffffff8008cb2ccc:	f94013f5 	ldr	x21, [sp, #32]
ffffff8008cb2cd0:	b100041f 	adds	xzr, x0, #0x1
ffffff8008cb2cd4:	128004a0 	movn	w0, #0x25
ffffff8008cb2cd8:	1a9f1000 	csel	w0, w0, wzr, ne  // ne = any
ffffff8008cb2cdc:	a94153f3 	ldp	x19, x20, [sp, #16]
ffffff8008cb2ce0:	a8c37bfd 	ldp	x29, x30, [sp], #48
ffffff8008cb2ce4:	d65f03c0 	ret
ffffff8008cb2ce8:	a9bf7bfd 	stp	x29, x30, [sp, #-16]!
ffffff8008cb2cec:	d0003502 	adrp	x2, 0xffffff8009354000
ffffff8008cb2cf0:	92800003 	movn	x3, #0x0
ffffff8008cb2cf4:	910003fd 	add	x29, sp, #0x0
ffffff8008cb2cf8:	d2800101 	movz	x1, #0x8
ffffff8008cb2cfc:	91200040 	add	x0, x2, #0x800
ffffff8008cb2d00:	f9040043 	str	x3, [x2, #2048]
ffffff8008cb2d04:	97d02c33 	bl	0xffffff80080bddd0
ffffff8008cb2d08:	a8c17bfd 	ldp	x29, x30, [sp], #16
ffffff8008cb2d0c:	d65f03c0 	ret
	...
