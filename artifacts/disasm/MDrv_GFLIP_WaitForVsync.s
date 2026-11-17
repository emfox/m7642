// MDrv_GFLIP_WaitForVsync @ 0xffffff80088ebf98
   0:	a9b87bfd 	stp	x29, x30, [sp, #-128]!
   4:	910003fd 	mov	x29, sp
   8:	a90153f3 	stp	x19, x20, [sp, #16]
   c:	a9025bf5 	stp	x21, x22, [sp, #32]
  10:	a90363f7 	stp	x23, x24, [sp, #48]
  14:	f90023f9 	str	x25, [sp, #64]
  18:	2a0003f3 	mov	w19, w0
  1c:	aa1e03e0 	mov	x0, x30
  20:	b0004716 	adrp	x22, 0x8e1000
  24:	d503201f 	nop
  28:	911c22c0 	add	x0, x22, #0x708
  2c:	7100167f 	cmp	w19, #0x5
  30:	f9400001 	ldr	x1, [x0]
  34:	f9003fa1 	str	x1, [x29, #120]
  38:	d2800001 	mov	x1, #0x0                   	// #0
  3c:	54000289 	b.ls	0x8c  // b.plast
  40:	b0002521 	adrp	x1, 0x4a5000
  44:	b0003300 	adrp	x0, 0x661000
  48:	2a1303e3 	mov	w3, w19
  4c:	528110a2 	mov	w2, #0x885                 	// #2181
  50:	91152021 	add	x1, x1, #0x548
  54:	91302000 	add	x0, x0, #0xc08
  58:	97e40a12 	bl	0xffffffffff9028a0
  5c:	911c22c1 	add	x1, x22, #0x708
  60:	52800020 	mov	w0, #0x1                   	// #1
  64:	f9403fa2 	ldr	x2, [x29, #120]
  68:	f9400021 	ldr	x1, [x1]
  6c:	ca010041 	eor	x1, x2, x1
  70:	b5001dc1 	cbnz	x1, 0x428
  74:	a94153f3 	ldp	x19, x20, [sp, #16]
  78:	a9425bf5 	ldp	x21, x22, [sp, #32]
  7c:	a94363f7 	ldp	x23, x24, [sp, #48]
  80:	f94023f9 	ldr	x25, [sp, #64]
  84:	a8c87bfd 	ldp	x29, x30, [sp], #128
  88:	d65f03c0 	ret
  8c:	90002520 	adrp	x0, 0x4a4000
  90:	f0005be2 	adrp	x2, 0xb7f000
  94:	910fc000 	add	x0, x0, #0x3f0
  98:	910143b5 	add	x21, x29, #0x50
  9c:	9133e054 	add	x20, x2, #0xcf8
  a0:	78735800 	ldrh	w0, [x0, w19, uxtw #1]
  a4:	10000061 	adr	x1, 0xb0
  a8:	8b20a820 	add	x0, x1, w0, sxth #2
  ac:	d61f0000 	br	x0
  b0:	52800001 	mov	w1, #0x0                   	// #0
  b4:	aa1503e0 	mov	x0, x21
  b8:	f0004d57 	adrp	x23, 0x9ab000
  bc:	3902929f 	strb	wzr, [x20, #164]
  c0:	97e0e6f6 	bl	0xffffffffff839c98
  c4:	d2800333 	mov	x19, #0x19                  	// #25
  c8:	913002e0 	add	x0, x23, #0xc00
  cc:	aa1503e1 	mov	x1, x21
  d0:	91018000 	add	x0, x0, #0x60
  d4:	52800022 	mov	w2, #0x1                   	// #1
  d8:	aa0003f8 	mov	x24, x0
  dc:	97e0e83d 	bl	0xffffffffff83a1d0
  e0:	39429281 	ldrb	w1, [x20, #164]
  e4:	6b1f003f 	cmp	w1, wzr
  e8:	1a9f07e1 	cset	w1, ne  // ne = any
  ec:	35001641 	cbnz	w1, 0x3b4
  f0:	b4001633 	cbz	x19, 0x3b4
  f4:	b5fffb40 	cbnz	x0, 0x5c
  f8:	aa1303e0 	mov	x0, x19
  fc:	940efa6c 	bl	0x3beaac
 100:	aa0003f3 	mov	x19, x0
 104:	aa1503e1 	mov	x1, x21
 108:	52800022 	mov	w2, #0x1                   	// #1
 10c:	aa1803e0 	mov	x0, x24
 110:	97e0e830 	bl	0xffffffffff83a1d0
 114:	39429281 	ldrb	w1, [x20, #164]
 118:	6b1f003f 	cmp	w1, wzr
 11c:	1a9f07e1 	cset	w1, ne  // ne = any
 120:	b5fffe73 	cbnz	x19, 0xec
 124:	6b1f003f 	cmp	w1, wzr
 128:	9a9f0673 	csinc	x19, x19, xzr, eq  // eq = none
 12c:	17fffff0 	b	0xec
 130:	52800001 	mov	w1, #0x0                   	// #0
 134:	aa1503e0 	mov	x0, x21
 138:	f0004d57 	adrp	x23, 0x9ab000
 13c:	3902969f 	strb	wzr, [x20, #165]
 140:	97e0e6d6 	bl	0xffffffffff839c98
 144:	d2800333 	mov	x19, #0x19                  	// #25
 148:	913002e0 	add	x0, x23, #0xc00
 14c:	aa1503e1 	mov	x1, x21
 150:	9101e000 	add	x0, x0, #0x78
 154:	52800022 	mov	w2, #0x1                   	// #1
 158:	aa0003f8 	mov	x24, x0
 15c:	97e0e81d 	bl	0xffffffffff83a1d0
 160:	39429681 	ldrb	w1, [x20, #165]
 164:	6b1f003f 	cmp	w1, wzr
 168:	1a9f07e1 	cset	w1, ne  // ne = any
 16c:	35001381 	cbnz	w1, 0x3dc
 170:	b4001373 	cbz	x19, 0x3dc
 174:	b5fff740 	cbnz	x0, 0x5c
 178:	aa1303e0 	mov	x0, x19
 17c:	940efa4c 	bl	0x3beaac
 180:	aa0003f3 	mov	x19, x0
 184:	aa1503e1 	mov	x1, x21
 188:	52800022 	mov	w2, #0x1                   	// #1
 18c:	aa1803e0 	mov	x0, x24
 190:	97e0e810 	bl	0xffffffffff83a1d0
 194:	39429681 	ldrb	w1, [x20, #165]
 198:	6b1f003f 	cmp	w1, wzr
 19c:	1a9f07e1 	cset	w1, ne  // ne = any
 1a0:	b5fffe73 	cbnz	x19, 0x16c
 1a4:	6b1f003f 	cmp	w1, wzr
 1a8:	9a9f0673 	csinc	x19, x19, xzr, eq  // eq = none
 1ac:	17fffff0 	b	0x16c
 1b0:	52800001 	mov	w1, #0x0                   	// #0
 1b4:	aa1503e0 	mov	x0, x21
 1b8:	f0004d57 	adrp	x23, 0x9ab000
 1bc:	3902829f 	strb	wzr, [x20, #160]
 1c0:	913002f8 	add	x24, x23, #0xc00
 1c4:	97e0e6b5 	bl	0xffffffffff839c98
 1c8:	aa1503e1 	mov	x1, x21
 1cc:	aa1803e0 	mov	x0, x24
 1d0:	52800022 	mov	w2, #0x1                   	// #1
 1d4:	aa1803f9 	mov	x25, x24
 1d8:	d2800333 	mov	x19, #0x19                  	// #25
 1dc:	aa1403f8 	mov	x24, x20
 1e0:	97e0e7fc 	bl	0xffffffffff83a1d0
 1e4:	39428281 	ldrb	w1, [x20, #160]
 1e8:	6b1f003f 	cmp	w1, wzr
 1ec:	1a9f07e1 	cset	w1, ne  // ne = any
 1f0:	350010a1 	cbnz	w1, 0x404
 1f4:	b4001093 	cbz	x19, 0x404
 1f8:	b5fff320 	cbnz	x0, 0x5c
 1fc:	aa1303e0 	mov	x0, x19
