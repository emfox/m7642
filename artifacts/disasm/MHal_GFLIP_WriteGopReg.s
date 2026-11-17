// MHal_GFLIP_WriteGopReg @ 0xffffff80088f0cfc
   0:	a9bc7bfd 	stp	x29, x30, [sp, #-64]!
   4:	910003fd 	mov	x29, sp
   8:	a90153f3 	stp	x19, x20, [sp, #16]
   c:	a9025bf5 	stp	x21, x22, [sp, #32]
  10:	f9001bf7 	str	x23, [sp, #48]
  14:	2a0003f3 	mov	w19, w0
  18:	aa1e03e0 	mov	x0, x30
  1c:	53003c34 	uxth	w20, w1
  20:	53003c55 	uxth	w21, w2
  24:	53003c76 	uxth	w22, w3
  28:	53003c97 	uxth	w23, w4
  2c:	d503201f 	nop
  30:	71000a7f 	cmp	w19, #0x2
  34:	540000e8 	b.hi	0x50  // b.pmore
  38:	2a1703e4 	mov	w4, w23
  3c:	2a1603e3 	mov	w3, w22
  40:	2a1503e2 	mov	w2, w21
  44:	2a1403e1 	mov	w1, w20
  48:	2a1303e0 	mov	w0, w19
  4c:	97ffff79 	bl	0xfffffffffffffe30
  50:	a94153f3 	ldp	x19, x20, [sp, #16]
  54:	a9425bf5 	ldp	x21, x22, [sp, #32]
  58:	f9401bf7 	ldr	x23, [sp, #48]
  5c:	a8c47bfd 	ldp	x29, x30, [sp], #64
  60:	d65f03c0 	ret
  64:	a9bc7bfd 	stp	x29, x30, [sp, #-64]!
  68:	910003fd 	mov	x29, sp
  6c:	a90153f3 	stp	x19, x20, [sp, #16]
  70:	f90013f5 	str	x21, [sp, #32]
  74:	2a0003f3 	mov	w19, w0
  78:	aa1e03e0 	mov	x0, x30
  7c:	f9001fa3 	str	x3, [x29, #56]
  80:	53003c34 	uxth	w20, w1
  84:	53003c55 	uxth	w21, w2
  88:	d503201f 	nop
  8c:	71000a7f 	cmp	w19, #0x2
  90:	f9401fa3 	ldr	x3, [x29, #56]
  94:	54000128 	b.hi	0xb8  // b.pmore
  98:	2a1503e2 	mov	w2, w21
  9c:	2a1403e1 	mov	w1, w20
  a0:	2a1303e0 	mov	w0, w19
  a4:	97ffff9e 	bl	0xffffffffffffff1c
  a8:	f94013f5 	ldr	x21, [sp, #32]
  ac:	a94153f3 	ldp	x19, x20, [sp, #16]
  b0:	a8c47bfd 	ldp	x29, x30, [sp], #64
  b4:	d65f03c0 	ret
  b8:	7900007f 	strh	wzr, [x3]
  bc:	a94153f3 	ldp	x19, x20, [sp, #16]
  c0:	f94013f5 	ldr	x21, [sp, #32]
  c4:	a8c47bfd 	ldp	x29, x30, [sp], #64
  c8:	d65f03c0 	ret
  cc:	a9bd7bfd 	stp	x29, x30, [sp, #-48]!
  d0:	910003fd 	mov	x29, sp
  d4:	f9000bf3 	str	x19, [sp, #16]
  d8:	2a0003f3 	mov	w19, w0
  dc:	aa1e03e0 	mov	x0, x30
  e0:	b9002fa1 	str	w1, [x29, #44]
  e4:	d503201f 	nop
  e8:	7100127f 	cmp	w19, #0x4
  ec:	b9402fa1 	ldr	w1, [x29, #44]
  f0:	54000108 	b.hi	0x110  // b.pmore
  f4:	90002500 	adrp	x0, 0x4a0000
  f8:	91158000 	add	x0, x0, #0x560
  fc:	38734800 	ldrb	w0, [x0, w19, uxtw]
 100:	10000062 	adr	x2, 0x10c
 104:	8b208840 	add	x0, x2, w0, sxtb #2
 108:	d61f0000 	br	x0
 10c:	12000021 	and	w1, w1, #0x1
 110:	f9400bf3 	ldr	x19, [sp, #16]
 114:	2a0103e0 	mov	w0, w1
 118:	a8c37bfd 	ldp	x29, x30, [sp], #48
 11c:	d65f03c0 	ret
 120:	52800001 	mov	w1, #0x0                   	// #0
 124:	f9400bf3 	ldr	x19, [sp, #16]
 128:	2a0103e0 	mov	w0, w1
 12c:	a8c37bfd 	ldp	x29, x30, [sp], #48
 130:	d65f03c0 	ret
 134:	a9be7bfd 	stp	x29, x30, [sp, #-32]!
 138:	910003fd 	mov	x29, sp
 13c:	a90153f3 	stp	x19, x20, [sp, #16]
 140:	53003c14 	uxth	w20, w0
 144:	aa1e03e0 	mov	x0, x30
 148:	53003c33 	uxth	w19, w1
 14c:	d503201f 	nop
 150:	6b13029f 	cmp	w20, w19
 154:	4b130280 	sub	w0, w20, w19
 158:	54000122 	b.cs	0x17c  // b.hs, b.nlast
 15c:	4b140273 	sub	w19, w19, w20
 160:	528fffe2 	mov	w2, #0x7fff                	// #32767
 164:	11404001 	add	w1, w0, #0x10, lsl #12
 168:	6b02027f 	cmp	w19, w2
 16c:	1a80c020 	csel	w0, w1, w0, gt
 170:	a94153f3 	ldp	x19, x20, [sp, #16]
 174:	a8c27bfd 	ldp	x29, x30, [sp], #32
 178:	d65f03c0 	ret
 17c:	528fffe1 	mov	w1, #0x7fff                	// #32767
 180:	6b01001f 	cmp	w0, w1
 184:	54ffff6d 	b.le	0x170
 188:	11404262 	add	w2, w19, #0x10, lsl #12
 18c:	4b020280 	sub	w0, w20, w2
 190:	a94153f3 	ldp	x19, x20, [sp, #16]
 194:	a8c27bfd 	ldp	x29, x30, [sp], #32
 198:	d65f03c0 	ret
 19c:	a9bd7bfd 	stp	x29, x30, [sp, #-48]!
 1a0:	910003fd 	mov	x29, sp
 1a4:	a90153f3 	stp	x19, x20, [sp, #16]
 1a8:	2a0003f4 	mov	w20, w0
 1ac:	aa1e03e0 	mov	x0, x30
 1b0:	900046f3 	adrp	x19, 0x8dc000
 1b4:	d503201f 	nop
 1b8:	911c2260 	add	x0, x19, #0x708
 1bc:	71000a9f 	cmp	w20, #0x2
 1c0:	f9400001 	ldr	x1, [x0]
 1c4:	f90017a1 	str	x1, [x29, #40]
 1c8:	d2800001 	mov	x1, #0x0                   	// #0
 1cc:	52800000 	mov	w0, #0x0                   	// #0
 1d0:	54000129 	b.ls	0x1f4  // b.plast
 1d4:	911c2273 	add	x19, x19, #0x708
 1d8:	f94017a1 	ldr	x1, [x29, #40]
 1dc:	f9400261 	ldr	x1, [x19]
 1e0:	ca010021 	eor	x1, x1, x1
 1e4:	b5000161 	cbnz	x1, 0x210
 1e8:	a94153f3 	ldp	x19, x20, [sp, #16]
 1ec:	a8c37bfd 	ldp	x29, x30, [sp], #48
 1f0:	d65f03c0 	ret
 1f4:	2a1403e0 	mov	w0, w20
 1f8:	91009ba3 	add	x3, x29, #0x26
 1fc:	52800022 	mov	w2, #0x1                   	// #1
