
hal_hdmi.bin:     file format binary


Disassembly of section .data:

ffffff80013c2238 <.data>:
ffffff80013c2238:	a9bd7bfd 	stp	x29, x30, [sp, #-48]!
ffffff80013c223c:	910003fd 	add	x29, sp, #0x0
ffffff80013c2240:	a90153f3 	stp	x19, x20, [sp, #16]
ffffff80013c2244:	53001c03 	ubfm	w3, w0, #0, #7
ffffff80013c2248:	aa1e03e0 	orr	x0, xzr, x30
ffffff80013c224c:	b9002fa3 	str	w3, [x29, #44]
ffffff80013c2250:	52800a14 	movz	w20, #0x50
ffffff80013c2254:	d503201f 	hint	#0x0
ffffff80013c2258:	580021c1 	ldr	x1, 0xffffff80013c2690
ffffff80013c225c:	528647e2 	movz	w2, #0x323f
ffffff80013c2260:	580021c0 	ldr	x0, 0xffffff80013c2698
ffffff80013c2264:	b9402fa3 	ldr	w3, [x29, #44]
ffffff80013c2268:	91016021 	add	x1, x1, #0x58
ffffff80013c226c:	95b8b173 	bl	0xffffff80081ee838
ffffff80013c2270:	58002193 	ldr	x19, 0xffffff80013c26a0
ffffff80013c2274:	52814002 	movz	w2, #0xa00
ffffff80013c2278:	f9400260 	ldr	x0, [x19]
ffffff80013c227c:	914b9c00 	add	x0, x0, #0x2e7, lsl #12
ffffff80013c2280:	7904101f 	strh	wzr, [x0, #520]
ffffff80013c2284:	f9400260 	ldr	x0, [x19]
ffffff80013c2288:	914b9c00 	add	x0, x0, #0x2e7, lsl #12
ffffff80013c228c:	79441801 	ldrh	w1, [x0, #524]
ffffff80013c2290:	12181c21 	and	w1, w1, #0xff00
ffffff80013c2294:	79041801 	strh	w1, [x0, #524]
ffffff80013c2298:	f9400260 	ldr	x0, [x19]
ffffff80013c229c:	914b9c00 	add	x0, x0, #0x2e7, lsl #12
ffffff80013c22a0:	7904801f 	strh	wzr, [x0, #576]
ffffff80013c22a4:	f9400260 	ldr	x0, [x19]
ffffff80013c22a8:	914b9c00 	add	x0, x0, #0x2e7, lsl #12
ffffff80013c22ac:	7904881f 	strh	wzr, [x0, #580]
ffffff80013c22b0:	f9400260 	ldr	x0, [x19]
ffffff80013c22b4:	914b9c00 	add	x0, x0, #0x2e7, lsl #12
ffffff80013c22b8:	79449801 	ldrh	w1, [x0, #588]
ffffff80013c22bc:	12181c21 	and	w1, w1, #0xff00
ffffff80013c22c0:	79049801 	strh	w1, [x0, #588]
ffffff80013c22c4:	f9400260 	ldr	x0, [x19]
ffffff80013c22c8:	914b9c00 	add	x0, x0, #0x2e7, lsl #12
ffffff80013c22cc:	7904c01f 	strh	wzr, [x0, #608]
ffffff80013c22d0:	f9400260 	ldr	x0, [x19]
ffffff80013c22d4:	914b9c00 	add	x0, x0, #0x2e7, lsl #12
ffffff80013c22d8:	7904c81f 	strh	wzr, [x0, #612]
ffffff80013c22dc:	f9400260 	ldr	x0, [x19]
ffffff80013c22e0:	914b9c00 	add	x0, x0, #0x2e7, lsl #12
ffffff80013c22e4:	7944d801 	ldrh	w1, [x0, #620]
ffffff80013c22e8:	12181c21 	and	w1, w1, #0xff00
ffffff80013c22ec:	7904d801 	strh	w1, [x0, #620]
ffffff80013c22f0:	f9400260 	ldr	x0, [x19]
ffffff80013c22f4:	914b9c00 	add	x0, x0, #0x2e7, lsl #12
ffffff80013c22f8:	7905001f 	strh	wzr, [x0, #640]
ffffff80013c22fc:	f9400260 	ldr	x0, [x19]
ffffff80013c2300:	914b9c00 	add	x0, x0, #0x2e7, lsl #12
ffffff80013c2304:	7905081f 	strh	wzr, [x0, #644]
ffffff80013c2308:	f9400260 	ldr	x0, [x19]
ffffff80013c230c:	914b9c00 	add	x0, x0, #0x2e7, lsl #12
ffffff80013c2310:	79451801 	ldrh	w1, [x0, #652]
ffffff80013c2314:	12181c21 	and	w1, w1, #0xff00
ffffff80013c2318:	79051801 	strh	w1, [x0, #652]
ffffff80013c231c:	f9400260 	ldr	x0, [x19]
ffffff80013c2320:	914b9c00 	add	x0, x0, #0x2e7, lsl #12
ffffff80013c2324:	7905401f 	strh	wzr, [x0, #672]
ffffff80013c2328:	f9400260 	ldr	x0, [x19]
ffffff80013c232c:	914b9c00 	add	x0, x0, #0x2e7, lsl #12
ffffff80013c2330:	7905481f 	strh	wzr, [x0, #676]
ffffff80013c2334:	f9400260 	ldr	x0, [x19]
ffffff80013c2338:	914b9c00 	add	x0, x0, #0x2e7, lsl #12
ffffff80013c233c:	79455801 	ldrh	w1, [x0, #684]
ffffff80013c2340:	12181c21 	and	w1, w1, #0xff00
ffffff80013c2344:	79055801 	strh	w1, [x0, #684]
ffffff80013c2348:	f9400261 	ldr	x1, [x19]
ffffff80013c234c:	914b9c21 	add	x1, x1, #0x2e7, lsl #12
ffffff80013c2350:	7946a020 	ldrh	w0, [x1, #848]
ffffff80013c2354:	53003c00 	ubfm	w0, w0, #0, #15
ffffff80013c2358:	12146c00 	and	w0, w0, #0xfffff0ff
ffffff80013c235c:	2a020000 	orr	w0, w0, w2
ffffff80013c2360:	7906a020 	strh	w0, [x1, #848]
ffffff80013c2364:	529ff7e1 	movz	w1, #0xffbf
ffffff80013c2368:	f9400260 	ldr	x0, [x19]
ffffff80013c236c:	914b9c00 	add	x0, x0, #0x2e7, lsl #12
ffffff80013c2370:	79464802 	ldrh	w2, [x0, #804]
ffffff80013c2374:	0a010041 	and	w1, w2, w1
ffffff80013c2378:	79064801 	strh	w1, [x0, #804]
ffffff80013c237c:	f9400261 	ldr	x1, [x19]
ffffff80013c2380:	914b9c21 	add	x1, x1, #0x2e7, lsl #12
ffffff80013c2384:	79464820 	ldrh	w0, [x1, #804]
ffffff80013c2388:	53003c00 	ubfm	w0, w0, #0, #15
ffffff80013c238c:	32140000 	orr	w0, w0, #0x1000
ffffff80013c2390:	79064820 	strh	w0, [x1, #804]
ffffff80013c2394:	529dffe1 	movz	w1, #0xefff
ffffff80013c2398:	f9400260 	ldr	x0, [x19]
ffffff80013c239c:	914b9c00 	add	x0, x0, #0x2e7, lsl #12
ffffff80013c23a0:	79464802 	ldrh	w2, [x0, #804]
ffffff80013c23a4:	0a010041 	and	w1, w2, w1
ffffff80013c23a8:	79064801 	strh	w1, [x0, #804]
ffffff80013c23ac:	f9400261 	ldr	x1, [x19]
ffffff80013c23b0:	914b9c21 	add	x1, x1, #0x2e7, lsl #12
ffffff80013c23b4:	79464020 	ldrh	w0, [x1, #800]
ffffff80013c23b8:	32124400 	orr	w0, w0, #0xffffc000
ffffff80013c23bc:	53003c00 	ubfm	w0, w0, #0, #15
ffffff80013c23c0:	79064020 	strh	w0, [x1, #800]
ffffff80013c23c4:	f9400261 	ldr	x1, [x19]
ffffff80013c23c8:	914b9c21 	add	x1, x1, #0x2e7, lsl #12
ffffff80013c23cc:	79465820 	ldrh	w0, [x1, #812]
ffffff80013c23d0:	53003c00 	ubfm	w0, w0, #0, #15
ffffff80013c23d4:	321c0400 	orr	w0, w0, #0x30
ffffff80013c23d8:	79065820 	strh	w0, [x1, #812]
ffffff80013c23dc:	f9400260 	ldr	x0, [x19]
ffffff80013c23e0:	914b9c00 	add	x0, x0, #0x2e7, lsl #12
ffffff80013c23e4:	79462001 	ldrh	w1, [x0, #784]
ffffff80013c23e8:	53003c22 	ubfm	w2, w1, #0, #15
ffffff80013c23ec:	52801021 	movz	w1, #0x81
ffffff80013c23f0:	2a010041 	orr	w1, w2, w1
ffffff80013c23f4:	79062001 	strh	w1, [x0, #784]
ffffff80013c23f8:	f9400261 	ldr	x1, [x19]
ffffff80013c23fc:	914b9c21 	add	x1, x1, #0x2e7, lsl #12
ffffff80013c2400:	7945c020 	ldrh	w0, [x1, #736]
ffffff80013c2404:	53003c00 	ubfm	w0, w0, #0, #15
ffffff80013c2408:	32000000 	orr	w0, w0, #0x1
ffffff80013c240c:	7905c020 	strh	w0, [x1, #736]
ffffff80013c2410:	f9400261 	ldr	x1, [x19]
ffffff80013c2414:	914b9c21 	add	x1, x1, #0x2e7, lsl #12
ffffff80013c2418:	79464820 	ldrh	w0, [x1, #804]
ffffff80013c241c:	32124400 	orr	w0, w0, #0xffffc000
ffffff80013c2420:	53003c00 	ubfm	w0, w0, #0, #15
ffffff80013c2424:	79064820 	strh	w0, [x1, #804]
ffffff80013c2428:	f9400260 	ldr	x0, [x19]
ffffff80013c242c:	914b9c00 	add	x0, x0, #0x2e7, lsl #12
ffffff80013c2430:	79465801 	ldrh	w1, [x0, #812]
ffffff80013c2434:	12003821 	and	w1, w1, #0x7fff
ffffff80013c2438:	79065801 	strh	w1, [x0, #812]
ffffff80013c243c:	f9400261 	ldr	x1, [x19]
ffffff80013c2440:	91489421 	add	x1, x1, #0x225, lsl #12
ffffff80013c2444:	7940d020 	ldrh	w0, [x1, #104]
ffffff80013c2448:	53003c00 	ubfm	w0, w0, #0, #15
ffffff80013c244c:	321c0000 	orr	w0, w0, #0x10
ffffff80013c2450:	7900d020 	strh	w0, [x1, #104]
ffffff80013c2454:	f9400261 	ldr	x1, [x19]
ffffff80013c2458:	91489421 	add	x1, x1, #0x225, lsl #12
ffffff80013c245c:	79423820 	ldrh	w0, [x1, #284]
ffffff80013c2460:	53003c00 	ubfm	w0, w0, #0, #15
ffffff80013c2464:	32180000 	orr	w0, w0, #0x100
ffffff80013c2468:	79023820 	strh	w0, [x1, #284]
ffffff80013c246c:	f9400261 	ldr	x1, [x19]
ffffff80013c2470:	914b9c21 	add	x1, x1, #0x2e7, lsl #12
ffffff80013c2474:	7944a820 	ldrh	w0, [x1, #596]
ffffff80013c2478:	53003c00 	ubfm	w0, w0, #0, #15
ffffff80013c247c:	32130000 	orr	w0, w0, #0x2000
ffffff80013c2480:	7904a820 	strh	w0, [x1, #596]
ffffff80013c2484:	f9400261 	ldr	x1, [x19]
ffffff80013c2488:	914b9c21 	add	x1, x1, #0x2e7, lsl #12
ffffff80013c248c:	7944e820 	ldrh	w0, [x1, #628]
ffffff80013c2490:	53003c00 	ubfm	w0, w0, #0, #15
ffffff80013c2494:	32130000 	orr	w0, w0, #0x2000
ffffff80013c2498:	7904e820 	strh	w0, [x1, #628]
ffffff80013c249c:	f9400261 	ldr	x1, [x19]
ffffff80013c24a0:	914b9c21 	add	x1, x1, #0x2e7, lsl #12
ffffff80013c24a4:	79452820 	ldrh	w0, [x1, #660]
ffffff80013c24a8:	53003c00 	ubfm	w0, w0, #0, #15
ffffff80013c24ac:	32130000 	orr	w0, w0, #0x2000
ffffff80013c24b0:	79052820 	strh	w0, [x1, #660]
ffffff80013c24b4:	f9400261 	ldr	x1, [x19]
ffffff80013c24b8:	914b9c21 	add	x1, x1, #0x2e7, lsl #12
ffffff80013c24bc:	79456820 	ldrh	w0, [x1, #692]
ffffff80013c24c0:	53003c00 	ubfm	w0, w0, #0, #15
ffffff80013c24c4:	32130000 	orr	w0, w0, #0x2000
ffffff80013c24c8:	79056820 	strh	w0, [x1, #692]
ffffff80013c24cc:	f9400261 	ldr	x1, [x19]
ffffff80013c24d0:	914b9c21 	add	x1, x1, #0x2e7, lsl #12
ffffff80013c24d4:	7944a020 	ldrh	w0, [x1, #592]
ffffff80013c24d8:	53003c00 	ubfm	w0, w0, #0, #15
ffffff80013c24dc:	32190000 	orr	w0, w0, #0x80
ffffff80013c24e0:	7904a020 	strh	w0, [x1, #592]
ffffff80013c24e4:	f9400261 	ldr	x1, [x19]
ffffff80013c24e8:	914b9c21 	add	x1, x1, #0x2e7, lsl #12
ffffff80013c24ec:	7944e020 	ldrh	w0, [x1, #624]
ffffff80013c24f0:	53003c00 	ubfm	w0, w0, #0, #15
ffffff80013c24f4:	32190000 	orr	w0, w0, #0x80
ffffff80013c24f8:	7904e020 	strh	w0, [x1, #624]
ffffff80013c24fc:	f9400261 	ldr	x1, [x19]
ffffff80013c2500:	914b9c21 	add	x1, x1, #0x2e7, lsl #12
ffffff80013c2504:	79452020 	ldrh	w0, [x1, #656]
ffffff80013c2508:	53003c00 	ubfm	w0, w0, #0, #15
ffffff80013c250c:	32190000 	orr	w0, w0, #0x80
ffffff80013c2510:	79052020 	strh	w0, [x1, #656]
ffffff80013c2514:	f9400261 	ldr	x1, [x19]
ffffff80013c2518:	914b9c21 	add	x1, x1, #0x2e7, lsl #12
ffffff80013c251c:	79456020 	ldrh	w0, [x1, #688]
ffffff80013c2520:	53003c00 	ubfm	w0, w0, #0, #15
ffffff80013c2524:	32190000 	orr	w0, w0, #0x80
ffffff80013c2528:	79056020 	strh	w0, [x1, #688]
ffffff80013c252c:	529ff9e1 	movz	w1, #0xffcf
ffffff80013c2530:	f9400260 	ldr	x0, [x19]
ffffff80013c2534:	914b9c00 	add	x0, x0, #0x2e7, lsl #12
ffffff80013c2538:	7944a002 	ldrh	w2, [x0, #592]
ffffff80013c253c:	0a010041 	and	w1, w2, w1
ffffff80013c2540:	7904a001 	strh	w1, [x0, #592]
ffffff80013c2544:	529ff9e1 	movz	w1, #0xffcf
ffffff80013c2548:	f9400260 	ldr	x0, [x19]
ffffff80013c254c:	914b9c00 	add	x0, x0, #0x2e7, lsl #12
ffffff80013c2550:	7944e002 	ldrh	w2, [x0, #624]
ffffff80013c2554:	0a010041 	and	w1, w2, w1
ffffff80013c2558:	7904e001 	strh	w1, [x0, #624]
ffffff80013c255c:	529ff9e1 	movz	w1, #0xffcf
ffffff80013c2560:	f9400260 	ldr	x0, [x19]
ffffff80013c2564:	914b9c00 	add	x0, x0, #0x2e7, lsl #12
ffffff80013c2568:	79452002 	ldrh	w2, [x0, #656]
ffffff80013c256c:	0a010041 	and	w1, w2, w1
ffffff80013c2570:	79052001 	strh	w1, [x0, #656]
ffffff80013c2574:	529ff9e1 	movz	w1, #0xffcf
ffffff80013c2578:	f9400260 	ldr	x0, [x19]
ffffff80013c257c:	914b9c00 	add	x0, x0, #0x2e7, lsl #12
ffffff80013c2580:	79456002 	ldrh	w2, [x0, #688]
ffffff80013c2584:	0a010041 	and	w1, w2, w1
ffffff80013c2588:	79056001 	strh	w1, [x0, #688]
ffffff80013c258c:	51014a81 	sub	w1, w20, #0x52
ffffff80013c2590:	2a1403e0 	orr	w0, wzr, w20
ffffff80013c2594:	7100043f 	subs	wzr, w1, #0x1
ffffff80013c2598:	540006e9 	b.ls	0xffffff80013c2674  // b.plast
ffffff80013c259c:	97ffb5b9 	bl	0xffffff80013afc80
ffffff80013c25a0:	2a1403e0 	orr	w0, wzr, w20
ffffff80013c25a4:	97ffc025 	bl	0xffffff80013b2638
ffffff80013c25a8:	11000694 	add	w20, w20, #0x1
ffffff80013c25ac:	7101529f 	subs	wzr, w20, #0x54
ffffff80013c25b0:	54fffee1 	b.ne	0xffffff80013c258c  // b.any
ffffff80013c25b4:	52800000 	movz	w0, #0x0
ffffff80013c25b8:	97ffc110 	bl	0xffffff80013b29f8
ffffff80013c25bc:	52800020 	movz	w0, #0x1
ffffff80013c25c0:	97ffc10e 	bl	0xffffff80013b29f8
ffffff80013c25c4:	52800040 	movz	w0, #0x2
ffffff80013c25c8:	97ffc10c 	bl	0xffffff80013b29f8
ffffff80013c25cc:	52800060 	movz	w0, #0x3
ffffff80013c25d0:	97ffc10a 	bl	0xffffff80013b29f8
ffffff80013c25d4:	f9400261 	ldr	x1, [x19]
ffffff80013c25d8:	914b9c21 	add	x1, x1, #0x2e7, lsl #12
ffffff80013c25dc:	79465020 	ldrh	w0, [x1, #808]
ffffff80013c25e0:	53003c00 	ubfm	w0, w0, #0, #15
ffffff80013c25e4:	121d7800 	and	w0, w0, #0xfffffffb
ffffff80013c25e8:	321e0000 	orr	w0, w0, #0x4
ffffff80013c25ec:	79065020 	strh	w0, [x1, #808]
ffffff80013c25f0:	529ff7e1 	movz	w1, #0xffbf
ffffff80013c25f4:	f9400260 	ldr	x0, [x19]
ffffff80013c25f8:	914b9c00 	add	x0, x0, #0x2e7, lsl #12
ffffff80013c25fc:	79466802 	ldrh	w2, [x0, #820]
ffffff80013c2600:	0a010041 	and	w1, w2, w1
ffffff80013c2604:	79066801 	strh	w1, [x0, #820]
ffffff80013c2608:	529ff7e1 	movz	w1, #0xffbf
ffffff80013c260c:	f9400260 	ldr	x0, [x19]
ffffff80013c2610:	914b9c00 	add	x0, x0, #0x2e7, lsl #12
ffffff80013c2614:	79440802 	ldrh	w2, [x0, #516]
ffffff80013c2618:	0a010041 	and	w1, w2, w1
ffffff80013c261c:	79040801 	strh	w1, [x0, #516]
ffffff80013c2620:	f9400261 	ldr	x1, [x19]
ffffff80013c2624:	914b9c21 	add	x1, x1, #0x2e7, lsl #12
ffffff80013c2628:	79440820 	ldrh	w0, [x1, #516]
ffffff80013c262c:	12002c00 	and	w0, w0, #0xfff
ffffff80013c2630:	32140400 	orr	w0, w0, #0x3000
ffffff80013c2634:	79040820 	strh	w0, [x1, #516]
ffffff80013c2638:	f9400261 	ldr	x1, [x19]
ffffff80013c263c:	79522820 	ldrh	w0, [x1, #2324]
ffffff80013c2640:	53003c00 	ubfm	w0, w0, #0, #15
ffffff80013c2644:	32000c00 	orr	w0, w0, #0xf
ffffff80013c2648:	79122820 	strh	w0, [x1, #2324]
ffffff80013c264c:	f9400261 	ldr	x1, [x19]
ffffff80013c2650:	914b9c21 	add	x1, x1, #0x2e7, lsl #12
ffffff80013c2654:	79474020 	ldrh	w0, [x1, #928]
ffffff80013c2658:	53003c00 	ubfm	w0, w0, #0, #15
ffffff80013c265c:	12157000 	and	w0, w0, #0xfffff8ff
ffffff80013c2660:	32160000 	orr	w0, w0, #0x400
ffffff80013c2664:	79074020 	strh	w0, [x1, #928]
ffffff80013c2668:	a94153f3 	ldp	x19, x20, [sp, #16]
ffffff80013c266c:	a8c37bfd 	ldp	x29, x30, [sp], #48
ffffff80013c2670:	d65f03c0 	ret
ffffff80013c2674:	97ffa9ed 	bl	0xffffff80013ace28
ffffff80013c2678:	2a1403e0 	orr	w0, wzr, w20
ffffff80013c267c:	97ffbfef 	bl	0xffffff80013b2638
ffffff80013c2680:	2a1403e0 	orr	w0, wzr, w20
ffffff80013c2684:	97ffbde3 	bl	0xffffff80013b1e10
ffffff80013c2688:	17ffffc8 	b	0xffffff80013c25a8
ffffff80013c268c:	d503201f 	hint	#0x0
ffffff80013c2690:	01765ef8 	.inst	0x01765ef8 ; undefined
ffffff80013c2694:	ffffff80 	.inst	0xffffff80 ; undefined
ffffff80013c2698:	0192dc70 	.inst	0x0192dc70 ; undefined
ffffff80013c269c:	ffffff80 	.inst	0xffffff80 ; undefined
ffffff80013c26a0:	02702ee0 	.inst	0x02702ee0 ; undefined
ffffff80013c26a4:	ffffff80 	.inst	0xffffff80 ; undefined
ffffff80013c26a8:	a9bc7bfd 	stp	x29, x30, [sp, #-64]!
ffffff80013c26ac:	910003fd 	add	x29, sp, #0x0
ffffff80013c26b0:	a90153f3 	stp	x19, x20, [sp, #16]
ffffff80013c26b4:	f90013f5 	str	x21, [sp, #32]
ffffff80013c26b8:	2a0003f5 	orr	w21, wzr, w0
ffffff80013c26bc:	aa1e03e0 	orr	x0, xzr, x30
ffffff80013c26c0:	53001c34 	ubfm	w20, w1, #0, #7
ffffff80013c26c4:	f9001fa2 	str	x2, [x29, #56]
ffffff80013c26c8:	d503201f 	hint	#0x0
ffffff80013c26cc:	51000687 	sub	w7, w20, #0x1
ffffff80013c26d0:	11014280 	add	w0, w20, #0x50
ffffff80013c26d4:	710008ff 	subs	wzr, w7, #0x2
ffffff80013c26d8:	f9401fa2 	ldr	x2, [x29, #56]
ffffff80013c26dc:	54000488 	b.hi	0xffffff80013c276c  // b.pmore
ffffff80013c26e0:	58002c41 	ldr	x1, 0xffffff80013c2c68
ffffff80013c26e4:	91010021 	add	x1, x1, #0x40
ffffff80013c26e8:	b8675825 	ldr	w5, [x1, w7, uxtw #2]
ffffff80013c26ec:	9145c8a3 	add	x3, x5, #0x172, lsl #12
ffffff80013c26f0:	91008066 	add	x6, x3, #0x20
ffffff80013c26f4:	91008863 	add	x3, x3, #0x22
ffffff80013c26f8:	8b0600c6 	add	x6, x6, x6
ffffff80013c26fc:	8b030063 	add	x3, x3, x3
ffffff80013c2700:	71014c1f 	subs	wzr, w0, #0x53
ffffff80013c2704:	58002b60 	ldr	x0, 0xffffff80013c2c70
ffffff80013c2708:	529c0004 	movz	w4, #0xe000
ffffff80013c270c:	1a9f0088 	csel	w8, w4, wzr, eq  // eq = none
ffffff80013c2710:	f9400004 	ldr	x4, [x0]
ffffff80013c2714:	8b040069 	add	x9, x3, x4
ffffff80013c2718:	786468c1 	ldrh	w1, [x6, x4]
ffffff80013c271c:	78646863 	ldrh	w3, [x3, x4]
ffffff80013c2720:	53003c21 	ubfm	w1, w1, #0, #15
ffffff80013c2724:	53003c63 	ubfm	w3, w3, #0, #15
ffffff80013c2728:	b40023a2 	cbz	x2, 0xffffff80013c2b9c
ffffff80013c272c:	3940b040 	ldrb	w0, [x2, #44]
ffffff80013c2730:	71000c1f 	subs	wzr, w0, #0x3
ffffff80013c2734:	1a9f17e0 	csinc	w0, wzr, wzr, ne  // ne = any
ffffff80013c2738:	12160073 	and	w19, w3, #0x400
ffffff80013c273c:	53003e73 	ubfm	w19, w19, #0, #15
ffffff80013c2740:	35002893 	cbnz	w19, 0xffffff80013c2c50
ffffff80013c2744:	71005abf 	subs	wzr, w21, #0x16
ffffff80013c2748:	540001e9 	b.ls	0xffffff80013c2784  // b.plast
ffffff80013c274c:	580029e0 	ldr	x0, 0xffffff80013c2c88
ffffff80013c2750:	2a1403e1 	orr	w1, wzr, w20
ffffff80013c2754:	95b8b039 	bl	0xffffff80081ee838
ffffff80013c2758:	2a1303e0 	orr	w0, wzr, w19
ffffff80013c275c:	f94013f5 	ldr	x21, [sp, #32]
ffffff80013c2760:	a94153f3 	ldp	x19, x20, [sp, #16]
ffffff80013c2764:	a8c47bfd 	ldp	x29, x30, [sp], #64
ffffff80013c2768:	d65f03c0 	ret
ffffff80013c276c:	d2880883 	movz	x3, #0x4044
ffffff80013c2770:	d2880806 	movz	x6, #0x4040
ffffff80013c2774:	f2a005c3 	movk	x3, #0x2e, lsl #16
ffffff80013c2778:	f2a005c6 	movk	x6, #0x2e, lsl #16
ffffff80013c277c:	d2800005 	movz	x5, #0x0
ffffff80013c2780:	17ffffe0 	b	0xffffff80013c2700
ffffff80013c2784:	580027e1 	ldr	x1, 0xffffff80013c2c80
ffffff80013c2788:	78755821 	ldrh	w1, [x1, w21, uxtw #1]
ffffff80013c278c:	10000063 	adr	x3, 0xffffff80013c2798
ffffff80013c2790:	8b21a861 	add	x1, x3, w1, sxth #2
ffffff80013c2794:	d61f0020 	br	x1
ffffff80013c2798:	52804013 	movz	w19, #0x200
ffffff80013c279c:	17ffffef 	b	0xffffff80013c2758
ffffff80013c27a0:	710008ff 	subs	wzr, w7, #0x2
ffffff80013c27a4:	54002508 	b.hi	0xffffff80013c2c44  // b.pmore
ffffff80013c27a8:	58002600 	ldr	x0, 0xffffff80013c2c68
ffffff80013c27ac:	9100c000 	add	x0, x0, #0x30
ffffff80013c27b0:	b8675800 	ldr	w0, [x0, w7, uxtw #2]
ffffff80013c27b4:	9145c400 	add	x0, x0, #0x171, lsl #12
ffffff80013c27b8:	91018000 	add	x0, x0, #0x60
ffffff80013c27bc:	8b000000 	add	x0, x0, x0
ffffff80013c27c0:	78646813 	ldrh	w19, [x0, x4]
ffffff80013c27c4:	121b0273 	and	w19, w19, #0x20
ffffff80013c27c8:	53003e73 	ubfm	w19, w19, #0, #15
ffffff80013c27cc:	34fffc73 	cbz	w19, 0xffffff80013c2758
ffffff80013c27d0:	9145c8a5 	add	x5, x5, #0x172, lsl #12
ffffff80013c27d4:	9100b8a5 	add	x5, x5, #0x2e
ffffff80013c27d8:	8b0500a5 	add	x5, x5, x5
ffffff80013c27dc:	786468b3 	ldrh	w19, [x5, x4]
ffffff80013c27e0:	12003673 	and	w19, w19, #0x3fff
ffffff80013c27e4:	17ffffdd 	b	0xffffff80013c2758
ffffff80013c27e8:	710008ff 	subs	wzr, w7, #0x2
ffffff80013c27ec:	54002268 	b.hi	0xffffff80013c2c38  // b.pmore
ffffff80013c27f0:	580023c0 	ldr	x0, 0xffffff80013c2c68
ffffff80013c27f4:	9100c000 	add	x0, x0, #0x30
ffffff80013c27f8:	b8675800 	ldr	w0, [x0, w7, uxtw #2]
ffffff80013c27fc:	9145c400 	add	x0, x0, #0x171, lsl #12
ffffff80013c2800:	91018000 	add	x0, x0, #0x60
ffffff80013c2804:	8b000000 	add	x0, x0, x0
ffffff80013c2808:	78646813 	ldrh	w19, [x0, x4]
ffffff80013c280c:	121b0273 	and	w19, w19, #0x20
ffffff80013c2810:	53003e73 	ubfm	w19, w19, #0, #15
ffffff80013c2814:	34fffa33 	cbz	w19, 0xffffff80013c2758
ffffff80013c2818:	9145c8a5 	add	x5, x5, #0x172, lsl #12
ffffff80013c281c:	9100c8a5 	add	x5, x5, #0x32
ffffff80013c2820:	8b0500a5 	add	x5, x5, x5
ffffff80013c2824:	786468b3 	ldrh	w19, [x5, x4]
ffffff80013c2828:	12003673 	and	w19, w19, #0x3fff
ffffff80013c282c:	17ffffcb 	b	0xffffff80013c2758
ffffff80013c2830:	710008ff 	subs	wzr, w7, #0x2
ffffff80013c2834:	54001fc8 	b.hi	0xffffff80013c2c2c  // b.pmore
ffffff80013c2838:	58002180 	ldr	x0, 0xffffff80013c2c68
ffffff80013c283c:	9100c000 	add	x0, x0, #0x30
ffffff80013c2840:	b8675800 	ldr	w0, [x0, w7, uxtw #2]
ffffff80013c2844:	9145c400 	add	x0, x0, #0x171, lsl #12
ffffff80013c2848:	91018000 	add	x0, x0, #0x60
ffffff80013c284c:	8b000000 	add	x0, x0, x0
ffffff80013c2850:	78646813 	ldrh	w19, [x0, x4]
ffffff80013c2854:	121b0273 	and	w19, w19, #0x20
ffffff80013c2858:	53003e73 	ubfm	w19, w19, #0, #15
ffffff80013c285c:	34fff7f3 	cbz	w19, 0xffffff80013c2758
ffffff80013c2860:	9145c8a5 	add	x5, x5, #0x172, lsl #12
ffffff80013c2864:	9100a8a0 	add	x0, x5, #0x2a
ffffff80013c2868:	910098a1 	add	x1, x5, #0x26
ffffff80013c286c:	8b000002 	add	x2, x0, x0
ffffff80013c2870:	8b010021 	add	x1, x1, x1
ffffff80013c2874:	9100b8a0 	add	x0, x5, #0x2e
ffffff80013c2878:	9100c8a5 	add	x5, x5, #0x32
ffffff80013c287c:	14000064 	b	0xffffff80013c2a0c
ffffff80013c2880:	34001ce0 	cbz	w0, 0xffffff80013c2c1c
ffffff80013c2884:	2a0803e0 	orr	w0, wzr, w8
ffffff80013c2888:	914d4c00 	add	x0, x0, #0x353, lsl #12
ffffff80013c288c:	913d7800 	add	x0, x0, #0xf5e
ffffff80013c2890:	8b000000 	add	x0, x0, x0
ffffff80013c2894:	78646813 	ldrh	w19, [x0, x4]
ffffff80013c2898:	12000e73 	and	w19, w19, #0xf
ffffff80013c289c:	17ffffaf 	b	0xffffff80013c2758
ffffff80013c28a0:	710008ff 	subs	wzr, w7, #0x2
ffffff80013c28a4:	54001b68 	b.hi	0xffffff80013c2c10  // b.pmore
ffffff80013c28a8:	58001e00 	ldr	x0, 0xffffff80013c2c68
ffffff80013c28ac:	9100c000 	add	x0, x0, #0x30
ffffff80013c28b0:	b8675800 	ldr	w0, [x0, w7, uxtw #2]
ffffff80013c28b4:	9145c400 	add	x0, x0, #0x171, lsl #12
ffffff80013c28b8:	91018000 	add	x0, x0, #0x60
ffffff80013c28bc:	8b000000 	add	x0, x0, x0
ffffff80013c28c0:	78646813 	ldrh	w19, [x0, x4]
ffffff80013c28c4:	121b0273 	and	w19, w19, #0x20
ffffff80013c28c8:	53003e73 	ubfm	w19, w19, #0, #15
ffffff80013c28cc:	34fff473 	cbz	w19, 0xffffff80013c2758
ffffff80013c28d0:	9145c8a5 	add	x5, x5, #0x172, lsl #12
ffffff80013c28d4:	910098a5 	add	x5, x5, #0x26
ffffff80013c28d8:	8b0500a5 	add	x5, x5, x5
ffffff80013c28dc:	786468b3 	ldrh	w19, [x5, x4]
ffffff80013c28e0:	12003673 	and	w19, w19, #0x3fff
ffffff80013c28e4:	17ffff9d 	b	0xffffff80013c2758
ffffff80013c28e8:	710008ff 	subs	wzr, w7, #0x2
ffffff80013c28ec:	540018c8 	b.hi	0xffffff80013c2c04  // b.pmore
ffffff80013c28f0:	58001bc0 	ldr	x0, 0xffffff80013c2c68
ffffff80013c28f4:	9100c000 	add	x0, x0, #0x30
ffffff80013c28f8:	b8675800 	ldr	w0, [x0, w7, uxtw #2]
ffffff80013c28fc:	9145c400 	add	x0, x0, #0x171, lsl #12
ffffff80013c2900:	91018000 	add	x0, x0, #0x60
ffffff80013c2904:	8b000000 	add	x0, x0, x0
ffffff80013c2908:	78646813 	ldrh	w19, [x0, x4]
ffffff80013c290c:	121b0273 	and	w19, w19, #0x20
ffffff80013c2910:	53003e73 	ubfm	w19, w19, #0, #15
ffffff80013c2914:	34fff233 	cbz	w19, 0xffffff80013c2758
ffffff80013c2918:	9145c8a5 	add	x5, x5, #0x172, lsl #12
ffffff80013c291c:	910090a5 	add	x5, x5, #0x24
ffffff80013c2920:	8b0500a5 	add	x5, x5, x5
ffffff80013c2924:	786468b3 	ldrh	w19, [x5, x4]
ffffff80013c2928:	12003673 	and	w19, w19, #0x3fff
ffffff80013c292c:	17ffff8b 	b	0xffffff80013c2758
ffffff80013c2930:	710008ff 	subs	wzr, w7, #0x2
ffffff80013c2934:	54001628 	b.hi	0xffffff80013c2bf8  // b.pmore
ffffff80013c2938:	58001980 	ldr	x0, 0xffffff80013c2c68
ffffff80013c293c:	9100c000 	add	x0, x0, #0x30
ffffff80013c2940:	b8675800 	ldr	w0, [x0, w7, uxtw #2]
ffffff80013c2944:	9145c400 	add	x0, x0, #0x171, lsl #12
ffffff80013c2948:	91018000 	add	x0, x0, #0x60
ffffff80013c294c:	8b000000 	add	x0, x0, x0
ffffff80013c2950:	78646813 	ldrh	w19, [x0, x4]
ffffff80013c2954:	121b0273 	and	w19, w19, #0x20
ffffff80013c2958:	53003e73 	ubfm	w19, w19, #0, #15
ffffff80013c295c:	34ffeff3 	cbz	w19, 0xffffff80013c2758
ffffff80013c2960:	9145c8a5 	add	x5, x5, #0x172, lsl #12
ffffff80013c2964:	9100a8a5 	add	x5, x5, #0x2a
ffffff80013c2968:	8b0500a5 	add	x5, x5, x5
ffffff80013c296c:	786468b3 	ldrh	w19, [x5, x4]
ffffff80013c2970:	12003673 	and	w19, w19, #0x3fff
ffffff80013c2974:	17ffff79 	b	0xffffff80013c2758
ffffff80013c2978:	710008ff 	subs	wzr, w7, #0x2
ffffff80013c297c:	54001388 	b.hi	0xffffff80013c2bec  // b.pmore
ffffff80013c2980:	58001740 	ldr	x0, 0xffffff80013c2c68
ffffff80013c2984:	9100c000 	add	x0, x0, #0x30
ffffff80013c2988:	b8675800 	ldr	w0, [x0, w7, uxtw #2]
ffffff80013c298c:	9145c400 	add	x0, x0, #0x171, lsl #12
ffffff80013c2990:	91018000 	add	x0, x0, #0x60
ffffff80013c2994:	8b000000 	add	x0, x0, x0
ffffff80013c2998:	78646813 	ldrh	w19, [x0, x4]
ffffff80013c299c:	121b0273 	and	w19, w19, #0x20
ffffff80013c29a0:	53003e73 	ubfm	w19, w19, #0, #15
ffffff80013c29a4:	34ffedb3 	cbz	w19, 0xffffff80013c2758
ffffff80013c29a8:	9145c8a5 	add	x5, x5, #0x172, lsl #12
ffffff80013c29ac:	9100a0a5 	add	x5, x5, #0x28
ffffff80013c29b0:	8b0500a5 	add	x5, x5, x5
ffffff80013c29b4:	786468b3 	ldrh	w19, [x5, x4]
ffffff80013c29b8:	12003673 	and	w19, w19, #0x3fff
ffffff80013c29bc:	17ffff67 	b	0xffffff80013c2758
ffffff80013c29c0:	710008ff 	subs	wzr, w7, #0x2
ffffff80013c29c4:	540010e8 	b.hi	0xffffff80013c2be0  // b.pmore
ffffff80013c29c8:	58001500 	ldr	x0, 0xffffff80013c2c68
ffffff80013c29cc:	9100c000 	add	x0, x0, #0x30
ffffff80013c29d0:	b8675800 	ldr	w0, [x0, w7, uxtw #2]
ffffff80013c29d4:	9145c400 	add	x0, x0, #0x171, lsl #12
ffffff80013c29d8:	91018000 	add	x0, x0, #0x60
ffffff80013c29dc:	8b000000 	add	x0, x0, x0
ffffff80013c29e0:	78646813 	ldrh	w19, [x0, x4]
ffffff80013c29e4:	121b0273 	and	w19, w19, #0x20
ffffff80013c29e8:	53003e73 	ubfm	w19, w19, #0, #15
ffffff80013c29ec:	34ffeb73 	cbz	w19, 0xffffff80013c2758
ffffff80013c29f0:	9145c8a5 	add	x5, x5, #0x172, lsl #12
ffffff80013c29f4:	9100a0a0 	add	x0, x5, #0x28
ffffff80013c29f8:	910090a1 	add	x1, x5, #0x24
ffffff80013c29fc:	8b000002 	add	x2, x0, x0
ffffff80013c2a00:	8b010021 	add	x1, x1, x1
ffffff80013c2a04:	9100b0a0 	add	x0, x5, #0x2c
ffffff80013c2a08:	9100c0a5 	add	x5, x5, #0x30
ffffff80013c2a0c:	8b000000 	add	x0, x0, x0
ffffff80013c2a10:	8b0500a5 	add	x5, x5, x5
ffffff80013c2a14:	78646821 	ldrh	w1, [x1, x4]
ffffff80013c2a18:	78646843 	ldrh	w3, [x2, x4]
ffffff80013c2a1c:	78646800 	ldrh	w0, [x0, x4]
ffffff80013c2a20:	12003422 	and	w2, w1, #0x3fff
ffffff80013c2a24:	786468b3 	ldrh	w19, [x5, x4]
ffffff80013c2a28:	12003461 	and	w1, w3, #0x3fff
ffffff80013c2a2c:	4b010041 	sub	w1, w2, w1
ffffff80013c2a30:	12003400 	and	w0, w0, #0x3fff
ffffff80013c2a34:	4b000020 	sub	w0, w1, w0
