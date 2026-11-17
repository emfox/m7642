// MDrv_GFLIP_GetGwinInfo @ 0xffffff80088ebeb8
   0:	a9bd7bfd 	stp	x29, x30, [sp, #-48]!
   4:	910003fd 	mov	x29, sp
   8:	a90153f3 	stp	x19, x20, [sp, #16]
   c:	53001c13 	uxtb	w19, w0
  10:	aa1e03e0 	mov	x0, x30
  14:	53001c34 	uxtb	w20, w1
  18:	f90017a8 	str	x8, [x29, #40]
  1c:	d503201f 	nop
  20:	93407e82 	sxtw	x2, w20
  24:	93407e61 	sxtw	x1, w19
  28:	d37ef444 	lsl	x4, x2, #2
  2c:	d37ef425 	lsl	x5, x1, #2
  30:	cb020083 	sub	x3, x4, x2
  34:	cb0100a1 	sub	x1, x5, x1
  38:	d37cec21 	lsl	x1, x1, #4
  3c:	f94017a8 	ldr	x8, [x29, #40]
  40:	8b030c22 	add	x2, x1, x3, lsl #3
  44:	90005c01 	adrp	x1, 0xb80000
  48:	9133e021 	add	x1, x1, #0xcf8
  4c:	aa0803e0 	mov	x0, x8
  50:	91002021 	add	x1, x1, #0x8
  54:	8b020021 	add	x1, x1, x2
  58:	a9400c22 	ldp	x2, x3, [x1]
  5c:	f9400821 	ldr	x1, [x1, #16]
  60:	a9000d02 	stp	x2, x3, [x8]
  64:	f9000901 	str	x1, [x8, #16]
  68:	a94153f3 	ldp	x19, x20, [sp, #16]
  6c:	a8c37bfd 	ldp	x29, x30, [sp], #48
  70:	d65f03c0 	ret
  74:	a9bd7bfd 	stp	x29, x30, [sp, #-48]!
  78:	910003fd 	mov	x29, sp
  7c:	a90153f3 	stp	x19, x20, [sp, #16]
  80:	a9025bf5 	stp	x21, x22, [sp, #32]
  84:	90005c16 	adrp	x22, 0xb80000
  88:	aa1e03e0 	mov	x0, x30
  8c:	52800013 	mov	w19, #0x0                   	// #0
  90:	9133e2d6 	add	x22, x22, #0xcf8
  94:	d503201f 	nop
  98:	2a1303f4 	mov	w20, w19
  9c:	910262d5 	add	x21, x22, #0x98
  a0:	38746aa0 	ldrb	w0, [x21, x20]
  a4:	53001c00 	uxtb	w0, w0
  a8:	7100041f 	cmp	w0, #0x1
  ac:	54000120 	b.eq	0xd0  // b.none
  b0:	11000673 	add	w19, w19, #0x1
  b4:	71000e7f 	cmp	w19, #0x3
  b8:	54ffff01 	b.ne	0x98  // b.any
  bc:	52800020 	mov	w0, #0x1                   	// #1
  c0:	a94153f3 	ldp	x19, x20, [sp, #16]
  c4:	a9425bf5 	ldp	x21, x22, [sp, #32]
  c8:	a8c37bfd 	ldp	x29, x30, [sp], #48
  cc:	d65f03c0 	ret
  d0:	2a1303e0 	mov	w0, w19
  d4:	940017b4 	bl	0x5fa4
  d8:	38346abf 	strb	wzr, [x21, x20]
  dc:	17fffff5 	b	0xb0
  e0:	a9b87bfd 	stp	x29, x30, [sp, #-128]!
  e4:	910003fd 	mov	x29, sp
  e8:	a90153f3 	stp	x19, x20, [sp, #16]
  ec:	a9025bf5 	stp	x21, x22, [sp, #32]
  f0:	a90363f7 	stp	x23, x24, [sp, #48]
  f4:	f90023f9 	str	x25, [sp, #64]
  f8:	2a0003f3 	mov	w19, w0
  fc:	aa1e03e0 	mov	x0, x30
 100:	b0004716 	adrp	x22, 0x8e1000
 104:	d503201f 	nop
 108:	911c22c0 	add	x0, x22, #0x708
 10c:	7100167f 	cmp	w19, #0x5
 110:	f9400001 	ldr	x1, [x0]
 114:	f9003fa1 	str	x1, [x29, #120]
 118:	d2800001 	mov	x1, #0x0                   	// #0
 11c:	54000289 	b.ls	0x16c  // b.plast
 120:	b0002521 	adrp	x1, 0x4a5000
 124:	b0003300 	adrp	x0, 0x661000
 128:	2a1303e3 	mov	w3, w19
 12c:	528110a2 	mov	w2, #0x885                 	// #2181
 130:	91152021 	add	x1, x1, #0x548
 134:	91302000 	add	x0, x0, #0xc08
 138:	97e40a12 	bl	0xffffffffff902980
 13c:	911c22c1 	add	x1, x22, #0x708
 140:	52800020 	mov	w0, #0x1                   	// #1
 144:	f9403fa2 	ldr	x2, [x29, #120]
 148:	f9400021 	ldr	x1, [x1]
 14c:	ca010041 	eor	x1, x2, x1
 150:	b5001dc1 	cbnz	x1, 0x508
 154:	a94153f3 	ldp	x19, x20, [sp, #16]
 158:	a9425bf5 	ldp	x21, x22, [sp, #32]
 15c:	a94363f7 	ldp	x23, x24, [sp, #48]
 160:	f94023f9 	ldr	x25, [sp, #64]
 164:	a8c87bfd 	ldp	x29, x30, [sp], #128
 168:	d65f03c0 	ret
 16c:	90002520 	adrp	x0, 0x4a4000
 170:	f0005be2 	adrp	x2, 0xb7f000
 174:	910fc000 	add	x0, x0, #0x3f0
 178:	910143b5 	add	x21, x29, #0x50
 17c:	9133e054 	add	x20, x2, #0xcf8
 180:	78735800 	ldrh	w0, [x0, w19, uxtw #1]
 184:	10000061 	adr	x1, 0x190
 188:	8b20a820 	add	x0, x1, w0, sxth #2
 18c:	d61f0000 	br	x0
 190:	52800001 	mov	w1, #0x0                   	// #0
 194:	aa1503e0 	mov	x0, x21
 198:	f0004d57 	adrp	x23, 0x9ab000
 19c:	3902929f 	strb	wzr, [x20, #164]
 1a0:	97e0e6f6 	bl	0xffffffffff839d78
 1a4:	d2800333 	mov	x19, #0x19                  	// #25
 1a8:	913002e0 	add	x0, x23, #0xc00
 1ac:	aa1503e1 	mov	x1, x21
 1b0:	91018000 	add	x0, x0, #0x60
 1b4:	52800022 	mov	w2, #0x1                   	// #1
 1b8:	aa0003f8 	mov	x24, x0
 1bc:	97e0e83d 	bl	0xffffffffff83a2b0
 1c0:	39429281 	ldrb	w1, [x20, #164]
 1c4:	6b1f003f 	cmp	w1, wzr
 1c8:	1a9f07e1 	cset	w1, ne  // ne = any
 1cc:	35001641 	cbnz	w1, 0x494
 1d0:	b4001633 	cbz	x19, 0x494
 1d4:	b5fffb40 	cbnz	x0, 0x13c
 1d8:	aa1303e0 	mov	x0, x19
 1dc:	940efa6c 	bl	0x3beb8c
 1e0:	aa0003f3 	mov	x19, x0
 1e4:	aa1503e1 	mov	x1, x21
 1e8:	52800022 	mov	w2, #0x1                   	// #1
 1ec:	aa1803e0 	mov	x0, x24
 1f0:	97e0e830 	bl	0xffffffffff83a2b0
 1f4:	39429281 	ldrb	w1, [x20, #164]
 1f8:	6b1f003f 	cmp	w1, wzr
 1fc:	1a9f07e1 	cset	w1, ne  // ne = any
