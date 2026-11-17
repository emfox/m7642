// MDrv_SYS_SetGFXGOPIndex @ 0xffffff8008898280
   0:	a9be7bfd 	stp	x29, x30, [sp, #-32]!
   4:	910003fd 	mov	x29, sp
   8:	f9000bf3 	str	x19, [sp, #16]
   c:	aa0003f3 	mov	x19, x0
  10:	aa1e03e0 	mov	x0, x30
  14:	d503201f 	nop
  18:	b0005cc1 	adrp	x1, 0xb99000
  1c:	b9065033 	str	w19, [x1, #1616]
  20:	f9400bf3 	ldr	x19, [sp, #16]
  24:	a8c27bfd 	ldp	x29, x30, [sp], #32
  28:	d65f03c0 	ret
  2c:	a9be7bfd 	stp	x29, x30, [sp, #-32]!
  30:	910003fd 	mov	x29, sp
  34:	f9000bf3 	str	x19, [sp, #16]
  38:	aa0003f3 	mov	x19, x0
  3c:	aa1e03e0 	mov	x0, x30
  40:	d503201f 	nop
  44:	aa1303e2 	mov	x2, x19
  48:	d5384100 	mrs	x0, sp_el0
  4c:	f9400401 	ldr	x1, [x0, #8]
  50:	b1001042 	adds	x2, x2, #0x4
  54:	9a8183e1 	csel	x1, xzr, x1, hi  // hi = pmore
  58:	da9f3042 	csinv	x2, x2, xzr, cc  // cc = lo, ul, last
  5c:	fa01005f 	sbcs	xzr, x2, x1
  60:	9a9f87e2 	cset	x2, ls  // ls = plast
  64:	b50000e2 	cbnz	x2, 0x80
  68:	90003540 	adrp	x0, 0x6a8000
  6c:	91132000 	add	x0, x0, #0x4c8
  70:	97e55952 	bl	0xffffffffff9565b8
  74:	f9400bf3 	ldr	x19, [sp, #16]
  78:	a8c27bfd 	ldp	x29, x30, [sp], #32
  7c:	d65f03c0 	ret
  80:	b0005cc1 	adrp	x1, 0xb99000
  84:	d2800082 	mov	x2, #0x4                   	// #4
  88:	91108021 	add	x1, x1, #0x420
  8c:	aa1303e0 	mov	x0, x19
  90:	9108c021 	add	x1, x1, #0x230
  94:	97f3b4fb 	bl	0xffffffffffced480
  98:	b5fffe80 	cbnz	x0, 0x68
  9c:	f9400bf3 	ldr	x19, [sp, #16]
  a0:	a8c27bfd 	ldp	x29, x30, [sp], #32
  a4:	d65f03c0 	ret
  a8:	a9be7bfd 	stp	x29, x30, [sp, #-32]!
  ac:	910003fd 	mov	x29, sp
  b0:	f9000bf3 	str	x19, [sp, #16]
  b4:	aa0003f3 	mov	x19, x0
  b8:	aa1e03e0 	mov	x0, x30
  bc:	d503201f 	nop
  c0:	b0005cc1 	adrp	x1, 0xb99000
  c4:	b9065433 	str	w19, [x1, #1620]
  c8:	f9400bf3 	ldr	x19, [sp, #16]
  cc:	a8c27bfd 	ldp	x29, x30, [sp], #32
  d0:	d65f03c0 	ret
  d4:	a9bf7bfd 	stp	x29, x30, [sp, #-16]!
  d8:	910003fd 	mov	x29, sp
  dc:	aa1e03e0 	mov	x0, x30
  e0:	d503201f 	nop
  e4:	b0005cc0 	adrp	x0, 0xb99000
  e8:	a8c17bfd 	ldp	x29, x30, [sp], #16
  ec:	b9465400 	ldr	w0, [x0, #1620]
  f0:	d65f03c0 	ret
  f4:	a9be7bfd 	stp	x29, x30, [sp, #-32]!
  f8:	910003fd 	mov	x29, sp
  fc:	f9000bf3 	str	x19, [sp, #16]
 100:	aa0003f3 	mov	x19, x0
 104:	aa1e03e0 	mov	x0, x30
 108:	d503201f 	nop
 10c:	aa1303e2 	mov	x2, x19
 110:	d5384100 	mrs	x0, sp_el0
 114:	f9400401 	ldr	x1, [x0, #8]
 118:	b1001042 	adds	x2, x2, #0x4
 11c:	9a8183e1 	csel	x1, xzr, x1, hi  // hi = pmore
 120:	da9f3042 	csinv	x2, x2, xzr, cc  // cc = lo, ul, last
 124:	fa01005f 	sbcs	xzr, x2, x1
 128:	9a9f87e2 	cset	x2, ls  // ls = plast
 12c:	b50000e2 	cbnz	x2, 0x148
 130:	90003540 	adrp	x0, 0x6a8000
 134:	91132000 	add	x0, x0, #0x4c8
 138:	97e55920 	bl	0xffffffffff9565b8
 13c:	f9400bf3 	ldr	x19, [sp, #16]
 140:	a8c27bfd 	ldp	x29, x30, [sp], #32
 144:	d65f03c0 	ret
 148:	b0005cc1 	adrp	x1, 0xb99000
 14c:	d2800082 	mov	x2, #0x4                   	// #4
 150:	91108021 	add	x1, x1, #0x420
 154:	aa1303e0 	mov	x0, x19
 158:	9108d021 	add	x1, x1, #0x234
 15c:	97f3b4c9 	bl	0xffffffffffced480
 160:	b5fffe80 	cbnz	x0, 0x130
 164:	f9400bf3 	ldr	x19, [sp, #16]
 168:	a8c27bfd 	ldp	x29, x30, [sp], #32
 16c:	d65f03c0 	ret
 170:	a9be7bfd 	stp	x29, x30, [sp, #-32]!
 174:	910003fd 	mov	x29, sp
 178:	f9000bf3 	str	x19, [sp, #16]
 17c:	aa0003f3 	mov	x19, x0
 180:	aa1e03e0 	mov	x0, x30
 184:	d503201f 	nop
 188:	b0005cc1 	adrp	x1, 0xb99000
 18c:	b9065833 	str	w19, [x1, #1624]
 190:	f9400bf3 	ldr	x19, [sp, #16]
 194:	a8c27bfd 	ldp	x29, x30, [sp], #32
 198:	d65f03c0 	ret
 19c:	a9be7bfd 	stp	x29, x30, [sp, #-32]!
 1a0:	910003fd 	mov	x29, sp
 1a4:	f9000bf3 	str	x19, [sp, #16]
 1a8:	aa0003f3 	mov	x19, x0
 1ac:	aa1e03e0 	mov	x0, x30
 1b0:	d503201f 	nop
 1b4:	aa1303e2 	mov	x2, x19
 1b8:	d5384100 	mrs	x0, sp_el0
 1bc:	f9400401 	ldr	x1, [x0, #8]
 1c0:	b1001042 	adds	x2, x2, #0x4
 1c4:	9a8183e1 	csel	x1, xzr, x1, hi  // hi = pmore
 1c8:	da9f3042 	csinv	x2, x2, xzr, cc  // cc = lo, ul, last
 1cc:	fa01005f 	sbcs	xzr, x2, x1
 1d0:	9a9f87e2 	cset	x2, ls  // ls = plast
 1d4:	b50000e2 	cbnz	x2, 0x1f0
 1d8:	90003540 	adrp	x0, 0x6a8000
 1dc:	91132000 	add	x0, x0, #0x4c8
 1e0:	97e558f6 	bl	0xffffffffff9565b8
 1e4:	f9400bf3 	ldr	x19, [sp, #16]
 1e8:	a8c27bfd 	ldp	x29, x30, [sp], #32
 1ec:	d65f03c0 	ret
 1f0:	b0005cc1 	adrp	x1, 0xb99000
 1f4:	d2800082 	mov	x2, #0x4                   	// #4
 1f8:	91108021 	add	x1, x1, #0x420
 1fc:	aa1303e0 	mov	x0, x19
