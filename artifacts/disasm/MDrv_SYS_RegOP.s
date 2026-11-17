// MDrv_SYS_RegOP @ 0xffffff8008896550
   0:	a9bb7bfd 	stp	x29, x30, [sp, #-80]!
   4:	910003fd 	mov	x29, sp
   8:	a90153f3 	stp	x19, x20, [sp, #16]
   c:	f90013f5 	str	x21, [sp, #32]
  10:	aa0003f4 	mov	x20, x0
  14:	aa1e03e0 	mov	x0, x30
  18:	d00049b3 	adrp	x19, 0x936000
  1c:	d503201f 	nop
  20:	911c2260 	add	x0, x19, #0x708
  24:	aa1403e3 	mov	x3, x20
  28:	d5384101 	mrs	x1, sp_el0
  2c:	f9400422 	ldr	x2, [x1, #8]
  30:	f9400001 	ldr	x1, [x0]
  34:	f90027a1 	str	x1, [x29, #72]
  38:	d2800001 	mov	x1, #0x0                   	// #0
  3c:	b1004063 	adds	x3, x3, #0x10
  40:	9a8283e2 	csel	x2, xzr, x2, hi  // hi = pmore
  44:	da9f3063 	csinv	x3, x3, xzr, cc  // cc = lo, ul, last
  48:	fa02007f 	sbcs	xzr, x3, x2
  4c:	9a9f87e3 	cset	x3, ls  // ls = plast
  50:	9100e3b5 	add	x21, x29, #0x38
  54:	b50005e3 	cbnz	x3, 0x110
  58:	d2800200 	mov	x0, #0x10                  	// #16
  5c:	aa1503e3 	mov	x3, x21
  60:	aa0003e2 	mov	x2, x0
  64:	52800001 	mov	w1, #0x0                   	// #0
  68:	aa0303e0 	mov	x0, x3
  6c:	97f3be91 	bl	0xffffffffffcefab0
  70:	d0003540 	adrp	x0, 0x6aa000
  74:	91104000 	add	x0, x0, #0x410
  78:	97e5609c 	bl	0xffffffffff9582e8
  7c:	b9403fa0 	ldr	w0, [x29, #60]
  80:	35000280 	cbnz	w0, 0xd0
  84:	d0005601 	adrp	x1, 0xac2000
  88:	b94043a2 	ldr	w2, [x29, #64]
  8c:	d5384100 	mrs	x0, sp_el0
  90:	aa1403e3 	mov	x3, x20
  94:	f9402421 	ldr	x1, [x1, #72]
  98:	91600021 	add	x1, x1, #0x800, lsl #12
  9c:	b8626821 	ldr	w1, [x1, x2]
  a0:	b90047a1 	str	w1, [x29, #68]
  a4:	f9400402 	ldr	x2, [x0, #8]
  a8:	b1004063 	adds	x3, x3, #0x10
  ac:	9a8283e2 	csel	x2, xzr, x2, hi  // hi = pmore
  b0:	da9f3063 	csinv	x3, x3, xzr, cc  // cc = lo, ul, last
  b4:	fa02007f 	sbcs	xzr, x3, x2
  b8:	9a9f87e3 	cset	x3, ls  // ls = plast
  bc:	b50003a3 	cbnz	x3, 0x130
  c0:	d0003540 	adrp	x0, 0x6aa000
  c4:	91132000 	add	x0, x0, #0x4c8
  c8:	97e56088 	bl	0xffffffffff9582e8
  cc:	14000007 	b	0xe8
  d0:	d0005600 	adrp	x0, 0xac2000
  d4:	b94043a1 	ldr	w1, [x29, #64]
  d8:	b94047a2 	ldr	w2, [x29, #68]
  dc:	f9402400 	ldr	x0, [x0, #72]
  e0:	91600000 	add	x0, x0, #0x800, lsl #12
  e4:	b8216802 	str	w2, [x0, x1]
  e8:	911c2273 	add	x19, x19, #0x708
  ec:	52800000 	mov	w0, #0x0                   	// #0
  f0:	f94027a1 	ldr	x1, [x29, #72]
  f4:	f9400261 	ldr	x1, [x19]
  f8:	ca010021 	eor	x1, x1, x1
  fc:	b5000261 	cbnz	x1, 0x148
 100:	a94153f3 	ldp	x19, x20, [sp, #16]
 104:	f94013f5 	ldr	x21, [sp, #32]
 108:	a8c57bfd 	ldp	x29, x30, [sp], #80
 10c:	d65f03c0 	ret
 110:	d2800202 	mov	x2, #0x10                  	// #16
 114:	aa1403e1 	mov	x1, x20
 118:	aa1503e0 	mov	x0, x21
 11c:	97f3ba85 	bl	0xffffffffffceeb30
 120:	b4fffae0 	cbz	x0, 0x7c
 124:	cb0002a3 	sub	x3, x21, x0
 128:	91004063 	add	x3, x3, #0x10
 12c:	17ffffcd 	b	0x60
 130:	d2800202 	mov	x2, #0x10                  	// #16
 134:	aa1503e1 	mov	x1, x21
 138:	aa1403e0 	mov	x0, x20
 13c:	97f3bc1d 	bl	0xffffffffffcef1b0
 140:	b4fffd40 	cbz	x0, 0xe8
 144:	17ffffdf 	b	0xc0
 148:	97e0d845 	bl	0xffffffffff83625c
 14c:	a9b77bfd 	stp	x29, x30, [sp, #-144]!
 150:	910003fd 	mov	x29, sp
 154:	a90153f3 	stp	x19, x20, [sp, #16]
 158:	a9025bf5 	stp	x21, x22, [sp, #32]
 15c:	a90363f7 	stp	x23, x24, [sp, #48]
 160:	a9046bf9 	stp	x25, x26, [sp, #64]
 164:	a90573fb 	stp	x27, x28, [sp, #80]
 168:	aa0003f9 	mov	x25, x0
 16c:	aa1e03e0 	mov	x0, x30
 170:	d00049b5 	adrp	x21, 0x936000
 174:	d503201f 	nop
 178:	911c22a0 	add	x0, x21, #0x708
 17c:	d28260a2 	mov	x2, #0x1305                	// #4869
 180:	f9400001 	ldr	x1, [x0]
 184:	f90047a1 	str	x1, [x29, #136]
 188:	d2800001 	mov	x1, #0x0                   	// #0
 18c:	f2b7f002 	movk	x2, #0xbf80, lsl #16
 190:	d28260a1 	mov	x1, #0x1305                	// #4869
 194:	52800100 	mov	w0, #0x8                   	// #8
 198:	f2b7f001 	movk	x1, #0xbf80, lsl #16
 19c:	39400042 	ldrb	w2, [x2]
 1a0:	3900003f 	strb	wzr, [x1]
 1a4:	53001c41 	uxtb	w1, w2
 1a8:	b9007fa1 	str	w1, [x29, #124]
 1ac:	d2826181 	mov	x1, #0x130c                	// #4876
 1b0:	71000400 	subs	w0, w0, #0x1
 1b4:	aa0103e2 	mov	x2, x1
 1b8:	f2b7f001 	movk	x1, #0xbf80, lsl #16
 1bc:	f2b7f002 	movk	x2, #0xbf80, lsl #16
 1c0:	b9400021 	ldr	w1, [x1]
 1c4:	32110021 	orr	w1, w1, #0x8000
 1c8:	b9000041 	str	w1, [x2]
 1cc:	54ffff01 	b.ne	0x1ac  // b.any
 1d0:	d2826180 	mov	x0, #0x130c                	// #4876
 1d4:	f2b7f000 	movk	x0, #0xbf80, lsl #16
 1d8:	b9400000 	ldr	w0, [x0]
 1dc:	3707ffa0 	tbnz	w0, #0, 0x1d0
 1e0:	91001320 	add	x0, x25, #0x4
 1e4:	f9003ba0 	str	x0, [x29, #112]
 1e8:	d0003540 	adrp	x0, 0x6aa000
 1ec:	d0003558 	adrp	x24, 0x6aa000
 1f0:	91180000 	add	x0, x0, #0x600
 1f4:	52800017 	mov	w23, #0x0                   	// #0
 1f8:	52800016 	mov	w22, #0x0                   	// #0
 1fc:	91184318 	add	x24, x24, #0x610
