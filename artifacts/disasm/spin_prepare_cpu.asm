
spin_prepare_cpu.bin:     file format binary


Disassembly of section .data:

ffffff8008087168 <.data>:
ffffff8008087168:	a9be7bfd 	stp	x29, x30, [sp, #-32]!
ffffff800808716c:	910003fd 	add	x29, sp, #0x0
ffffff8008087170:	a90153f3 	stp	x19, x20, [sp, #16]
ffffff8008087174:	2a0003f3 	orr	w19, wzr, w0
ffffff8008087178:	aa1e03e0 	orr	x0, xzr, x30
ffffff800808717c:	d503201f 	hint	#0x0
ffffff8008087180:	b0009687 	adrp	x7, 0xffffff8009358000
ffffff8008087184:	911a80e1 	add	x1, x7, #0x6a0
ffffff8008087188:	f8735820 	ldr	x0, [x1, w19, uxtw #3]
ffffff800808718c:	b4004d40 	cbz	x0, 0xffffff8008087b34
ffffff8008087190:	d0006123 	adrp	x3, 0xffffff8008cad000
ffffff8008087194:	92c00802 	movn	x2, #0x40, lsl #32
ffffff8008087198:	91054061 	add	x1, x3, #0x150
ffffff800808719c:	8b000000 	add	x0, x0, x0
ffffff80080871a0:	eb02003f 	subs	xzr, x1, x2
ffffff80080871a4:	b0009682 	adrp	x2, 0xffffff8009358000
ffffff80080871a8:	f9402442 	ldr	x2, [x2, #72]
ffffff80080871ac:	8b020000 	add	x0, x0, x2
ffffff80080871b0:	91001014 	add	x20, x0, #0x4
ffffff80080871b4:	91002013 	add	x19, x0, #0x8
ffffff80080871b8:	54001728 	b.hi	0xffffff800808749c  // b.pmore
ffffff80080871bc:	90007822 	adrp	x2, 0xffffff8008f8b000
ffffff80080871c0:	f9426445 	ldr	x5, [x2, #1224]
ffffff80080871c4:	4b050025 	sub	w5, w1, w5
ffffff80080871c8:	12003ca5 	and	w5, w5, #0xffff
ffffff80080871cc:	b9000005 	str	w5, [x0]
ffffff80080871d0:	92c00802 	movn	x2, #0x40, lsl #32
ffffff80080871d4:	eb02003f 	subs	xzr, x1, x2
ffffff80080871d8:	54002e49 	b.ls	0xffffff80080877a0  // b.plast
ffffff80080871dc:	d0008aa2 	adrp	x2, 0xffffff80091dd000
ffffff80080871e0:	d0008aa6 	adrp	x6, 0xffffff80091dd000
ffffff80080871e4:	f9401048 	ldr	x8, [x2, #32]
ffffff80080871e8:	b100051f 	adds	xzr, x8, #0x1
ffffff80080871ec:	54003ac0 	b.eq	0xffffff8008087944  // b.none
ffffff80080871f0:	f94004c5 	ldr	x5, [x6, #8]
ffffff80080871f4:	92405103 	and	x3, x8, #0x1fffff
ffffff80080871f8:	b25a67e4 	orr	x4, xzr, #0xffffffc000000000
ffffff80080871fc:	924050a2 	and	x2, x5, #0x1fffff
ffffff8008087200:	8b0400a5 	add	x5, x5, x4
ffffff8008087204:	8b030043 	add	x3, x2, x3
ffffff8008087208:	9147fc62 	add	x2, x3, #0x1ff, lsl #12
ffffff800808720c:	cb0300a3 	sub	x3, x5, x3
ffffff8008087210:	913ffc42 	add	x2, x2, #0xfff
ffffff8008087214:	926ba842 	and	x2, x2, #0xffffffffffe00000
ffffff8008087218:	8b020062 	add	x2, x3, x2
ffffff800808721c:	eb02003f 	subs	xzr, x1, x2
ffffff8008087220:	1a9f37e2 	csinc	w2, wzr, wzr, cc  // cc = lo, ul, last
ffffff8008087224:	34002f02 	cbz	w2, 0xffffff8008087804
ffffff8008087228:	d0008aa2 	adrp	x2, 0xffffff80091dd000
ffffff800808722c:	f9401849 	ldr	x9, [x2, #48]
ffffff8008087230:	b100053f 	adds	xzr, x9, #0x1
ffffff8008087234:	54002f20 	b.eq	0xffffff8008087818  // b.none
ffffff8008087238:	b100051f 	adds	xzr, x8, #0x1
ffffff800808723c:	d0008aac 	adrp	x12, 0xffffff80091dd000
ffffff8008087240:	f94004ca 	ldr	x10, [x6, #8]
ffffff8008087244:	54003f60 	b.eq	0xffffff8008087a30  // b.none
ffffff8008087248:	92405144 	and	x4, x10, #0x1fffff
ffffff800808724c:	f9401583 	ldr	x3, [x12, #40]
ffffff8008087250:	92405102 	and	x2, x8, #0x1fffff
ffffff8008087254:	9240512b 	and	x11, x9, #0x1fffff
ffffff8008087258:	8b020082 	add	x2, x4, x2
ffffff800808725c:	8b030144 	add	x4, x10, x3
ffffff8008087260:	9147fc46 	add	x6, x2, #0x1ff, lsl #12
ffffff8008087264:	b25a67e3 	orr	x3, xzr, #0xffffffc000000000
ffffff8008087268:	8b030083 	add	x3, x4, x3
ffffff800808726c:	913ffcc6 	add	x6, x6, #0xfff
ffffff8008087270:	cb020062 	sub	x2, x3, x2
ffffff8008087274:	926ba8c6 	and	x6, x6, #0xffffffffffe00000
ffffff8008087278:	9147fd65 	add	x5, x11, #0x1ff, lsl #12
ffffff800808727c:	8b060044 	add	x4, x2, x6
ffffff8008087280:	913ffca5 	add	x5, x5, #0xfff
ffffff8008087284:	92405082 	and	x2, x4, #0x1fffff
ffffff8008087288:	8b0200a5 	add	x5, x5, x2
ffffff800808728c:	926ba8a5 	and	x5, x5, #0xffffffffffe00000
ffffff8008087290:	8b0400a5 	add	x5, x5, x4
ffffff8008087294:	cb0b00a4 	sub	x4, x5, x11
ffffff8008087298:	cb020084 	sub	x4, x4, x2
ffffff800808729c:	eb04003f 	subs	xzr, x1, x4
ffffff80080872a0:	1a9f37e2 	csinc	w2, wzr, wzr, cc  // cc = lo, ul, last
ffffff80080872a4:	34002e02 	cbz	w2, 0xffffff8008087864
ffffff80080872a8:	d0008aa2 	adrp	x2, 0xffffff80091dd000
ffffff80080872ac:	f9402043 	ldr	x3, [x2, #64]
ffffff80080872b0:	b100047f 	adds	xzr, x3, #0x1
ffffff80080872b4:	54004440 	b.eq	0xffffff8008087b3c  // b.none
ffffff80080872b8:	b100053f 	adds	xzr, x9, #0x1
ffffff80080872bc:	54005280 	b.eq	0xffffff8008087d0c  // b.none
ffffff80080872c0:	b100051f 	adds	xzr, x8, #0x1
ffffff80080872c4:	54003580 	b.eq	0xffffff8008087974  // b.none
ffffff80080872c8:	f940158f 	ldr	x15, [x12, #40]
ffffff80080872cc:	b25a67e5 	orr	x5, xzr, #0xffffffc000000000
ffffff80080872d0:	92405102 	and	x2, x8, #0x1fffff
ffffff80080872d4:	9240514e 	and	x14, x10, #0x1fffff
ffffff80080872d8:	8b0501e5 	add	x5, x15, x5
ffffff80080872dc:	8b0201ce 	add	x14, x14, x2
ffffff80080872e0:	8b0a00a5 	add	x5, x5, x10
ffffff80080872e4:	9147fdc2 	add	x2, x14, #0x1ff, lsl #12
ffffff80080872e8:	cb0e00ae 	sub	x14, x5, x14
ffffff80080872ec:	d0008aa5 	adrp	x5, 0xffffff80091dd000
ffffff80080872f0:	913ffc42 	add	x2, x2, #0xfff
ffffff80080872f4:	92405124 	and	x4, x9, #0x1fffff
ffffff80080872f8:	926ba842 	and	x2, x2, #0xffffffffffe00000
ffffff80080872fc:	9147fc8d 	add	x13, x4, #0x1ff, lsl #12
ffffff8008087300:	f9401cb0 	ldr	x16, [x5, #56]
ffffff8008087304:	8b0201c2 	add	x2, x14, x2
ffffff8008087308:	92405052 	and	x18, x2, #0x1fffff
ffffff800808730c:	913ffdad 	add	x13, x13, #0xfff
ffffff8008087310:	cb040211 	sub	x17, x16, x4
ffffff8008087314:	8b0d024b 	add	x11, x18, x13
ffffff8008087318:	8b020231 	add	x17, x17, x2
ffffff800808731c:	926ba96b 	and	x11, x11, #0xffffffffffe00000
ffffff8008087320:	cb120231 	sub	x17, x17, x18
ffffff8008087324:	92405065 	and	x5, x3, #0x1fffff
ffffff8008087328:	8b0b0231 	add	x17, x17, x11
ffffff800808732c:	8b100042 	add	x2, x2, x16
ffffff8008087330:	9147fca6 	add	x6, x5, #0x1ff, lsl #12
ffffff8008087334:	8b0b004e 	add	x14, x2, x11
ffffff8008087338:	b100051f 	adds	xzr, x8, #0x1
ffffff800808733c:	cb0401ce 	sub	x14, x14, x4
ffffff8008087340:	913ffccb 	add	x11, x6, #0xfff
ffffff8008087344:	cb1201ce 	sub	x14, x14, x18
ffffff8008087348:	924051ce 	and	x14, x14, #0x1fffff
ffffff800808734c:	8b0e016b 	add	x11, x11, x14
ffffff8008087350:	926ba972 	and	x18, x11, #0xffffffffffe00000
ffffff8008087354:	54005820 	b.eq	0xffffff8008087e58  // b.none
ffffff8008087358:	9240510b 	and	x11, x8, #0x1fffff
ffffff800808735c:	9240514c 	and	x12, x10, #0x1fffff
ffffff8008087360:	8b0b018c 	add	x12, x12, x11
ffffff8008087364:	b25a67e2 	orr	x2, xzr, #0xffffffc000000000
ffffff8008087368:	9147fd8e 	add	x14, x12, #0x1ff, lsl #12
ffffff800808736c:	8b020142 	add	x2, x10, x2
ffffff8008087370:	913ffdce 	add	x14, x14, #0xfff
ffffff8008087374:	cb0c004c 	sub	x12, x2, x12
ffffff8008087378:	926ba9c2 	and	x2, x14, #0xffffffffffe00000
ffffff800808737c:	8b02018c 	add	x12, x12, x2
ffffff8008087380:	8b0f0182 	add	x2, x12, x15
ffffff8008087384:	9240504b 	and	x11, x2, #0x1fffff
ffffff8008087388:	8b0d016d 	add	x13, x11, x13
ffffff800808738c:	926ba9ac 	and	x12, x13, #0xffffffffffe00000
ffffff8008087390:	8b0c004c 	add	x12, x2, x12
ffffff8008087394:	8b120231 	add	x17, x17, x18
ffffff8008087398:	cb04018c 	sub	x12, x12, x4
ffffff800808739c:	cb050231 	sub	x17, x17, x5
ffffff80080873a0:	cb0b018b 	sub	x11, x12, x11
ffffff80080873a4:	8b0b020b 	add	x11, x16, x11
ffffff80080873a8:	9240516b 	and	x11, x11, #0x1fffff
ffffff80080873ac:	cb0b022b 	sub	x11, x17, x11
ffffff80080873b0:	eb0b003f 	subs	xzr, x1, x11
ffffff80080873b4:	54003543 	b.cc	0xffffff8008087a5c  // b.lo, b.ul, b.last
ffffff80080873b8:	b100051f 	adds	xzr, x8, #0x1
ffffff80080873bc:	54006920 	b.eq	0xffffff80080880e0  // b.none
ffffff80080873c0:	9240514b 	and	x11, x10, #0x1fffff
ffffff80080873c4:	92405102 	and	x2, x8, #0x1fffff
ffffff80080873c8:	8b02016c 	add	x12, x11, x2
ffffff80080873cc:	b25a67eb 	orr	x11, xzr, #0xffffffc000000000
ffffff80080873d0:	9147fd82 	add	x2, x12, #0x1ff, lsl #12
ffffff80080873d4:	8b0b0149 	add	x9, x10, x11
ffffff80080873d8:	913ffc42 	add	x2, x2, #0xfff
ffffff80080873dc:	cb0c012b 	sub	x11, x9, x12
ffffff80080873e0:	926ba849 	and	x9, x2, #0xffffffffffe00000
ffffff80080873e4:	cb040202 	sub	x2, x16, x4
ffffff80080873e8:	8b090169 	add	x9, x11, x9
ffffff80080873ec:	8b0f0129 	add	x9, x9, x15
ffffff80080873f0:	9147fc8c 	add	x12, x4, #0x1ff, lsl #12
ffffff80080873f4:	9240512d 	and	x13, x9, #0x1fffff
ffffff80080873f8:	913ffd8c 	add	x12, x12, #0xfff
ffffff80080873fc:	8b0c01ab 	add	x11, x13, x12
ffffff8008087400:	8b090042 	add	x2, x2, x9
ffffff8008087404:	926ba96b 	and	x11, x11, #0xffffffffffe00000
ffffff8008087408:	cb0d0042 	sub	x2, x2, x13
ffffff800808740c:	8b0b0129 	add	x9, x9, x11
ffffff8008087410:	92405042 	and	x2, x2, #0x1fffff
ffffff8008087414:	8b090209 	add	x9, x16, x9
ffffff8008087418:	8b0200a5 	add	x5, x5, x2
ffffff800808741c:	cb040129 	sub	x9, x9, x4
ffffff8008087420:	913ffcc2 	add	x2, x6, #0xfff
ffffff8008087424:	cb0d0129 	sub	x9, x9, x13
ffffff8008087428:	b100051f 	adds	xzr, x8, #0x1
ffffff800808742c:	92405129 	and	x9, x9, #0x1fffff
ffffff8008087430:	8b090042 	add	x2, x2, x9
ffffff8008087434:	926ba842 	and	x2, x2, #0xffffffffffe00000
ffffff8008087438:	cb0200a2 	sub	x2, x5, x2
ffffff800808743c:	54006440 	b.eq	0xffffff80080880c4  // b.none
ffffff8008087440:	92405146 	and	x6, x10, #0x1fffff
ffffff8008087444:	92405108 	and	x8, x8, #0x1fffff
ffffff8008087448:	8b0800c6 	add	x6, x6, x8
ffffff800808744c:	b25a67e9 	orr	x9, xzr, #0xffffffc000000000
ffffff8008087450:	9147fcc5 	add	x5, x6, #0x1ff, lsl #12
ffffff8008087454:	8b09014a 	add	x10, x10, x9
ffffff8008087458:	913ffca5 	add	x5, x5, #0xfff
ffffff800808745c:	cb060146 	sub	x6, x10, x6
ffffff8008087460:	926ba8a5 	and	x5, x5, #0xffffffffffe00000
ffffff8008087464:	8b0500c6 	add	x6, x6, x5
ffffff8008087468:	8b0f00cf 	add	x15, x6, x15
ffffff800808746c:	924051e5 	and	x5, x15, #0x1fffff
ffffff8008087470:	8b050188 	add	x8, x12, x5
ffffff8008087474:	926ba908 	and	x8, x8, #0xffffffffffe00000
ffffff8008087478:	8b0801e6 	add	x6, x15, x8
ffffff800808747c:	cb0400c4 	sub	x4, x6, x4
ffffff8008087480:	cb050086 	sub	x6, x4, x5
ffffff8008087484:	cb100021 	sub	x1, x1, x16
ffffff8008087488:	8b020021 	add	x1, x1, x2
ffffff800808748c:	cb060021 	sub	x1, x1, x6
ffffff8008087490:	8b030021 	add	x1, x1, x3
ffffff8008087494:	d350fc21 	ubfm	x1, x1, #16, #63
ffffff8008087498:	140000c6 	b	0xffffff80080877b0
ffffff800808749c:	d0008aa2 	adrp	x2, 0xffffff80091dd000
ffffff80080874a0:	d0008aa6 	adrp	x6, 0xffffff80091dd000
ffffff80080874a4:	f9401044 	ldr	x4, [x2, #32]
ffffff80080874a8:	b100049f 	adds	xzr, x4, #0x1
ffffff80080874ac:	54002400 	b.eq	0xffffff800808792c  // b.none
ffffff80080874b0:	f94004c9 	ldr	x9, [x6, #8]
ffffff80080874b4:	92405082 	and	x2, x4, #0x1fffff
ffffff80080874b8:	b25a67e5 	orr	x5, xzr, #0xffffffc000000000
ffffff80080874bc:	92405128 	and	x8, x9, #0x1fffff
ffffff80080874c0:	8b050129 	add	x9, x9, x5
ffffff80080874c4:	8b020102 	add	x2, x8, x2
ffffff80080874c8:	9147fc48 	add	x8, x2, #0x1ff, lsl #12
ffffff80080874cc:	cb020122 	sub	x2, x9, x2
ffffff80080874d0:	913ffd08 	add	x8, x8, #0xfff
ffffff80080874d4:	926ba908 	and	x8, x8, #0xffffffffffe00000
ffffff80080874d8:	8b080048 	add	x8, x2, x8
ffffff80080874dc:	eb08003f 	subs	xzr, x1, x8
ffffff80080874e0:	1a9f37e2 	csinc	w2, wzr, wzr, cc  // cc = lo, ul, last
ffffff80080874e4:	340018a2 	cbz	w2, 0xffffff80080877f8
ffffff80080874e8:	d0008aa2 	adrp	x2, 0xffffff80091dd000
ffffff80080874ec:	f940184b 	ldr	x11, [x2, #48]
ffffff80080874f0:	b100057f 	adds	xzr, x11, #0x1
ffffff80080874f4:	54001d80 	b.eq	0xffffff80080878a4  // b.none
ffffff80080874f8:	b100049f 	adds	xzr, x4, #0x1
ffffff80080874fc:	d0008aac 	adrp	x12, 0xffffff80091dd000
ffffff8008087500:	f94004ca 	ldr	x10, [x6, #8]
ffffff8008087504:	54002800 	b.eq	0xffffff8008087a04  // b.none
ffffff8008087508:	92405142 	and	x2, x10, #0x1fffff
ffffff800808750c:	f9401586 	ldr	x6, [x12, #40]
ffffff8008087510:	92405085 	and	x5, x4, #0x1fffff
ffffff8008087514:	9240516d 	and	x13, x11, #0x1fffff
ffffff8008087518:	8b050045 	add	x5, x2, x5
ffffff800808751c:	8b060142 	add	x2, x10, x6
ffffff8008087520:	9147fca9 	add	x9, x5, #0x1ff, lsl #12
ffffff8008087524:	b25a67e6 	orr	x6, xzr, #0xffffffc000000000
ffffff8008087528:	8b060046 	add	x6, x2, x6
ffffff800808752c:	913ffd29 	add	x9, x9, #0xfff
ffffff8008087530:	cb0500c5 	sub	x5, x6, x5
ffffff8008087534:	926ba929 	and	x9, x9, #0xffffffffffe00000
ffffff8008087538:	9147fda8 	add	x8, x13, #0x1ff, lsl #12
ffffff800808753c:	8b0900a2 	add	x2, x5, x9
ffffff8008087540:	913ffd08 	add	x8, x8, #0xfff
ffffff8008087544:	92405045 	and	x5, x2, #0x1fffff
ffffff8008087548:	8b050108 	add	x8, x8, x5
ffffff800808754c:	926ba908 	and	x8, x8, #0xffffffffffe00000
ffffff8008087550:	8b020108 	add	x8, x8, x2
ffffff8008087554:	cb0d0102 	sub	x2, x8, x13
ffffff8008087558:	cb050042 	sub	x2, x2, x5
ffffff800808755c:	eb02003f 	subs	xzr, x1, x2
ffffff8008087560:	1a9f37e2 	csinc	w2, wzr, wzr, cc  // cc = lo, ul, last
ffffff8008087564:	34001c62 	cbz	w2, 0xffffff80080878f0
