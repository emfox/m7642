
ehci_probe.bin:     file format binary


Disassembly of section .data:

0000000000000000 <.data>:
   0:	a9bc7bfd 	stp	x29, x30, [sp, #-64]!
   4:	910003fd 	add	x29, sp, #0x0
   8:	a90153f3 	stp	x19, x20, [sp, #16]
   c:	a9025bf5 	stp	x21, x22, [sp, #32]
  10:	a90363f7 	stp	x23, x24, [sp, #48]
  14:	aa0003f4 	orr	x20, xzr, x0
  18:	aa1e03e0 	orr	x0, xzr, x30
  1c:	d503201f 	hint	#0x0
  20:	97ff3b06 	bl	0xfffffffffffcec38
  24:	2a0003f3 	orr	w19, wzr, w0
  28:	34000100 	cbz	w0, 0x48
  2c:	12800253 	movn	w19, #0x12
  30:	2a1303e0 	orr	w0, wzr, w19
  34:	a94153f3 	ldp	x19, x20, [sp, #16]
  38:	a9425bf5 	ldp	x21, x22, [sp, #32]
  3c:	a94363f7 	ldp	x23, x24, [sp, #48]
  40:	a8c47bfd 	ldp	x29, x30, [sp], #64
  44:	d65f03c0 	ret
  48:	f9400281 	ldr	x1, [x20]
  4c:	b0003dc0 	adrp	x0, 0x7b9000
  50:	910e2000 	add	x0, x0, #0x388
  54:	97ea6a2a 	bl	0xffffffffffa9a8fc
  58:	f9405a80 	ldr	x0, [x20, #176]
  5c:	b4001fe0 	cbz	x0, 0x458
  60:	f940f680 	ldr	x0, [x20, #488]
  64:	b40014a0 	cbz	x0, 0x2f8
  68:	b1004296 	adds	x22, x20, #0x10
  6c:	540014c0 	b.eq	0x304  // b.none
  70:	f9410ec0 	ldr	x0, [x22, #536]
  74:	b4001480 	cbz	x0, 0x304
  78:	f9404002 	ldr	x2, [x0, #128]
  7c:	b4001202 	cbz	x2, 0x2bc
  80:	b2407fe1 	orr	x1, xzr, #0xffffffff
  84:	aa1603e0 	orr	x0, xzr, x22
  88:	d63f0040 	blr	x2
  8c:	35000140 	cbnz	w0, 0xb4
  90:	b4000e76 	cbz	x22, 0x25c
  94:	f9410ec0 	ldr	x0, [x22, #536]
  98:	b4000e20 	cbz	x0, 0x25c
  9c:	f9403c02 	ldr	x2, [x0, #120]
  a0:	b4000162 	cbz	x2, 0xcc
  a4:	b2407fe1 	orr	x1, xzr, #0xffffffff
  a8:	aa1603e0 	orr	x0, xzr, x22
  ac:	d63f0040 	blr	x2
  b0:	350000e0 	cbnz	w0, 0xcc
  b4:	b0003dc0 	adrp	x0, 0x7b9000
  b8:	b2407fe1 	orr	x1, xzr, #0xffffffff
  bc:	91102000 	add	x0, x0, #0x408
  c0:	12800bd3 	movn	w19, #0x5e
  c4:	97ea6a0e 	bl	0xffffffffffa9a8fc
  c8:	17ffffda 	b	0x30
  cc:	b2407fe1 	orr	x1, xzr, #0xffffffff
  d0:	f900f2c1 	str	x1, [x22, #480]
  d4:	90003dc0 	adrp	x0, 0x7b8000
  d8:	f940f682 	ldr	x2, [x20, #488]
  dc:	910f2000 	add	x0, x0, #0x3c8
  e0:	f9400042 	ldr	x2, [x2]
  e4:	97ea6a06 	bl	0xffffffffffa9a8fc
  e8:	f9412280 	ldr	x0, [x20, #576]
  ec:	52800001 	movz	w1, #0x0
  f0:	9403fac5 	bl	0xfec04
  f4:	2a0003f8 	orr	w24, wzr, w0
  f8:	90003dc2 	adrp	x2, 0x7b8000
  fc:	f00053c0 	adrp	x0, 0xa7b000
 100:	91100042 	add	x2, x2, #0x400
 104:	aa1603e1 	orr	x1, xzr, x22
 108:	91006000 	add	x0, x0, #0x18
 10c:	97ff628b 	bl	0xfffffffffffd8b38
 110:	aa0003f5 	orr	x21, xzr, x0
 114:	b4001aa0 	cbz	x0, 0x468
 118:	f9400297 	ldr	x23, [x20]
 11c:	900039a1 	adrp	x1, 0x734000
 120:	d2800182 	movz	x2, #0xc
 124:	91064021 	add	x1, x1, #0x190
 128:	aa1703e0 	orr	x0, xzr, x23
 12c:	97f8c8ee 	bl	0xffffffffffe324e4
 130:	35000660 	cbnz	w0, 0x1fc
 134:	90006020 	adrp	x0, 0xc04000
 138:	52800021 	movz	w1, #0x1
 13c:	b9022ea1 	str	w1, [x21, #556]
 140:	528004f7 	movz	w23, #0x27
 144:	f9402401 	ldr	x1, [x0, #72]
 148:	91481c24 	add	x4, x1, #0x207, lsl #12
 14c:	91481023 	add	x3, x1, #0x204, lsl #12
 150:	91480022 	add	x2, x1, #0x200, lsl #12
 154:	91491821 	add	x1, x1, #0x246, lsl #12
 158:	91140084 	add	x4, x4, #0x500
 15c:	91200063 	add	x3, x3, #0x800
 160:	91380042 	add	x2, x2, #0xe00
 164:	91300021 	add	x1, x1, #0xc00
 168:	f9011aa4 	str	x4, [x21, #560]
 16c:	f9011ea3 	str	x3, [x21, #568]
 170:	f90122a2 	str	x2, [x21, #576]
 174:	f90126a1 	str	x1, [x21, #584]
 178:	f9402400 	ldr	x0, [x0, #72]
 17c:	f9411ea1 	ldr	x1, [x21, #568]
 180:	11480002 	add	w2, w0, #0x200, lsl #12
 184:	4a000040 	eor	w0, w2, w0
 188:	93407c00 	sbfm	x0, x0, #0, #31
 18c:	ea01001f 	ands	xzr, x0, x1
 190:	54000101 	b.ne	0x1b0  // b.any
 194:	b9422ea1 	ldr	w1, [x21, #556]
 198:	90003dc0 	adrp	x0, 0x7b8000
 19c:	91118000 	add	x0, x0, #0x460
 1a0:	97ea69d7 	bl	0xffffffffffa9a8fc
 1a4:	b9428aa0 	ldr	w0, [x21, #648]
 1a8:	321c0000 	orr	w0, w0, #0x10
 1ac:	b9028aa0 	str	w0, [x21, #648]
 1b0:	f9412281 	ldr	x1, [x20, #576]
 1b4:	aa1503e0 	orr	x0, xzr, x21
 1b8:	12800178 	movn	w24, #0xb
 1bc:	97fffcdd 	bl	0xfffffffffffff530
 1c0:	aa1503e0 	orr	x0, xzr, x21
 1c4:	97ffff80 	bl	0xffffffffffffffc4
 1c8:	3944c2a0 	ldrb	w0, [x21, #304]
 1cc:	d2803f82 	movz	x2, #0x1fc
 1d0:	f9411ea1 	ldr	x1, [x21, #568]
 1d4:	321a0000 	orr	w0, w0, #0x40
 1d8:	f900a2a1 	str	x1, [x21, #320]
 1dc:	f900a6a2 	str	x2, [x21, #328]
 1e0:	3904c2a0 	strb	w0, [x21, #304]
 1e4:	f9009ea1 	str	x1, [x21, #312]
 1e8:	b5000a61 	cbnz	x1, 0x334
 1ec:	aa1503e0 	orr	x0, xzr, x21
 1f0:	2a1803f3 	orr	w19, wzr, w24
 1f4:	97ff61b2 	bl	0xfffffffffffd88bc
 1f8:	17ffff8e 	b	0x30
 1fc:	900039a1 	adrp	x1, 0x734000
 200:	d2800182 	movz	x2, #0xc
 204:	91060021 	add	x1, x1, #0x180
 208:	aa1703e0 	orr	x0, xzr, x23
 20c:	97f8c8b6 	bl	0xffffffffffe324e4
 210:	350002e0 	cbnz	w0, 0x26c
 214:	90006020 	adrp	x0, 0xc04000
 218:	52800041 	movz	w1, #0x2
 21c:	b9022ea1 	str	w1, [x21, #556]
 220:	52800837 	movz	w23, #0x41
 224:	f9402401 	ldr	x1, [x0, #72]
 228:	91481c24 	add	x4, x1, #0x207, lsl #12
 22c:	91480423 	add	x3, x1, #0x201, lsl #12
 230:	91480022 	add	x2, x1, #0x200, lsl #12
 234:	91491821 	add	x1, x1, #0x246, lsl #12
 238:	91100084 	add	x4, x4, #0x400
 23c:	91280063 	add	x3, x3, #0xa00
 240:	913c0042 	add	x2, x2, #0xf00
 244:	91310021 	add	x1, x1, #0xc40
 248:	f9011aa4 	str	x4, [x21, #560]
 24c:	f9011ea3 	str	x3, [x21, #568]
 250:	f90122a2 	str	x2, [x21, #576]
 254:	f90126a1 	str	x1, [x21, #584]
 258:	17ffffc8 	b	0x178
 25c:	90006020 	adrp	x0, 0xc04000
 260:	f947a000 	ldr	x0, [x0, #3904]
 264:	b4fff280 	cbz	x0, 0xb4
 268:	17ffff8d 	b	0x9c
 26c:	900039a1 	adrp	x1, 0x734000
 270:	d2800182 	movz	x2, #0xc
 274:	9105c021 	add	x1, x1, #0x170
 278:	aa1703e0 	orr	x0, xzr, x23
 27c:	97f8c89a 	bl	0xffffffffffe324e4
 280:	35000480 	cbnz	w0, 0x310
 284:	90006020 	adrp	x0, 0xc04000
 288:	52800061 	movz	w1, #0x3
 28c:	b9022ea1 	str	w1, [x21, #556]
 290:	52800897 	movz	w23, #0x44
 294:	f9402401 	ldr	x1, [x0, #72]
 298:	91408821 	add	x1, x1, #0x22, lsl #12
 29c:	f90126a1 	str	x1, [x21, #584]
 2a0:	91240023 	add	x3, x1, #0x900
 2a4:	91180022 	add	x2, x1, #0x600
 2a8:	f9011aa3 	str	x3, [x21, #560]
 2ac:	91100021 	add	x1, x1, #0x400
 2b0:	f9011ea2 	str	x2, [x21, #568]
 2b4:	f90122a1 	str	x1, [x21, #576]
 2b8:	17ffffb0 	b	0x178
 2bc:	f940eec0 	ldr	x0, [x22, #472]
 2c0:	b4ffefa0 	cbz	x0, 0xb4
 2c4:	b4000c36 	cbz	x22, 0x448
 2c8:	f9410ec0 	ldr	x0, [x22, #536]
 2cc:	b4000be0 	cbz	x0, 0x448
 2d0:	f9403c02 	ldr	x2, [x0, #120]
 2d4:	b40000a2 	cbz	x2, 0x2e8
 2d8:	b2407fe1 	orr	x1, xzr, #0xffffffff
 2dc:	aa1603e0 	orr	x0, xzr, x22
 2e0:	d63f0040 	blr	x2
 2e4:	34ffee80 	cbz	w0, 0xb4
 2e8:	f940eec0 	ldr	x0, [x22, #472]
 2ec:	b2407fe1 	orr	x1, xzr, #0xffffffff
 2f0:	f9000001 	str	x1, [x0]
 2f4:	17ffff67 	b	0x90
 2f8:	9107c280 	add	x0, x20, #0x1f0
 2fc:	f900f680 	str	x0, [x20, #488]
 300:	17ffff5a 	b	0x68
 304:	90006020 	adrp	x0, 0xc04000
 308:	f947a000 	ldr	x0, [x0, #3904]
 30c:	17ffff5b 	b	0x78
 310:	900039a1 	adrp	x1, 0x734000
 314:	d2800182 	movz	x2, #0xc
 318:	91058021 	add	x1, x1, #0x160
 31c:	aa1703e0 	orr	x0, xzr, x23
 320:	97f8c871 	bl	0xffffffffffe324e4
 324:	34000a60 	cbz	w0, 0x470
 328:	2a1803f7 	orr	w23, wzr, w24
 32c:	90006020 	adrp	x0, 0xc04000
 330:	17ffff92 	b	0x178
 334:	910b22a2 	add	x2, x21, #0x2c8
 338:	9278dc20 	and	x0, x1, #0xffffffffffffff00
 33c:	f9006041 	str	x1, [x2, #192]
 340:	8b210400 	add	x0, x0, w1, uxtb #1
 344:	b9400004 	ldr	w4, [x0]
 348:	d5033d9f 	dsb	ld
 34c:	91001000 	add	x0, x0, #0x4
 350:	b9400000 	ldr	w0, [x0]
 354:	d5033d9f 	dsb	ld
 358:	f9406043 	ldr	x3, [x2, #192]
 35c:	8b240021 	add	x1, x1, w4, uxtb
 360:	f9006441 	str	x1, [x2, #200]
 364:	91001063 	add	x3, x3, #0x4
 368:	9278dc60 	and	x0, x3, #0xffffffffffffff00
 36c:	8b230403 	add	x3, x0, w3, uxtb #1
 370:	b9400060 	ldr	w0, [x3]
 374:	d5033d9f 	dsb	ld
 378:	91001063 	add	x3, x3, #0x4
 37c:	b9400063 	ldr	w3, [x3]
 380:	d5033d9f 	dsb	ld
 384:	12003c00 	and	w0, w0, #0xffff
 388:	52800001 	movz	w1, #0x0
 38c:	2a034003 	orr	w3, w0, w3, lsl #16
 390:	aa1503e0 	orr	x0, xzr, x21
 394:	b900d843 	str	w3, [x2, #216]
 398:	97ffc6fc 	bl	0xffffffffffff1f88
 39c:	52800021 	movz	w1, #0x1
 3a0:	aa1503e0 	orr	x0, xzr, x21
 3a4:	97ffc67f 	bl	0xffffffffffff1da0
 3a8:	f9400281 	ldr	x1, [x20]
 3ac:	90003dc0 	adrp	x0, 0x7b8000
 3b0:	2a1703e2 	orr	w2, wzr, w23
 3b4:	9110e000 	add	x0, x0, #0x438
 3b8:	97ea6951 	bl	0xffffffffffa9a8fc
 3bc:	d2800002 	movz	x2, #0x0
 3c0:	2a1703e1 	orr	w1, wzr, w23
 3c4:	aa1503e0 	orr	x0, xzr, x21
 3c8:	97ff649a 	bl	0xfffffffffffd9630
 3cc:	2a0003f8 	orr	w24, wzr, w0
 3d0:	90006603 	adrp	x3, 0xcc0000
 3d4:	90000005 	adrp	x5, 0x0
 3d8:	91018063 	add	x3, x3, #0x60
 3dc:	f0ffffc4 	adrp	x4, 0xffffffffffffb000
 3e0:	90003dc0 	adrp	x0, 0x7b8000
 3e4:	9100a062 	add	x2, x3, #0x28
 3e8:	aa1603e1 	orr	x1, xzr, x22
 3ec:	91043084 	add	x4, x4, #0x10c
 3f0:	b90292bf 	str	wzr, [x21, #656]
 3f4:	d2800007 	movz	x7, #0x0
 3f8:	390a52bf 	strb	wzr, [x21, #660]
 3fc:	d2800006 	movz	x6, #0x0
 400:	390a56bf 	strb	wzr, [x21, #661]
 404:	910fa0a5 	add	x5, x5, #0x3e8
 408:	790542bf 	strh	wzr, [x21, #672]
 40c:	91114000 	add	x0, x0, #0x450
 410:	790546bf 	strh	wzr, [x21, #674]
 414:	97fca1f7 	bl	0xfffffffffff28bf0
 418:	f0005882 	adrp	x2, 0xb13000
 41c:	f94002a0 	ldr	x0, [x21]
 420:	91378042 	add	x2, x2, #0xde0
 424:	528036c3 	movz	w3, #0x1b6
 428:	91012042 	add	x2, x2, #0x48
 42c:	aa0203e1 	orr	x1, xzr, x2
 430:	79401044 	ldrh	w4, [x2, #8]
 434:	2a030083 	orr	w3, w4, w3
 438:	79001043 	strh	w3, [x2, #8]
 43c:	97fc383c 	bl	0xfffffffffff0e52c
 440:	35ffed78 	cbnz	w24, 0x1ec
 444:	17fffefb 	b	0x30
 448:	90006020 	adrp	x0, 0xc04000
 44c:	f947a000 	ldr	x0, [x0, #3904]
 450:	b4ffe320 	cbz	x0, 0xb4
 454:	17ffff9f 	b	0x2d0
 458:	90003dc0 	adrp	x0, 0x7b8000
 45c:	910e6000 	add	x0, x0, #0x398
 460:	97ea6927 	bl	0xffffffffffa9a8fc
 464:	17fffeff 	b	0x60
 468:	12800173 	movn	w19, #0xb
 46c:	17fffef1 	b	0x30
 470:	90006020 	adrp	x0, 0xc04000
 474:	52800081 	movz	w1, #0x4
 478:	b9022ea1 	str	w1, [x21, #556]
 47c:	52800bd7 	movz	w23, #0x5e
 480:	f9402401 	ldr	x1, [x0, #72]
 484:	915b8821 	add	x1, x1, #0x6e2, lsl #12
 488:	91100024 	add	x4, x1, #0x400
 48c:	91200023 	add	x3, x1, #0x800
 490:	91080022 	add	x2, x1, #0x200
 494:	f9011aa4 	str	x4, [x21, #560]
 498:	91190021 	add	x1, x1, #0x640
 49c:	f9011ea3 	str	x3, [x21, #568]
 4a0:	f90122a2 	str	x2, [x21, #576]
 4a4:	f90126a1 	str	x1, [x21, #584]
 4a8:	17ffff34 	b	0x178
 4ac:	a9be7bfd 	stp	x29, x30, [sp, #-32]!
 4b0:	910003fd 	add	x29, sp, #0x0
 4b4:	f9000bf3 	str	x19, [sp, #16]
 4b8:	aa0003f3 	orr	x19, xzr, x0
 4bc:	aa1e03e0 	orr	x0, xzr, x30
 4c0:	d503201f 	hint	#0x0
 4c4:	f100427f 	subs	xzr, x19, #0x10
 4c8:	540010a0 	b.eq	0x6dc  // b.none
 4cc:	90006600 	adrp	x0, 0xcc0000
 4d0:	f9403400 	ldr	x0, [x0, #104]
 4d4:	b4000060 	cbz	x0, 0x4e0
 4d8:	91034000 	add	x0, x0, #0xd0
 4dc:	94154ff0 	bl	0x55449c
 4e0:	f9405673 	ldr	x19, [x19, #168]
 4e4:	90003dc0 	adrp	x0, 0x7b8000
 4e8:	91122000 	add	x0, x0, #0x488
 4ec:	b9422e61 	ldr	w1, [x19, #556]
 4f0:	97ea6903 	bl	0xffffffffffa9a8fc
 4f4:	b9428a60 	ldr	w0, [x19, #648]
 4f8:	910b2262 	add	x2, x19, #0x2c8
 4fc:	372003e0 	tbnz	w0, #4, 0x578
 500:	f9406441 	ldr	x1, [x2, #200]
 504:	91007021 	add	x1, x1, #0x1c
 508:	9278dc20 	and	x0, x1, #0xffffffffffffff00
 50c:	8b210401 	add	x1, x0, w1, uxtb #1
 510:	b9400020 	ldr	w0, [x1]
 514:	d5033d9f 	dsb	ld
 518:	91001021 	add	x1, x1, #0x4
 51c:	b9400022 	ldr	w2, [x1]
 520:	d5033d9f 	dsb	ld
 524:	12003c01 	and	w1, w0, #0xffff
 528:	2a024021 	orr	w1, w1, w2, lsl #16
 52c:	7100043f 	subs	wzr, w1, #0x1
 530:	540000c0 	b.eq	0x548  // b.none
 534:	aa1303e0 	orr	x0, xzr, x19
 538:	97fffea3 	bl	0xffffffffffffffc4
 53c:	52800001 	movz	w1, #0x0
 540:	aa1303e0 	orr	x0, xzr, x19
 544:	97ffc691 	bl	0xffffffffffff1f88
 548:	52800001 	movz	w1, #0x0
 54c:	aa1303e0 	orr	x0, xzr, x19
 550:	97ffdb52 	bl	0xffffffffffff7298
 554:	9104a261 	add	x1, x19, #0x128
 558:	52800040 	movz	w0, #0x2
 55c:	97f8c282 	bl	0xffffffffffe30f64
 560:	aa1303e0 	orr	x0, xzr, x19
 564:	97ff63cc 	bl	0xfffffffffffd9494
 568:	f9400bf3 	ldr	x19, [sp, #16]
 56c:	52800000 	movz	w0, #0x0
 570:	a8c27bfd 	ldp	x29, x30, [sp], #32
 574:	d65f03c0 	ret
 578:	d5033e9f 	dsb	st
 57c:	f9411a60 	ldr	x0, [x19, #560]
 580:	91008000 	add	x0, x0, #0x20
 584:	39400000 	ldrb	w0, [x0]
 588:	53001c00 	ubfm	w0, w0, #0, #7
 58c:	d5033d9f 	dsb	ld
 590:	f9411a61 	ldr	x1, [x19, #560]
 594:	321a0000 	orr	w0, w0, #0x40
 598:	91008021 	add	x1, x1, #0x20
 59c:	39000020 	strb	w0, [x1]
 5a0:	d5033e9f 	dsb	st
 5a4:	f9411a60 	ldr	x0, [x19, #560]
 5a8:	91000400 	add	x0, x0, #0x1
 5ac:	39400000 	ldrb	w0, [x0]
 5b0:	53001c00 	ubfm	w0, w0, #0, #7
 5b4:	d5033d9f 	dsb	ld
 5b8:	f9411a61 	ldr	x1, [x19, #560]
 5bc:	12196000 	and	w0, w0, #0xffffff80
 5c0:	91000421 	add	x1, x1, #0x1
 5c4:	39000020 	strb	w0, [x1]
 5c8:	d5033e9f 	dsb	st
 5cc:	f9411a60 	ldr	x0, [x19, #560]
 5d0:	39400000 	ldrb	w0, [x0]
 5d4:	53001c00 	ubfm	w0, w0, #0, #7
 5d8:	d5033d9f 	dsb	ld
 5dc:	121d7800 	and	w0, w0, #0xfffffffb
 5e0:	f9411a61 	ldr	x1, [x19, #560]
 5e4:	39000020 	strb	w0, [x1]
 5e8:	90006021 	adrp	x1, 0xc04000
 5ec:	f9402420 	ldr	x0, [x1, #72]
 5f0:	91408800 	add	x0, x0, #0x22, lsl #12
 5f4:	91080000 	add	x0, x0, #0x200
 5f8:	39400000 	ldrb	w0, [x0]
 5fc:	53001c00 	ubfm	w0, w0, #0, #7
 600:	d5033d9f 	dsb	ld
 604:	d5033e9f 	dsb	st
 608:	f9402421 	ldr	x1, [x1, #72]
 60c:	121e7800 	and	w0, w0, #0xfffffffd
 610:	91408821 	add	x1, x1, #0x22, lsl #12
 614:	91080021 	add	x1, x1, #0x200
 618:	39000020 	strb	w0, [x1]
 61c:	d28dbc00 	movz	x0, #0x6de0
 620:	f2a00680 	movk	x0, #0x34, lsl #16
 624:	97f8c51e 	bl	0xffffffffffe31a9c
 628:	b9428a60 	ldr	w0, [x19, #648]
 62c:	910b2262 	add	x2, x19, #0x2c8
 630:	361ff680 	tbz	w0, #3, 0x500
 634:	f9406441 	ldr	x1, [x2, #200]
 638:	91009020 	add	x0, x1, #0x24
 63c:	9278dc01 	and	x1, x0, #0xffffffffffffff00
 640:	8b200421 	add	x1, x1, w0, uxtb #1
 644:	b9400020 	ldr	w0, [x1]
 648:	d5033d9f 	dsb	ld
 64c:	91001021 	add	x1, x1, #0x4
 650:	b9400021 	ldr	w1, [x1]
 654:	d5033d9f 	dsb	ld
 658:	f9406443 	ldr	x3, [x2, #200]
 65c:	12003c00 	and	w0, w0, #0xffff
 660:	2a014000 	orr	w0, w0, w1, lsl #16
 664:	91009061 	add	x1, x3, #0x24
 668:	9278dc23 	and	x3, x1, #0xffffffffffffff00
 66c:	8b210461 	add	x1, x3, w1, uxtb #1
 670:	d5033e9f 	dsb	st
 674:	12003c03 	and	w3, w0, #0xffff
 678:	321a0063 	orr	w3, w3, #0x40
 67c:	b9000023 	str	w3, [x1]
 680:	d5033e9f 	dsb	st
 684:	53107c00 	ubfm	w0, w0, #16, #31
 688:	91001021 	add	x1, x1, #0x4
 68c:	b9000020 	str	w0, [x1]
 690:	f9406440 	ldr	x0, [x2, #200]
 694:	91009000 	add	x0, x0, #0x24
 698:	9278dc01 	and	x1, x0, #0xffffffffffffff00
 69c:	8b200420 	add	x0, x1, w0, uxtb #1
 6a0:	b9400001 	ldr	w1, [x0]
 6a4:	d5033d9f 	dsb	ld
 6a8:	91001000 	add	x0, x0, #0x4
 6ac:	b9400000 	ldr	w0, [x0]
 6b0:	d5033d9f 	dsb	ld
 6b4:	f9406440 	ldr	x0, [x2, #200]
 6b8:	91008000 	add	x0, x0, #0x20
 6bc:	9278dc01 	and	x1, x0, #0xffffffffffffff00
 6c0:	8b200420 	add	x0, x1, w0, uxtb #1
 6c4:	b9400001 	ldr	w1, [x0]
 6c8:	d5033d9f 	dsb	ld
 6cc:	91001000 	add	x0, x0, #0x4
 6d0:	b9400000 	ldr	w0, [x0]
 6d4:	d5033d9f 	dsb	ld
 6d8:	17ffff8a 	b	0x500
 6dc:	d4210000 	brk	#0x800
 6e0:	12800240 	movn	w0, #0x12
 6e4:	f9400bf3 	ldr	x19, [sp, #16]
 6e8:	a8c27bfd 	ldp	x29, x30, [sp], #32
 6ec:	d65f03c0 	ret
 6f0:	a9bd7bfd 	stp	x29, x30, [sp, #-48]!
 6f4:	910003fd 	add	x29, sp, #0x0
 6f8:	f9000bf3 	str	x19, [sp, #16]
 6fc:	aa0003f3 	orr	x19, xzr, x0
 700:	aa1e03e0 	orr	x0, xzr, x30
 704:	b9002fa1 	str	w1, [x29, #44]
 708:	d503201f 	hint	#0x0
 70c:	b9402fa1 	ldr	w1, [x29, #44]
 710:	340002a1 	cbz	w1, 0x764
 714:	910b2260 	add	x0, x19, #0x2c8
 718:	51000421 	sub	w1, w1, #0x1
 71c:	f9400402 	ldr	x2, [x0, #8]
 720:	91004021 	add	x1, x1, #0x10
 724:	d37ef421 	ubfm	x1, x1, #62, #61
 728:	8b010042 	add	x2, x2, x1
 72c:	91005042 	add	x2, x2, #0x14
 730:	b9400042 	ldr	w2, [x2]
 734:	d5033d9f 	dsb	ld
 738:	360001a2 	tbz	w2, #0, 0x76c
 73c:	f9400400 	ldr	x0, [x0, #8]
 740:	8b010001 	add	x1, x0, x1
 744:	91005021 	add	x1, x1, #0x14
 748:	d5033e9f 	dsb	st
 74c:	52800200 	movz	w0, #0x10
 750:	b9000020 	str	w0, [x1]
 754:	52800000 	movz	w0, #0x0
 758:	f9400bf3 	ldr	x19, [sp, #16]
 75c:	a8c37bfd 	ldp	x29, x30, [sp], #48
 760:	d65f03c0 	ret
 764:	128002a0 	movn	w0, #0x15
 768:	17fffffc 	b	0x758
 76c:	12800240 	movn	w0, #0x12
 770:	17fffffa 	b	0x758
 774:	a9bd7bfd 	stp	x29, x30, [sp, #-48]!
 778:	910003fd 	add	x29, sp, #0x0
 77c:	f9000bf3 	str	x19, [sp, #16]
 780:	aa0003f3 	orr	x19, xzr, x0
 784:	aa1e03e0 	orr	x0, xzr, x30
 788:	f90017a1 	str	x1, [x29, #40]
 78c:	d503201f 	hint	#0x0
 790:	f94017a1 	ldr	x1, [x29, #40]
 794:	b9400020 	ldr	w0, [x1]
 798:	32120000 	orr	w0, w0, #0x4000
 79c:	b9000020 	str	w0, [x1]
 7a0:	d5033e9f 	dsb	st
 7a4:	39414420 	ldrb	w0, [x1, #81]
 7a8:	52800022 	movz	w2, #0x1
 7ac:	39014022 	strb	w2, [x1, #80]
 7b0:	7100081f 	subs	wzr, w0, #0x2
 7b4:	540007c0 	b.eq	0x8ac  // b.none
 7b8:	71000c1f 	subs	wzr, w0, #0x3
 7bc:	54000241 	b.ne	0x804  // b.any
 7c0:	f9401420 	ldr	x0, [x1, #40]
 7c4:	b4000b60 	cbz	x0, 0x930
 7c8:	f9401022 	ldr	x2, [x1, #32]
 7cc:	f9001002 	str	x2, [x0, #32]
 7d0:	f9401420 	ldr	x0, [x1, #40]
 7d4:	b9400c22 	ldr	w2, [x1, #12]
 7d8:	b9000c02 	str	w2, [x0, #12]
 7dc:	f9401660 	ldr	x0, [x19, #40]
 7e0:	eb01001f 	subs	xzr, x0, x1
 7e4:	540009c0 	b.eq	0x91c  // b.none
 7e8:	f9401020 	ldr	x0, [x1, #32]
 7ec:	b4000060 	cbz	x0, 0x7f8
 7f0:	f9401421 	ldr	x1, [x1, #40]
 7f4:	f9001401 	str	x1, [x0, #40]
 7f8:	f9400bf3 	ldr	x19, [sp, #16]
 7fc:	a8c37bfd 	ldp	x29, x30, [sp], #48
 800:	d65f03c0 	ret
 804:	39414825 	ldrb	w5, [x1, #82]
 808:	71007cbf 	subs	wzr, w5, #0x1f
 80c:	54000bac 	b.gt	0x980
 810:	93407ca4 	sbfm	x4, x5, #0, #31
 814:	f9400a60 	ldr	x0, [x19, #16]
 818:	91001883 	add	x3, x4, #0x6
 81c:	8b030e62 	add	x2, x19, x3, lsl #3
 820:	f9400443 	ldr	x3, [x2, #8]
 824:	b4000123 	cbz	x3, 0x848
 828:	eb03003f 	subs	xzr, x1, x3
 82c:	54000081 	b.ne	0x83c  // b.any
 830:	1400002e 	b	0x8e8
 834:	540002e0 	b.eq	0x890  // b.none
 838:	aa0203e3 	orr	x3, xzr, x2
 83c:	f9401062 	ldr	x2, [x3, #32]
 840:	eb02003f 	subs	xzr, x1, x2
 844:	b5ffff82 	cbnz	x2, 0x834
 848:	8b040a64 	add	x4, x19, x4, lsl #2
 84c:	7940ac20 	ldrh	w0, [x1, #86]
 850:	b9438882 	ldr	w2, [x4, #904]
 854:	4b000042 	sub	w2, w2, w0
 858:	b9038882 	str	w2, [x4, #904]
 85c:	7940a820 	ldrh	w0, [x1, #84]
 860:	0b0000a5 	add	w5, w5, w0
 864:	71007cbf 	subs	wzr, w5, #0x1f
 868:	54fffd4d 	b.le	0x810
 86c:	7940ac22 	ldrh	w2, [x1, #86]
 870:	d10b2273 	sub	x19, x19, #0x2c8
 874:	1ac00840 	udiv	w0, w2, w0
 878:	b9407a61 	ldr	w1, [x19, #120]
 87c:	4b000020 	sub	w0, w1, w0
 880:	b9007a60 	str	w0, [x19, #120]
 884:	f9400bf3 	ldr	x19, [sp, #16]
 888:	a8c37bfd 	ldp	x29, x30, [sp], #48
 88c:	d65f03c0 	ret
 890:	91003060 	add	x0, x3, #0xc
 894:	91008063 	add	x3, x3, #0x20
 898:	b9400c22 	ldr	w2, [x1, #12]
 89c:	b9000002 	str	w2, [x0]
 8a0:	f9401020 	ldr	x0, [x1, #32]
 8a4:	f9000060 	str	x0, [x3]
 8a8:	17ffffe8 	b	0x848
 8ac:	f9401420 	ldr	x0, [x1, #40]
 8b0:	b4000220 	cbz	x0, 0x8f4
 8b4:	f9401022 	ldr	x2, [x1, #32]
 8b8:	f9001002 	str	x2, [x0, #32]
 8bc:	f9401420 	ldr	x0, [x1, #40]
 8c0:	b9400c22 	ldr	w2, [x1, #12]
 8c4:	b9000c02 	str	w2, [x0, #12]
 8c8:	f9401a60 	ldr	x0, [x19, #48]
 8cc:	eb01001f 	subs	xzr, x0, x1
 8d0:	54fff8c1 	b.ne	0x7e8  // b.any
 8d4:	f9401420 	ldr	x0, [x1, #40]
 8d8:	f9001a60 	str	x0, [x19, #48]
 8dc:	b4fff8e0 	cbz	x0, 0x7f8
 8e0:	f900101f 	str	xzr, [x0, #32]
 8e4:	17ffffc5 	b	0x7f8
 8e8:	91002043 	add	x3, x2, #0x8
 8ec:	8b040800 	add	x0, x0, x4, lsl #2
 8f0:	17ffffea 	b	0x898
 8f4:	b9400c22 	ldr	w2, [x1, #12]
 8f8:	350003a2 	cbnz	w2, 0x96c
 8fc:	b9440a60 	ldr	w0, [x19, #1032]
 900:	f9400662 	ldr	x2, [x19, #8]
 904:	121b7800 	and	w0, w0, #0xffffffef
 908:	b9040a60 	str	w0, [x19, #1032]
 90c:	91001042 	add	x2, x2, #0x4
 910:	d5033e9f 	dsb	st
 914:	b9000040 	str	w0, [x2]
 918:	17ffffec 	b	0x8c8
 91c:	f9401420 	ldr	x0, [x1, #40]
 920:	f9001660 	str	x0, [x19, #40]
 924:	b4fff6a0 	cbz	x0, 0x7f8
 928:	f900101f 	str	xzr, [x0, #32]
 92c:	17ffffb3 	b	0x7f8
 930:	b9400c22 	ldr	w2, [x1, #12]
 934:	35000122 	cbnz	w2, 0x958
 938:	b9440a60 	ldr	w0, [x19, #1032]
 93c:	f9400662 	ldr	x2, [x19, #8]
 940:	121a7800 	and	w0, w0, #0xffffffdf
 944:	b9040a60 	str	w0, [x19, #1032]
 948:	91001042 	add	x2, x2, #0x4
 94c:	d5033e9f 	dsb	st
 950:	b9000040 	str	w0, [x2]
 954:	17ffffa2 	b	0x7dc
 958:	f9400660 	ldr	x0, [x19, #8]
 95c:	9100a000 	add	x0, x0, #0x28
 960:	d5033e9f 	dsb	st
 964:	b9000002 	str	w2, [x0]
 968:	17ffff9d 	b	0x7dc
 96c:	f9400660 	ldr	x0, [x19, #8]
 970:	91008000 	add	x0, x0, #0x20
 974:	d5033e9f 	dsb	st
 978:	b9000002 	str	w2, [x0]
 97c:	17ffffd3 	b	0x8c8
 980:	7940a820 	ldrh	w0, [x1, #84]
 984:	17ffffba 	b	0x86c
 988:	a9be7bfd 	stp	x29, x30, [sp, #-32]!
 98c:	910003fd 	add	x29, sp, #0x0
 990:	a90153f3 	stp	x19, x20, [sp, #16]
 994:	aa0103f3 	orr	x19, xzr, x1
 998:	aa0003f4 	orr	x20, xzr, x0
 99c:	aa1e03e0 	orr	x0, xzr, x30
 9a0:	d503201f 	hint	#0x0
 9a4:	b9400262 	ldr	w2, [x19]
 9a8:	aa1403e0 	orr	x0, xzr, x20
 9ac:	aa1303e1 	orr	x1, xzr, x19
 9b0:	32050042 	orr	w2, w2, #0x8000000
 9b4:	b9000262 	str	w2, [x19]
 9b8:	97ffff6f 	bl	0x774
 9bc:	f9401280 	ldr	x0, [x20, #32]
 9c0:	f9001260 	str	x0, [x19, #32]
 9c4:	f900167f 	str	xzr, [x19, #40]
 9c8:	f9001293 	str	x19, [x20, #32]
 9cc:	f9400680 	ldr	x0, [x20, #8]
 9d0:	91003000 	add	x0, x0, #0xc
 9d4:	d5033e9f 	dsb	st
 9d8:	52800081 	movz	w1, #0x4
 9dc:	b9000001 	str	w1, [x0]
 9e0:	f9400680 	ldr	x0, [x20, #8]
 9e4:	91004000 	add	x0, x0, #0x10
 9e8:	d5033e9f 	dsb	st
 9ec:	b9000001 	str	w1, [x0]
 9f0:	f9400680 	ldr	x0, [x20, #8]
 9f4:	91001000 	add	x0, x0, #0x4
 9f8:	b9400000 	ldr	w0, [x0]
 9fc:	d5033d9f 	dsb	ld
 a00:	f9400a80 	ldr	x0, [x20, #16]
 a04:	b9408000 	ldr	w0, [x0, #128]
 a08:	11000400 	add	w0, w0, #0x1
 a0c:	7900b660 	strh	w0, [x19, #90]
 a10:	a94153f3 	ldp	x19, x20, [sp, #16]
 a14:	a8c27bfd 	ldp	x29, x30, [sp], #32
 a18:	d65f03c0 	ret
 a1c:	a9bc7bfd 	stp	x29, x30, [sp, #-64]!
 a20:	910003fd 	add	x29, sp, #0x0
 a24:	f9000bf3 	str	x19, [sp, #16]
 a28:	aa0003f3 	orr	x19, xzr, x0
 a2c:	aa1e03e0 	orr	x0, xzr, x30
 a30:	f90013a4 	str	x4, [x29, #32]
 a34:	b9002fa1 	str	w1, [x29, #44]
 a38:	b9003ba5 	str	w5, [x29, #56]
 a3c:	f9001ba2 	str	x2, [x29, #48]
 a40:	b9003fa3 	str	w3, [x29, #60]
 a44:	d503201f 	hint	#0x0
 a48:	f94013a4 	ldr	x4, [x29, #32]
 a4c:	b9403ba5 	ldr	w5, [x29, #56]
 a50:	b9402fa1 	ldr	w1, [x29, #44]
 a54:	f9400487 	ldr	x7, [x4, #8]
 a58:	1210002b 	and	w11, w1, #0x10000
 a5c:	b9403fa3 	ldr	w3, [x29, #60]
 a60:	f9401ba2 	ldr	x2, [x29, #48]
 a64:	794010e6 	ldrh	w6, [x7, #8]
 a68:	510004c6 	sub	w6, w6, #0x1
 a6c:	6b0500df 	subs	wzr, w6, w5
 a70:	54000720 	b.eq	0xb54  // b.none
 a74:	320a0421 	orr	w1, w1, #0xc00000
 a78:	f94000ea 	ldr	x10, [x7]
 a7c:	8b25cce0 	add	x0, x7, w5, sxtw #3
 a80:	f9401009 	ldr	x9, [x0, #32]
 a84:	6b1f007f 	subs	wzr, w3, wzr
 a88:	1a9f1048 	csel	w8, w2, wzr, ne  // ne = any
 a8c:	6b1f007f 	subs	wzr, w3, wzr
 a90:	f9400d46 	ldr	x6, [x10, #24]
 a94:	f9001006 	str	x6, [x0, #32]
 a98:	f9000d49 	str	x9, [x10, #24]
 a9c:	f94000e7 	ldr	x7, [x7]
 aa0:	f9000cc7 	str	x7, [x6, #24]
 aa4:	f90020c2 	str	x2, [x6, #64]
 aa8:	9a9f1042 	csel	x2, x2, xzr, ne  // ne = any
 aac:	f90014df 	str	xzr, [x6, #40]
 ab0:	390050c5 	strb	w5, [x6, #20]
 ab4:	f90018c4 	str	x4, [x6, #48]
 ab8:	b90000c1 	str	w1, [x6]
 abc:	3400040b 	cbz	w11, 0xb3c
 ac0:	12002c41 	and	w1, w2, #0xfff
 ac4:	12144d00 	and	w0, w8, #0xfffff000
 ac8:	32134821 	orr	w1, w1, #0xffffe000
 acc:	b90004c0 	str	w0, [x6, #4]
 ad0:	790020c1 	strh	w1, [x6, #16]
 ad4:	b5000382 	cbnz	x2, 0xb44
 ad8:	b9000cdf 	str	wzr, [x6, #12]
 adc:	f9401d20 	ldr	x0, [x9, #56]
 ae0:	910120c1 	add	x1, x6, #0x48
 ae4:	b90008c0 	str	w0, [x6, #8]
 ae8:	9100c0e0 	add	x0, x7, #0x30
 aec:	f9401ce2 	ldr	x2, [x7, #56]
 af0:	f9001ce1 	str	x1, [x7, #56]
 af4:	f90024c0 	str	x0, [x6, #72]
 af8:	f90028c2 	str	x2, [x6, #80]
 afc:	f9000041 	str	x1, [x2]
 b00:	f9401cc1 	ldr	x1, [x6, #56]
 b04:	d346fc20 	ubfm	x0, x1, #6, #63
 b08:	4a010001 	eor	w1, w0, w1
 b0c:	d37d1421 	ubfm	x1, x1, #61, #5
 b10:	8b010260 	add	x0, x19, x1
 b14:	f940a801 	ldr	x1, [x0, #336]
 b18:	f90010c1 	str	x1, [x6, #32]
 b1c:	f900a806 	str	x6, [x0, #336]
 b20:	d5033e9f 	dsb	st
 b24:	f9400cc0 	ldr	x0, [x6, #24]
 b28:	b94008c1 	ldr	w1, [x6, #8]
 b2c:	b9000401 	str	w1, [x0, #4]
 b30:	f9400bf3 	ldr	x19, [sp, #16]
 b34:	a8c47bfd 	ldp	x29, x30, [sp], #64
 b38:	d65f03c0 	ret
 b3c:	b90004c8 	str	w8, [x6, #4]
 b40:	b4fffcc2 	cbz	x2, 0xad8
 b44:	51000463 	sub	w3, w3, #0x1
 b48:	0b080063 	add	w3, w3, w8
 b4c:	b9000cc3 	str	w3, [x6, #12]
 b50:	17ffffe3 	b	0xadc
 b54:	b9406480 	ldr	w0, [x4, #100]
 b58:	363ff900 	tbz	w0, #7, 0xa78
 b5c:	17ffffc6 	b	0xa74
 b60:	a9be7bfd 	stp	x29, x30, [sp, #-32]!
 b64:	910003fd 	add	x29, sp, #0x0
 b68:	f9000bf3 	str	x19, [sp, #16]
 b6c:	aa0003f3 	orr	x19, xzr, x0
 b70:	aa1e03e0 	orr	x0, xzr, x30
 b74:	d503201f 	hint	#0x0
 b78:	f9416e60 	ldr	x0, [x19, #728]
 b7c:	f9400bf3 	ldr	x19, [sp, #16]
 b80:	a8c27bfd 	ldp	x29, x30, [sp], #32
 b84:	79410000 	ldrh	w0, [x0, #128]
 b88:	d65f03c0 	ret
 b8c:	a9be7bfd 	stp	x29, x30, [sp, #-32]!
 b90:	910003fd 	add	x29, sp, #0x0
 b94:	f9000bf3 	str	x19, [sp, #16]
 b98:	aa0003f3 	orr	x19, xzr, x0
 b9c:	aa1e03e0 	orr	x0, xzr, x30
 ba0:	d503201f 	hint	#0x0
 ba4:	f9400661 	ldr	x1, [x19, #8]
 ba8:	91001021 	add	x1, x1, #0x4
 bac:	b9400021 	ldr	w1, [x1]
 bb0:	d5033d9f 	dsb	ld
 bb4:	f9400660 	ldr	x0, [x19, #8]
 bb8:	12170021 	and	w1, w1, #0x200
 bbc:	b9040a61 	str	w1, [x19, #1032]
 bc0:	91001000 	add	x0, x0, #0x4
 bc4:	d5033e9f 	dsb	st
 bc8:	b9000001 	str	w1, [x0]
 bcc:	b903827f 	str	wzr, [x19, #896]
 bd0:	f9400bf3 	ldr	x19, [sp, #16]
 bd4:	a8c27bfd 	ldp	x29, x30, [sp], #32
 bd8:	d65f03c0 	ret
 bdc:	a9be7bfd 	stp	x29, x30, [sp, #-32]!
 be0:	910003fd 	add	x29, sp, #0x0
 be4:	a90153f3 	stp	x19, x20, [sp, #16]
 be8:	aa0003f3 	orr	x19, xzr, x0
 bec:	aa1e03e0 	orr	x0, xzr, x30
 bf0:	aa0103f4 	orr	x20, xzr, x1
 bf4:	d503201f 	hint	#0x0
 bf8:	d2802c02 	movz	x2, #0x160
 bfc:	52800001 	movz	w1, #0x0
