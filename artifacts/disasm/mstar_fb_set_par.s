// mstar_fb_set_par @ 0xffffff80088f20ac
   0:	a9be7bfd 	stp	x29, x30, [sp, #-32]!
   4:	910003fd 	mov	x29, sp
   8:	f9000bf3 	str	x19, [sp, #16]
   c:	aa0003f3 	mov	x19, x0
  10:	aa1e03e0 	mov	x0, x30
  14:	d503201f 	nop
  18:	9101c260 	add	x0, x19, #0x70
  1c:	b9401801 	ldr	w1, [x0, #24]
  20:	7100403f 	cmp	w1, #0x10
  24:	540002c0 	b.eq	0x7c  // b.none
  28:	7100803f 	cmp	w1, #0x20
  2c:	54000280 	b.eq	0x7c  // b.none
  30:	7100043f 	cmp	w1, #0x1
  34:	540001c0 	b.eq	0x6c  // b.none
  38:	52800061 	mov	w1, #0x3                   	// #3
  3c:	52800402 	mov	w2, #0x20                  	// #32
  40:	b9013661 	str	w1, [x19, #308]
  44:	52800101 	mov	w1, #0x8                   	// #8
  48:	b9400803 	ldr	w3, [x0, #8]
  4c:	52800000 	mov	w0, #0x0                   	// #0
  50:	79027262 	strh	w2, [x19, #312]
  54:	1b037c21 	mul	w1, w1, w3
  58:	53037c21 	lsr	w1, w1, #3
  5c:	b9014261 	str	w1, [x19, #320]
  60:	f9400bf3 	ldr	x19, [sp, #16]
  64:	a8c27bfd 	ldp	x29, x30, [sp], #32
  68:	d65f03c0 	ret
  6c:	b901367f 	str	wzr, [x19, #308]
  70:	52800402 	mov	w2, #0x20                  	// #32
  74:	52800101 	mov	w1, #0x8                   	// #8
  78:	17fffff4 	b	0x48
  7c:	52800043 	mov	w3, #0x2                   	// #2
  80:	53037c22 	lsr	w2, w1, #3
  84:	b9013663 	str	w3, [x19, #308]
  88:	52800403 	mov	w3, #0x20                  	// #32
  8c:	1ac20862 	udiv	w2, w3, w2
  90:	17ffffee 	b	0x48
  94:	a9bb7bfd 	stp	x29, x30, [sp, #-80]!
  98:	910003fd 	mov	x29, sp
  9c:	a90153f3 	stp	x19, x20, [sp, #16]
  a0:	a9025bf5 	stp	x21, x22, [sp, #32]
  a4:	f9001bf7 	str	x23, [sp, #48]
  a8:	2a0003f7 	mov	w23, w0
  ac:	aa1e03e0 	mov	x0, x30
  b0:	f90027a5 	str	x5, [x29, #72]
  b4:	2a0103f5 	mov	w21, w1
  b8:	2a0203f4 	mov	w20, w2
  bc:	2a0303f3 	mov	w19, w3
  c0:	2a0403f6 	mov	w22, w4
  c4:	d503201f 	nop
  c8:	f94027a5 	ldr	x5, [x29, #72]
  cc:	b9408ca0 	ldr	w0, [x5, #140]
  d0:	34000140 	cbz	w0, 0xf8
  d4:	52800383 	mov	w3, #0x1c                  	// #28
  d8:	528012e2 	mov	w2, #0x97                  	// #151
  dc:	1b037e73 	mul	w19, w19, w3
  e0:	1b024e93 	madd	w19, w20, w2, w19
  e4:	528009b4 	mov	w20, #0x4d                  	// #77
  e8:	1b144eb3 	madd	w19, w21, w20, w19
  ec:	53087e73 	lsr	w19, w19, #8
  f0:	2a1303f4 	mov	w20, w19
  f4:	2a1303f5 	mov	w21, w19
  f8:	b94134a1 	ldr	w1, [x5, #308]
  fc:	52800000 	mov	w0, #0x0                   	// #0
 100:	51000821 	sub	w1, w1, #0x2
 104:	721e783f 	tst	w1, #0xfffffffd
 108:	54000201 	b.ne	0x148  // b.any
 10c:	71003eff 	cmp	w23, #0xf
 110:	54000268 	b.hi	0x15c  // b.pmore
 114:	b94090a1 	ldr	w1, [x5, #144]
 118:	b9409ca2 	ldr	w2, [x5, #156]
 11c:	b940b4a4 	ldr	w4, [x5, #180]
 120:	1ac122b5 	lsl	w21, w21, w1
 124:	b940a8a3 	ldr	w3, [x5, #168]
 128:	1ac22294 	lsl	w20, w20, w2
 12c:	f941aca5 	ldr	x5, [x5, #856]
 130:	2a1402b4 	orr	w20, w21, w20
 134:	1ac422d6 	lsl	w22, w22, w4
 138:	1ac32273 	lsl	w19, w19, w3
 13c:	2a160294 	orr	w20, w20, w22
 140:	2a130293 	orr	w19, w20, w19
 144:	b83758b3 	str	w19, [x5, w23, uxtw #2]
 148:	a94153f3 	ldp	x19, x20, [sp, #16]
 14c:	a9425bf5 	ldp	x21, x22, [sp, #32]
 150:	f9401bf7 	ldr	x23, [sp, #48]
 154:	a8c57bfd 	ldp	x29, x30, [sp], #80
 158:	d65f03c0 	ret
 15c:	128002a0 	mov	w0, #0xffffffea            	// #-22
 160:	17fffffa 	b	0x148
 164:	a9bf7bfd 	stp	x29, x30, [sp, #-16]!
 168:	910003fd 	mov	x29, sp
 16c:	aa1e03e0 	mov	x0, x30
 170:	d503201f 	nop
 174:	a8c17bfd 	ldp	x29, x30, [sp], #16
 178:	d65f03c0 	ret
 17c:	a9bf7bfd 	stp	x29, x30, [sp, #-16]!
 180:	910003fd 	mov	x29, sp
 184:	aa1e03e0 	mov	x0, x30
 188:	d503201f 	nop
 18c:	a8c17bfd 	ldp	x29, x30, [sp], #16
 190:	d65f03c0 	ret
 194:	a9bf7bfd 	stp	x29, x30, [sp, #-16]!
 198:	910003fd 	mov	x29, sp
 19c:	aa1e03e0 	mov	x0, x30
 1a0:	d503201f 	nop
 1a4:	a8c17bfd 	ldp	x29, x30, [sp], #16
 1a8:	d65f03c0 	ret
 1ac:	a9bd7bfd 	stp	x29, x30, [sp, #-48]!
 1b0:	910003fd 	mov	x29, sp
 1b4:	f9000bf3 	str	x19, [sp, #16]
 1b8:	aa0003f3 	mov	x19, x0
 1bc:	aa1e03e0 	mov	x0, x30
 1c0:	f90017a1 	str	x1, [x29, #40]
 1c4:	d503201f 	nop
 1c8:	b9408660 	ldr	w0, [x19, #132]
 1cc:	f94017a1 	ldr	x1, [x29, #40]
 1d0:	364800e0 	tbz	w0, #9, 0x1ec
 1d4:	32180000 	orr	w0, w0, #0x100
 1d8:	b9008660 	str	w0, [x19, #132]
 1dc:	b9408020 	ldr	w0, [x1, #128]
 1e0:	b9001260 	str	w0, [x19, #16]
 1e4:	b9408420 	ldr	w0, [x1, #132]
 1e8:	b9001660 	str	w0, [x19, #20]
 1ec:	b9400263 	ldr	w3, [x19]
 1f0:	35000063 	cbnz	w3, 0x1fc
 1f4:	b9407023 	ldr	w3, [x1, #112]
 1f8:	b9000263 	str	w3, [x19]
 1fc:	b9400662 	ldr	w2, [x19, #4]
