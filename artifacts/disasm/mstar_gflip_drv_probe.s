// mstar_gflip_drv_probe @ 0xffffff80088e8cec
   0:	a9be7bfd 	stp	x29, x30, [sp, #-32]!
   4:	910003fd 	mov	x29, sp
   8:	f9000bf3 	str	x19, [sp, #16]
   c:	aa0003f3 	mov	x19, x0
  10:	aa1e03e0 	mov	x0, x30
  14:	d503201f 	nop
  18:	f9005a7f 	str	xzr, [x19, #176]
  1c:	52800000 	mov	w0, #0x0                   	// #0
  20:	f9400bf3 	ldr	x19, [sp, #16]
  24:	a8c27bfd 	ldp	x29, x30, [sp], #32
  28:	d65f03c0 	ret
  2c:	a9be7bfd 	stp	x29, x30, [sp, #-32]!
  30:	910003fd 	mov	x29, sp
  34:	f9000bf3 	str	x19, [sp, #16]
  38:	aa0003f3 	mov	x19, x0
  3c:	aa1e03e0 	mov	x0, x30
  40:	d503201f 	nop
  44:	f9005a7f 	str	xzr, [x19, #176]
  48:	52800000 	mov	w0, #0x0                   	// #0
  4c:	f9400bf3 	ldr	x19, [sp, #16]
  50:	a8c27bfd 	ldp	x29, x30, [sp], #32
  54:	d65f03c0 	ret
  58:	a9bd7bfd 	stp	x29, x30, [sp, #-48]!
  5c:	910003fd 	mov	x29, sp
  60:	a90153f3 	stp	x19, x20, [sp, #16]
  64:	a9025bf5 	stp	x21, x22, [sp, #32]
  68:	f0005c13 	adrp	x19, 0xb83000
  6c:	aa1e03e0 	mov	x0, x30
  70:	9123a273 	add	x19, x19, #0x8e8
  74:	aa0103f5 	mov	x21, x1
  78:	91100274 	add	x20, x19, #0x400
  7c:	d503201f 	nop
  80:	aa1303f6 	mov	x22, x19
  84:	14000004 	b	0x94
  88:	91004273 	add	x19, x19, #0x10
  8c:	eb14027f 	cmp	x19, x20
  90:	540001e0 	b.eq	0xcc  // b.none
  94:	f9400260 	ldr	x0, [x19]
  98:	eb15001f 	cmp	x0, x21
  9c:	54ffff61 	b.ne	0x88  // b.any
  a0:	b9400a60 	ldr	w0, [x19, #8]
  a4:	911002c1 	add	x1, x22, #0x400
  a8:	78605822 	ldrh	w2, [x1, w0, uxtw #1]
  ac:	51000442 	sub	w2, w2, #0x1
  b0:	53003c42 	uxth	w2, w2
  b4:	78205822 	strh	w2, [x1, w0, uxtw #1]
  b8:	340001e2 	cbz	w2, 0xf4
  bc:	f900027f 	str	xzr, [x19]
  c0:	91004273 	add	x19, x19, #0x10
  c4:	eb14027f 	cmp	x19, x20
  c8:	54fffe61 	b.ne	0x94  // b.any
  cc:	f0004d61 	adrp	x1, 0x9af000
  d0:	52800000 	mov	w0, #0x0                   	// #0
  d4:	91214021 	add	x1, x1, #0x850
  d8:	b9400822 	ldr	w2, [x1, #8]
  dc:	51000442 	sub	w2, w2, #0x1
  e0:	b9000822 	str	w2, [x1, #8]
  e4:	a94153f3 	ldp	x19, x20, [sp, #16]
  e8:	a9425bf5 	ldp	x21, x22, [sp, #32]
  ec:	a8c37bfd 	ldp	x29, x30, [sp], #48
  f0:	d65f03c0 	ret
  f4:	94001586 	bl	0x570c
  f8:	f900027f 	str	xzr, [x19]
  fc:	17fffff1 	b	0xc0
 100:	a9be7bfd 	stp	x29, x30, [sp, #-32]!
 104:	910003fd 	mov	x29, sp
 108:	a90153f3 	stp	x19, x20, [sp, #16]
 10c:	f0004d73 	adrp	x19, 0x9af000
 110:	aa1e03e0 	mov	x0, x30
 114:	91214274 	add	x20, x19, #0x850
 118:	d503201f 	nop
 11c:	90002541 	adrp	x1, 0x4a8000
 120:	90003320 	adrp	x0, 0x664000
 124:	d5384104 	mrs	x4, sp_el0
 128:	b9400a85 	ldr	w5, [x20, #8]
 12c:	528088c2 	mov	w2, #0x446                 	// #1094
 130:	b945c083 	ldr	w3, [x4, #1472]
 134:	910e0021 	add	x1, x1, #0x380
 138:	911e2084 	add	x4, x4, #0x788
 13c:	912a2000 	add	x0, x0, #0xa88
 140:	97e41683 	bl	0xffffffffff905b4c
 144:	b9400a80 	ldr	w0, [x20, #8]
 148:	35000060 	cbnz	w0, 0x154
 14c:	94000f48 	bl	0x3e6c
 150:	b9400a80 	ldr	w0, [x20, #8]
 154:	91214273 	add	x19, x19, #0x850
 158:	11000401 	add	w1, w0, #0x1
 15c:	52800000 	mov	w0, #0x0                   	// #0
 160:	b9000a61 	str	w1, [x19, #8]
 164:	a94153f3 	ldp	x19, x20, [sp, #16]
 168:	a8c27bfd 	ldp	x29, x30, [sp], #32
 16c:	d65f03c0 	ret
 170:	a9bd7bfd 	stp	x29, x30, [sp, #-48]!
 174:	910003fd 	mov	x29, sp
 178:	a90153f3 	stp	x19, x20, [sp, #16]
 17c:	aa0003f4 	mov	x20, x0
 180:	aa1e03e0 	mov	x0, x30
 184:	90004733 	adrp	x19, 0x8e4000
 188:	d503201f 	nop
 18c:	911c2262 	add	x2, x19, #0x708
 190:	910087a1 	add	x1, x29, #0x21
 194:	f9400043 	ldr	x3, [x2]
 198:	f90017a3 	str	x3, [x29, #40]
 19c:	d2800003 	mov	x3, #0x0                   	// #0
 1a0:	910083a0 	add	x0, x29, #0x20
 1a4:	94000bd1 	bl	0x30e8
 1a8:	394083a1 	ldrb	w1, [x29, #32]
 1ac:	39400280 	ldrb	w0, [x20]
 1b0:	394087a2 	ldrb	w2, [x29, #33]
 1b4:	39000682 	strb	w2, [x20, #1]
 1b8:	6b00003f 	cmp	w1, w0
 1bc:	54000161 	b.ne	0x1e8  // b.any
 1c0:	39000a9f 	strb	wzr, [x20, #2]
 1c4:	911c2273 	add	x19, x19, #0x708
 1c8:	52800020 	mov	w0, #0x1                   	// #1
 1cc:	f94017a1 	ldr	x1, [x29, #40]
 1d0:	f9400261 	ldr	x1, [x19]
 1d4:	ca010021 	eor	x1, x1, x1
 1d8:	b5000121 	cbnz	x1, 0x1fc
 1dc:	a94153f3 	ldp	x19, x20, [sp, #16]
 1e0:	a8c37bfd 	ldp	x29, x30, [sp], #48
 1e4:	d65f03c0 	ret
 1e8:	52800021 	mov	w1, #0x1                   	// #1
 1ec:	aa1403e0 	mov	x0, x20
 1f0:	39000a81 	strb	w1, [x20, #2]
 1f4:	94001740 	bl	0x5ef4
 1f8:	17fffff3 	b	0x1c4
 1fc:	97df8e31 	bl	0xffffffffff7e3ac0
