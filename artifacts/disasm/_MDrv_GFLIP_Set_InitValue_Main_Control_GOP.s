// _MDrv_GFLIP_Set_InitValue_Main_Control_GOP @ 0xffffff80088efaf8
   0:	a9be7bfd 	stp	x29, x30, [sp, #-32]!
   4:	910003fd 	mov	x29, sp
   8:	f9000bf3 	str	x19, [sp, #16]
   c:	aa0003f3 	mov	x19, x0
  10:	aa1e03e0 	mov	x0, x30
  14:	d503201f 	nop
  18:	12800003 	mov	w3, #0xffffffff            	// #-1
  1c:	52800020 	mov	w0, #0x1                   	// #1
  20:	5280006b 	mov	w11, #0x3                   	// #3
  24:	39002660 	strb	w0, [x19, #9]
  28:	39002e60 	strb	w0, [x19, #11]
  2c:	528fa00a 	mov	w10, #0x7d00                	// #32000
  30:	39001e6b 	strb	w11, [x19, #7]
  34:	52875309 	mov	w9, #0x3a98                	// #15000
  38:	39003260 	strb	w0, [x19, #12]
  3c:	5283a988 	mov	w8, #0x1d4c                	// #7500
  40:	39001a63 	strb	w3, [x19, #6]
  44:	528808e7 	mov	w7, #0x4047                	// #16455
  48:	39003660 	strb	w0, [x19, #13]
  4c:	528ea606 	mov	w6, #0x7530                	// #30000
  50:	79001e6a 	strh	w10, [x19, #14]
  54:	52817705 	mov	w5, #0xbb8                 	// #3000
  58:	79002269 	strh	w9, [x19, #16]
  5c:	5287a264 	mov	w4, #0x3d13                	// #15635
  60:	79002668 	strh	w8, [x19, #18]
  64:	52880843 	mov	w3, #0x4042                	// #16450
  68:	79002a67 	strh	w7, [x19, #20]
  6c:	528000a2 	mov	w2, #0x5                   	// #5
  70:	79002e66 	strh	w6, [x19, #22]
  74:	79003265 	strh	w5, [x19, #24]
  78:	79003664 	strh	w4, [x19, #26]
  7c:	79003a63 	strh	w3, [x19, #28]
  80:	39007a62 	strb	w2, [x19, #30]
  84:	39007e6b 	strb	w11, [x19, #31]
  88:	39008660 	strb	w0, [x19, #33]
  8c:	39008e60 	strb	w0, [x19, #35]
  90:	39009260 	strb	w0, [x19, #36]
  94:	39009660 	strb	w0, [x19, #37]
  98:	79004e6a 	strh	w10, [x19, #38]
  9c:	79005269 	strh	w9, [x19, #40]
  a0:	79005668 	strh	w8, [x19, #42]
  a4:	79005a67 	strh	w7, [x19, #44]
  a8:	79005e66 	strh	w6, [x19, #46]
  ac:	79006265 	strh	w5, [x19, #48]
  b0:	79006664 	strh	w4, [x19, #50]
  b4:	79006a63 	strh	w3, [x19, #52]
  b8:	3900227f 	strb	wzr, [x19, #8]
  bc:	39002a7f 	strb	wzr, [x19, #10]
  c0:	3900827f 	strb	wzr, [x19, #32]
  c4:	39008a7f 	strb	wzr, [x19, #34]
  c8:	f9400bf3 	ldr	x19, [sp, #16]
  cc:	a8c27bfd 	ldp	x29, x30, [sp], #32
  d0:	d65f03c0 	ret
  d4:	a9be7bfd 	stp	x29, x30, [sp, #-32]!
  d8:	910003fd 	mov	x29, sp
  dc:	f9000bf3 	str	x19, [sp, #16]
  e0:	aa0003f3 	mov	x19, x0
  e4:	aa1e03e0 	mov	x0, x30
  e8:	d503201f 	nop
  ec:	52808120 	mov	w0, #0x409                 	// #1033
  f0:	b40002f3 	cbz	x19, 0x14c
  f4:	52800640 	mov	w0, #0x32                  	// #50
  f8:	52808001 	mov	w1, #0x400                 	// #1024
  fc:	a9017e7f 	stp	xzr, xzr, [x19, #16]
 100:	a9027e7f 	stp	xzr, xzr, [x19, #32]
 104:	79000e60 	strh	w0, [x19, #6]
 108:	52801000 	mov	w0, #0x80                  	// #128
 10c:	52808002 	mov	w2, #0x400                 	// #1024
 110:	79001260 	strh	w0, [x19, #8]
 114:	79001661 	strh	w1, [x19, #10]
 118:	52800000 	mov	w0, #0x0                   	// #0
 11c:	79006e61 	strh	w1, [x19, #54]
 120:	79007261 	strh	w1, [x19, #56]
 124:	79007661 	strh	w1, [x19, #58]
 128:	52800021 	mov	w1, #0x1                   	// #1
 12c:	3900327f 	strb	wzr, [x19, #12]
 130:	b9001262 	str	w2, [x19, #16]
 134:	b9002262 	str	w2, [x19, #32]
 138:	b9003262 	str	w2, [x19, #48]
 13c:	79006a62 	strh	w2, [x19, #52]
 140:	3900f261 	strb	w1, [x19, #60]
 144:	3900f67f 	strb	wzr, [x19, #61]
 148:	3900fa7f 	strb	wzr, [x19, #62]
 14c:	f9400bf3 	ldr	x19, [sp, #16]
 150:	a8c27bfd 	ldp	x29, x30, [sp], #32
 154:	d65f03c0 	ret
 158:	a9be7bfd 	stp	x29, x30, [sp, #-32]!
 15c:	910003fd 	mov	x29, sp
 160:	f9000bf3 	str	x19, [sp, #16]
 164:	aa0003f3 	mov	x19, x0
 168:	aa1e03e0 	mov	x0, x30
 16c:	d503201f 	nop
 170:	528fa000 	mov	w0, #0x7d00                	// #32000
 174:	79001a60 	strh	w0, [x19, #12]
 178:	52875300 	mov	w0, #0x3a98                	// #15000
 17c:	79001e60 	strh	w0, [x19, #14]
 180:	5283a980 	mov	w0, #0x1d4c                	// #7500
 184:	79002260 	strh	w0, [x19, #16]
 188:	528808e0 	mov	w0, #0x4047                	// #16455
 18c:	79002660 	strh	w0, [x19, #18]
 190:	528ea600 	mov	w0, #0x7530                	// #30000
 194:	79002a60 	strh	w0, [x19, #20]
 198:	52817700 	mov	w0, #0xbb8                 	// #3000
 19c:	79002e60 	strh	w0, [x19, #22]
 1a0:	5287a260 	mov	w0, #0x3d13                	// #15635
 1a4:	79003260 	strh	w0, [x19, #24]
 1a8:	52880840 	mov	w0, #0x4042                	// #16450
 1ac:	79003660 	strh	w0, [x19, #26]
 1b0:	52800640 	mov	w0, #0x32                  	// #50
 1b4:	79000e60 	strh	w0, [x19, #6]
 1b8:	52800c80 	mov	w0, #0x64                  	// #100
 1bc:	79001260 	strh	w0, [x19, #8]
 1c0:	52803e80 	mov	w0, #0x1f4                 	// #500
 1c4:	79001660 	strh	w0, [x19, #10]
 1c8:	f9400bf3 	ldr	x19, [sp, #16]
 1cc:	a8c27bfd 	ldp	x29, x30, [sp], #32
 1d0:	d65f03c0 	ret
 1d4:	a9be7bfd 	stp	x29, x30, [sp, #-32]!
 1d8:	910003fd 	mov	x29, sp
 1dc:	f9000bf3 	str	x19, [sp, #16]
 1e0:	aa0003f3 	mov	x19, x0
 1e4:	aa1e03e0 	mov	x0, x30
 1e8:	d503201f 	nop
 1ec:	b40001f3 	cbz	x19, 0x228
 1f0:	52800182 	mov	w2, #0xc                   	// #12
 1f4:	79000a62 	strh	w2, [x19, #4]
 1f8:	128007e2 	mov	w2, #0xffffffc0            	// #-64
 1fc:	52800021 	mov	w1, #0x1                   	// #1
