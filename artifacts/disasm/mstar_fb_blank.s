// mstar_fb_blank @ 0xffffff80088f26d0
   0:	a9be7bfd 	stp	x29, x30, [sp, #-32]!
   4:	910003fd 	mov	x29, sp
   8:	f9000bf3 	str	x19, [sp, #16]
   c:	aa1e03e0 	mov	x0, x30
  10:	d5384113 	mrs	x19, sp_el0
  14:	d503201f 	nop
  18:	911e2273 	add	x19, x19, #0x788
  1c:	aa1303e0 	mov	x0, x19
  20:	97f24f28 	bl	0xffffffffffc93cc0
  24:	aa0003e2 	mov	x2, x0
  28:	b0003041 	adrp	x1, 0x609000
  2c:	aa1303e0 	mov	x0, x19
  30:	913ec021 	add	x1, x1, #0xfb0
  34:	97f24f47 	bl	0xffffffffffc93d50
  38:	6b1f001f 	cmp	w0, wzr
  3c:	128002a1 	mov	w1, #0xffffffea            	// #-22
  40:	f9400bf3 	ldr	x19, [sp, #16]
  44:	1a810000 	csel	w0, w0, w1, eq  // eq = none
  48:	a8c27bfd 	ldp	x29, x30, [sp], #32
  4c:	d65f03c0 	ret
  50:	a9be7bfd 	stp	x29, x30, [sp, #-32]!
  54:	910003fd 	mov	x29, sp
  58:	f9000bf3 	str	x19, [sp, #16]
  5c:	aa0003f3 	mov	x19, x0
  60:	aa1e03e0 	mov	x0, x30
  64:	d503201f 	nop
  68:	b40002f3 	cbz	x19, 0xc4
  6c:	52800002 	mov	w2, #0x0                   	// #0
  70:	52800001 	mov	w1, #0x0                   	// #0
  74:	52800000 	mov	w0, #0x0                   	// #0
  78:	94000169 	bl	0x61c
  7c:	52800000 	mov	w0, #0x0                   	// #0
  80:	94000178 	bl	0x660
  84:	f9405e73 	ldr	x19, [x19, #184]
  88:	90005be0 	adrp	x0, 0xb7c000
  8c:	3917c01f 	strb	wzr, [x0, #1520]
  90:	b4000133 	cbz	x19, 0xb4
  94:	aa1303e0 	mov	x0, x19
  98:	97f39ad3 	bl	0xffffffffffce6be4
  9c:	aa1303e0 	mov	x0, x19
  a0:	97f39f25 	bl	0xffffffffffce7d34
  a4:	52800000 	mov	w0, #0x0                   	// #0
  a8:	f9400bf3 	ldr	x19, [sp, #16]
  ac:	a8c27bfd 	ldp	x29, x30, [sp], #32
  b0:	d65f03c0 	ret
  b4:	52800000 	mov	w0, #0x0                   	// #0
  b8:	f9400bf3 	ldr	x19, [sp, #16]
  bc:	a8c27bfd 	ldp	x29, x30, [sp], #32
  c0:	d65f03c0 	ret
  c4:	f00032c0 	adrp	x0, 0x65b000
  c8:	910a8000 	add	x0, x0, #0x2a0
  cc:	97e3f027 	bl	0xffffffffff8fc168
  d0:	12800300 	mov	w0, #0xffffffe7            	// #-25
  d4:	17fffff5 	b	0xa8
  d8:	a9ba7bfd 	stp	x29, x30, [sp, #-96]!
  dc:	910003fd 	mov	x29, sp
  e0:	a90153f3 	stp	x19, x20, [sp, #16]
  e4:	aa0003f3 	mov	x19, x0
  e8:	aa1e03e0 	mov	x0, x30
  ec:	d503201f 	nop
  f0:	b9401a60 	ldr	w0, [x19, #24]
  f4:	7100041f 	cmp	w0, #0x1
  f8:	54000040 	b.eq	0x100  // b.none
  fc:	53037c00 	lsr	w0, w0, #3
 100:	b0004d21 	adrp	x1, 0x9a5000
 104:	b9401262 	ldr	w2, [x19, #16]
 108:	f9476034 	ldr	x20, [x1, #3776]
 10c:	b2407be1 	mov	x1, #0x7fffffff            	// #2147483647
 110:	eb01029f 	cmp	x20, x1
 114:	b9401661 	ldr	w1, [x19, #20]
 118:	1a9f9294 	csel	w20, w20, wzr, ls  // ls = plast
 11c:	35000042 	cbnz	w2, 0x124
 120:	34000081 	cbz	w1, 0x130
 124:	b9400a63 	ldr	w3, [x19, #8]
 128:	1b030821 	madd	w1, w1, w3, w2
 12c:	1b005034 	madd	w20, w1, w0, w20
 130:	52800001 	mov	w1, #0x0                   	// #0
 134:	52800000 	mov	w0, #0x0                   	// #0
 138:	9400009a 	bl	0x3a0
 13c:	b90057b4 	str	w20, [x29, #84]
 140:	b9400a63 	ldr	w3, [x19, #8]
 144:	910083a2 	add	x2, x29, #0x20
 148:	b90053a3 	str	w3, [x29, #80]
 14c:	528000e3 	mov	w3, #0x7                   	// #7
 150:	b9400265 	ldr	w5, [x19]
 154:	52800001 	mov	w1, #0x0                   	// #0
 158:	b9400664 	ldr	w4, [x19, #4]
 15c:	52800000 	mov	w0, #0x0                   	// #0
 160:	b90033a3 	str	w3, [x29, #48]
 164:	910123a3 	add	x3, x29, #0x48
 168:	790093bf 	strh	wzr, [x29, #72]
 16c:	790097a5 	strh	w5, [x29, #74]
 170:	79009bbf 	strh	wzr, [x29, #76]
 174:	79009fa4 	strh	w4, [x29, #78]
 178:	a9401464 	ldp	x4, x5, [x3]
 17c:	a90217a4 	stp	x4, x5, [x29, #32]
 180:	940000c6 	bl	0x498
 184:	52800000 	mov	w0, #0x0                   	// #0
 188:	94000136 	bl	0x660
 18c:	a94153f3 	ldp	x19, x20, [sp, #16]
 190:	a8c67bfd 	ldp	x29, x30, [sp], #96
 194:	d65f03c0 	ret
 198:	a9bc7bfd 	stp	x29, x30, [sp, #-64]!
 19c:	910003fd 	mov	x29, sp
 1a0:	a90153f3 	stp	x19, x20, [sp, #16]
 1a4:	a9025bf5 	stp	x21, x22, [sp, #32]
 1a8:	aa0003f5 	mov	x21, x0
 1ac:	aa1e03e0 	mov	x0, x30
 1b0:	aa0103f6 	mov	x22, x1
 1b4:	d00046d3 	adrp	x19, 0x8da000
 1b8:	d503201f 	nop
 1bc:	911c2260 	add	x0, x19, #0x708
 1c0:	d5384114 	mrs	x20, sp_el0
 1c4:	911e2294 	add	x20, x20, #0x788
 1c8:	f9400001 	ldr	x1, [x0]
 1cc:	f9001fa1 	str	x1, [x29, #56]
 1d0:	d2800001 	mov	x1, #0x0                   	// #0
 1d4:	aa1403e0 	mov	x0, x20
 1d8:	97f24eba 	bl	0xffffffffffc93cc0
 1dc:	aa0003e2 	mov	x2, x0
 1e0:	b0003041 	adrp	x1, 0x609000
 1e4:	aa1403e0 	mov	x0, x20
 1e8:	913ec021 	add	x1, x1, #0xfb0
 1ec:	97f24ed9 	bl	0xffffffffffc93d50
 1f0:	34000160 	cbz	w0, 0x21c
 1f4:	911c2273 	add	x19, x19, #0x708
 1f8:	52800000 	mov	w0, #0x0                   	// #0
 1fc:	f9401fa1 	ldr	x1, [x29, #56]
