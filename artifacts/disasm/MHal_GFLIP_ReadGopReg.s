// MHal_GFLIP_ReadGopReg @ 0xffffff80088f0d60
   0:	a9bc7bfd 	stp	x29, x30, [sp, #-64]!
   4:	910003fd 	mov	x29, sp
   8:	a90153f3 	stp	x19, x20, [sp, #16]
   c:	f90013f5 	str	x21, [sp, #32]
  10:	2a0003f3 	mov	w19, w0
  14:	aa1e03e0 	mov	x0, x30
  18:	f9001fa3 	str	x3, [x29, #56]
  1c:	53003c34 	uxth	w20, w1
  20:	53003c55 	uxth	w21, w2
  24:	d503201f 	nop
  28:	71000a7f 	cmp	w19, #0x2
  2c:	f9401fa3 	ldr	x3, [x29, #56]
  30:	54000128 	b.hi	0x54  // b.pmore
  34:	2a1503e2 	mov	w2, w21
  38:	2a1403e1 	mov	w1, w20
  3c:	2a1303e0 	mov	w0, w19
  40:	97ffff9e 	bl	0xfffffffffffffeb8
  44:	f94013f5 	ldr	x21, [sp, #32]
  48:	a94153f3 	ldp	x19, x20, [sp, #16]
  4c:	a8c47bfd 	ldp	x29, x30, [sp], #64
  50:	d65f03c0 	ret
  54:	7900007f 	strh	wzr, [x3]
  58:	a94153f3 	ldp	x19, x20, [sp, #16]
  5c:	f94013f5 	ldr	x21, [sp, #32]
  60:	a8c47bfd 	ldp	x29, x30, [sp], #64
  64:	d65f03c0 	ret
  68:	a9bd7bfd 	stp	x29, x30, [sp, #-48]!
  6c:	910003fd 	mov	x29, sp
  70:	f9000bf3 	str	x19, [sp, #16]
  74:	2a0003f3 	mov	w19, w0
  78:	aa1e03e0 	mov	x0, x30
  7c:	b9002fa1 	str	w1, [x29, #44]
  80:	d503201f 	nop
  84:	7100127f 	cmp	w19, #0x4
  88:	b9402fa1 	ldr	w1, [x29, #44]
  8c:	54000108 	b.hi	0xac  // b.pmore
  90:	90002500 	adrp	x0, 0x4a0000
  94:	91158000 	add	x0, x0, #0x560
  98:	38734800 	ldrb	w0, [x0, w19, uxtw]
  9c:	10000062 	adr	x2, 0xa8
  a0:	8b208840 	add	x0, x2, w0, sxtb #2
  a4:	d61f0000 	br	x0
  a8:	12000021 	and	w1, w1, #0x1
  ac:	f9400bf3 	ldr	x19, [sp, #16]
  b0:	2a0103e0 	mov	w0, w1
  b4:	a8c37bfd 	ldp	x29, x30, [sp], #48
  b8:	d65f03c0 	ret
  bc:	52800001 	mov	w1, #0x0                   	// #0
  c0:	f9400bf3 	ldr	x19, [sp, #16]
  c4:	2a0103e0 	mov	w0, w1
  c8:	a8c37bfd 	ldp	x29, x30, [sp], #48
  cc:	d65f03c0 	ret
  d0:	a9be7bfd 	stp	x29, x30, [sp, #-32]!
  d4:	910003fd 	mov	x29, sp
  d8:	a90153f3 	stp	x19, x20, [sp, #16]
  dc:	53003c14 	uxth	w20, w0
  e0:	aa1e03e0 	mov	x0, x30
  e4:	53003c33 	uxth	w19, w1
  e8:	d503201f 	nop
  ec:	6b13029f 	cmp	w20, w19
  f0:	4b130280 	sub	w0, w20, w19
  f4:	54000122 	b.cs	0x118  // b.hs, b.nlast
  f8:	4b140273 	sub	w19, w19, w20
  fc:	528fffe2 	mov	w2, #0x7fff                	// #32767
 100:	11404001 	add	w1, w0, #0x10, lsl #12
 104:	6b02027f 	cmp	w19, w2
 108:	1a80c020 	csel	w0, w1, w0, gt
 10c:	a94153f3 	ldp	x19, x20, [sp, #16]
 110:	a8c27bfd 	ldp	x29, x30, [sp], #32
 114:	d65f03c0 	ret
 118:	528fffe1 	mov	w1, #0x7fff                	// #32767
 11c:	6b01001f 	cmp	w0, w1
 120:	54ffff6d 	b.le	0x10c
 124:	11404262 	add	w2, w19, #0x10, lsl #12
 128:	4b020280 	sub	w0, w20, w2
 12c:	a94153f3 	ldp	x19, x20, [sp, #16]
 130:	a8c27bfd 	ldp	x29, x30, [sp], #32
 134:	d65f03c0 	ret
 138:	a9bd7bfd 	stp	x29, x30, [sp, #-48]!
 13c:	910003fd 	mov	x29, sp
 140:	a90153f3 	stp	x19, x20, [sp, #16]
 144:	2a0003f4 	mov	w20, w0
 148:	aa1e03e0 	mov	x0, x30
 14c:	900046f3 	adrp	x19, 0x8dc000
 150:	d503201f 	nop
 154:	911c2260 	add	x0, x19, #0x708
 158:	71000a9f 	cmp	w20, #0x2
 15c:	f9400001 	ldr	x1, [x0]
 160:	f90017a1 	str	x1, [x29, #40]
 164:	d2800001 	mov	x1, #0x0                   	// #0
 168:	52800000 	mov	w0, #0x0                   	// #0
 16c:	54000129 	b.ls	0x190  // b.plast
 170:	911c2273 	add	x19, x19, #0x708
 174:	f94017a1 	ldr	x1, [x29, #40]
 178:	f9400261 	ldr	x1, [x19]
 17c:	ca010021 	eor	x1, x1, x1
 180:	b5000161 	cbnz	x1, 0x1ac
 184:	a94153f3 	ldp	x19, x20, [sp, #16]
 188:	a8c37bfd 	ldp	x29, x30, [sp], #48
 18c:	d65f03c0 	ret
 190:	2a1403e0 	mov	w0, w20
 194:	91009ba3 	add	x3, x29, #0x26
 198:	52800022 	mov	w2, #0x1                   	// #1
 19c:	97ffff47 	bl	0xfffffffffffffeb8
 1a0:	79404fa1 	ldrh	w1, [x29, #38]
 1a4:	12000820 	and	w0, w1, #0x7
 1a8:	17fffff2 	b	0x170
 1ac:	97df6e28 	bl	0xffffffffff7dba4c
 1b0:	a9be7bfd 	stp	x29, x30, [sp, #-32]!
 1b4:	910003fd 	mov	x29, sp
 1b8:	a90153f3 	stp	x19, x20, [sp, #16]
 1bc:	2a0003f4 	mov	w20, w0
 1c0:	aa1e03e0 	mov	x0, x30
 1c4:	53003c33 	uxth	w19, w1
 1c8:	d503201f 	nop
 1cc:	7100067f 	cmp	w19, #0x1
 1d0:	54000380 	b.eq	0x240  // b.none
 1d4:	34000253 	cbz	w19, 0x21c
 1d8:	71000a7f 	cmp	w19, #0x2
 1dc:	540000c0 	b.eq	0x1f4  // b.none
 1e0:	52800004 	mov	w4, #0x0                   	// #0
 1e4:	2a0403e0 	mov	w0, w4
 1e8:	a94153f3 	ldp	x19, x20, [sp, #16]
 1ec:	a8c27bfd 	ldp	x29, x30, [sp], #32
 1f0:	d65f03c0 	ret
 1f4:	7100129f 	cmp	w20, #0x4
 1f8:	52800004 	mov	w4, #0x0                   	// #0
 1fc:	54ffff48 	b.hi	0x1e4  // b.pmore
