
physeq.bin:     file format binary


Disassembly of section .data:

ffffff8008753764 <.data>:
ffffff8008753764:	a9b97bfd 	stp	x29, x30, [sp, #-112]!
ffffff8008753768:	910003fd 	add	x29, sp, #0x0
ffffff800875376c:	a90153f3 	stp	x19, x20, [sp, #16]
ffffff8008753770:	a9025bf5 	stp	x21, x22, [sp, #32]
ffffff8008753774:	a90363f7 	stp	x23, x24, [sp, #48]
ffffff8008753778:	a9046bf9 	stp	x25, x26, [sp, #64]
ffffff800875377c:	a90573fb 	stp	x27, x28, [sp, #80]
ffffff8008753780:	aa0003f9 	orr	x25, xzr, x0
ffffff8008753784:	aa1e03e0 	orr	x0, xzr, x30
ffffff8008753788:	2a0403fc 	orr	w28, wzr, w4
ffffff800875378c:	aa0203fb 	orr	x27, xzr, x2
ffffff8008753790:	aa0103f3 	orr	x19, xzr, x1
ffffff8008753794:	aa0303f7 	orr	x23, xzr, x3
ffffff8008753798:	d503201f 	hint	#0x0
ffffff800875379c:	b0003dc0 	adrp	x0, 0xffffff8008f0c000
ffffff80087537a0:	121f0381 	and	w1, w28, #0x2
ffffff80087537a4:	910ca000 	add	x0, x0, #0x328
ffffff80087537a8:	b90067a1 	str	w1, [x29, #100]
ffffff80087537ac:	97ea6c23 	bl	0xffffff80081ee838
ffffff80087537b0:	aa1b03e0 	orr	x0, xzr, x27
ffffff80087537b4:	97ffffbd 	bl	0xffffff80087536a8
ffffff80087537b8:	3608013c 	tbz	w28, #1, 0xffffff80087537dc
ffffff80087537bc:	d5033e9f 	dsb	st
ffffff80087537c0:	52841081 	movz	w1, #0x2084
ffffff80087537c4:	91001260 	add	x0, x19, #0x4
ffffff80087537c8:	79000001 	strh	w1, [x0]
ffffff80087537cc:	d5033e9f 	dsb	st
ffffff80087537d0:	128ff5c1 	movn	w1, #0x7fae
ffffff80087537d4:	91010260 	add	x0, x19, #0x40
ffffff80087537d8:	79000001 	strh	w1, [x0]
ffffff80087537dc:	d5033e9f 	dsb	st
ffffff80087537e0:	39400260 	ldrb	w0, [x19]
ffffff80087537e4:	53001c01 	ubfm	w1, w0, #0, #7
ffffff80087537e8:	d5033d9f 	dsb	ld
ffffff80087537ec:	128007a0 	movn	w0, #0x3d
ffffff80087537f0:	2a000020 	orr	w0, w1, w0
ffffff80087537f4:	39000260 	strb	w0, [x19]
ffffff80087537f8:	d5033e9f 	dsb	st
ffffff80087537fc:	9102927a 	add	x26, x19, #0xa4
ffffff8008753800:	39400340 	ldrb	w0, [x26]
ffffff8008753804:	53001c00 	ubfm	w0, w0, #0, #7
ffffff8008753808:	d5033d9f 	dsb	ld
ffffff800875380c:	32001400 	orr	w0, w0, #0x3f
ffffff8008753810:	39000340 	strb	w0, [x26]
ffffff8008753814:	d5033e9f 	dsb	st
ffffff8008753818:	39400360 	ldrb	w0, [x27]
ffffff800875381c:	53001c01 	ubfm	w1, w0, #0, #7
ffffff8008753820:	d5033d9f 	dsb	ld
ffffff8008753824:	52800140 	movz	w0, #0xa
ffffff8008753828:	2a000020 	orr	w0, w1, w0
ffffff800875382c:	39000360 	strb	w0, [x27]
ffffff8008753830:	d5033e9f 	dsb	st
ffffff8008753834:	39400360 	ldrb	w0, [x27]
ffffff8008753838:	53001c01 	ubfm	w1, w0, #0, #7
ffffff800875383c:	d5033d9f 	dsb	ld
ffffff8008753840:	12800440 	movn	w0, #0x22
ffffff8008753844:	0a000020 	and	w0, w1, w0
ffffff8008753848:	321b0000 	orr	w0, w0, #0x20
ffffff800875384c:	39000360 	strb	w0, [x27]
ffffff8008753850:	d5033e9f 	dsb	st
ffffff8008753854:	910202f8 	add	x24, x23, #0x80
ffffff8008753858:	39400300 	ldrb	w0, [x24]
ffffff800875385c:	53001c00 	ubfm	w0, w0, #0, #7
ffffff8008753860:	d5033d9f 	dsb	ld
ffffff8008753864:	321d0000 	orr	w0, w0, #0x8
ffffff8008753868:	39000300 	strb	w0, [x24]
ffffff800875386c:	121e0380 	and	w0, w28, #0x4
ffffff8008753870:	b90063a0 	str	w0, [x29, #96]
ffffff8008753874:	91016276 	add	x22, x19, #0x58
ffffff8008753878:	361001fc 	tbz	w28, #2, 0xffffff80087538b4
ffffff800875387c:	12040f80 	and	w0, w28, #0xf0000000
ffffff8008753880:	52a20001 	movz	w1, #0x1000, lsl #16
ffffff8008753884:	6b01001f 	subs	wzr, w0, w1
ffffff8008753888:	54002f60 	b.eq	0xffffff8008753e74  // b.none
ffffff800875388c:	52a40001 	movz	w1, #0x2000, lsl #16
ffffff8008753890:	6b01001f 	subs	wzr, w0, w1
ffffff8008753894:	54003020 	b.eq	0xffffff8008753e98  // b.none
ffffff8008753898:	d5033e9f 	dsb	st
ffffff800875389c:	91016276 	add	x22, x19, #0x58
ffffff80087538a0:	394002c0 	ldrb	w0, [x22]
ffffff80087538a4:	53001c00 	ubfm	w0, w0, #0, #7
ffffff80087538a8:	d5033d9f 	dsb	ld
ffffff80087538ac:	32000000 	orr	w0, w0, #0x1
ffffff80087538b0:	390002c0 	strb	w0, [x22]
ffffff80087538b4:	910ae335 	add	x21, x25, #0x2b8
ffffff80087538b8:	394006a0 	ldrb	w0, [x21, #1]
ffffff80087538bc:	35003000 	cbnz	w0, 0xffffff8008753ebc
ffffff80087538c0:	91015260 	add	x0, x19, #0x54
ffffff80087538c4:	f90037a0 	str	x0, [x29, #104]
ffffff80087538c8:	d5033e9f 	dsb	st
ffffff80087538cc:	9101e274 	add	x20, x19, #0x78
ffffff80087538d0:	39400280 	ldrb	w0, [x20]
ffffff80087538d4:	53001c00 	ubfm	w0, w0, #0, #7
ffffff80087538d8:	d5033d9f 	dsb	ld
ffffff80087538dc:	32000000 	orr	w0, w0, #0x1
ffffff80087538e0:	39000280 	strb	w0, [x20]
ffffff80087538e4:	d2912b00 	movz	x0, #0x8958
ffffff80087538e8:	f2a00820 	movk	x0, #0x41, lsl #16
ffffff80087538ec:	97f8c83b 	bl	0xffffff80085859d8
ffffff80087538f0:	d5033e9f 	dsb	st
ffffff80087538f4:	39400280 	ldrb	w0, [x20]
ffffff80087538f8:	53001c00 	ubfm	w0, w0, #0, #7
ffffff80087538fc:	d5033d9f 	dsb	ld
ffffff8008753900:	121f7800 	and	w0, w0, #0xfffffffe
ffffff8008753904:	39000280 	strb	w0, [x20]
ffffff8008753908:	39400285 	ldrb	w5, [x20]
ffffff800875390c:	53001ca5 	ubfm	w5, w5, #0, #7
ffffff8008753910:	d5033d9f 	dsb	ld
ffffff8008753914:	360fffa5 	tbz	w5, #1, 0xffffff8008753908
ffffff8008753918:	79400280 	ldrh	w0, [x20]
ffffff800875391c:	53003c00 	ubfm	w0, w0, #0, #15
ffffff8008753920:	d5033d9f 	dsb	ld
ffffff8008753924:	529ffe01 	movz	w1, #0xfff0
ffffff8008753928:	121c2c00 	and	w0, w0, #0xfff0
ffffff800875392c:	6b01001f 	subs	wzr, w0, w1
ffffff8008753930:	54002e00 	b.eq	0xffffff8008753ef0  // b.none
ffffff8008753934:	79400294 	ldrh	w20, [x20]
ffffff8008753938:	53003e94 	ubfm	w20, w20, #0, #15
ffffff800875393c:	d5033d9f 	dsb	ld
ffffff8008753940:	721c2e9f 	ands	wzr, w20, #0xfff0
ffffff8008753944:	54002d60 	b.eq	0xffffff8008753ef0  // b.none
ffffff8008753948:	3600011c 	tbz	w28, #0, 0xffffff8008753968
ffffff800875394c:	d5033e9f 	dsb	st
ffffff8008753950:	91005661 	add	x1, x19, #0x15
ffffff8008753954:	39400020 	ldrb	w0, [x1]
ffffff8008753958:	53001c00 	ubfm	w0, w0, #0, #7
ffffff800875395c:	d5033d9f 	dsb	ld
ffffff8008753960:	321b0000 	orr	w0, w0, #0x20
ffffff8008753964:	39000020 	strb	w0, [x1]
ffffff8008753968:	91001374 	add	x20, x27, #0x4
ffffff800875396c:	3718013c 	tbnz	w28, #3, 0xffffff8008753990
ffffff8008753970:	d5033e9f 	dsb	st
ffffff8008753974:	91001374 	add	x20, x27, #0x4
ffffff8008753978:	39400280 	ldrb	w0, [x20]
ffffff800875397c:	53001c00 	ubfm	w0, w0, #0, #7
ffffff8008753980:	d5033d9f 	dsb	ld
ffffff8008753984:	121e7400 	and	w0, w0, #0xfffffffc
ffffff8008753988:	32000000 	orr	w0, w0, #0x1
ffffff800875398c:	39000280 	strb	w0, [x20]
ffffff8008753990:	d5033e9f 	dsb	st
ffffff8008753994:	39400300 	ldrb	w0, [x24]
ffffff8008753998:	53001c00 	ubfm	w0, w0, #0, #7
ffffff800875399c:	d5033d9f 	dsb	ld
ffffff80087539a0:	121b7800 	and	w0, w0, #0xffffffef
ffffff80087539a4:	39000300 	strb	w0, [x24]
ffffff80087539a8:	d28218e0 	movz	x0, #0x10c7
ffffff80087539ac:	97f8c80b 	bl	0xffffff80085859d8
ffffff80087539b0:	d5033e9f 	dsb	st
ffffff80087539b4:	39400260 	ldrb	w0, [x19]
ffffff80087539b8:	53001c01 	ubfm	w1, w0, #0, #7
ffffff80087539bc:	d5033d9f 	dsb	ld
ffffff80087539c0:	528007a0 	movz	w0, #0x3d
ffffff80087539c4:	0a000020 	and	w0, w1, w0
ffffff80087539c8:	39000260 	strb	w0, [x19]
ffffff80087539cc:	d5033e9f 	dsb	st
ffffff80087539d0:	39400340 	ldrb	w0, [x26]
ffffff80087539d4:	53001c00 	ubfm	w0, w0, #0, #7
ffffff80087539d8:	d5033d9f 	dsb	ld
ffffff80087539dc:	121a6400 	and	w0, w0, #0xffffffc0
ffffff80087539e0:	39000340 	strb	w0, [x26]
ffffff80087539e4:	d5033e9f 	dsb	st
ffffff80087539e8:	91003260 	add	x0, x19, #0xc
ffffff80087539ec:	39400001 	ldrb	w1, [x0]
ffffff80087539f0:	53001c21 	ubfm	w1, w1, #0, #7
ffffff80087539f4:	d5033d9f 	dsb	ld
ffffff80087539f8:	12197421 	and	w1, w1, #0xffffff9f
ffffff80087539fc:	321a0021 	orr	w1, w1, #0x40
ffffff8008753a00:	39000001 	strb	w1, [x0]
ffffff8008753a04:	d5033e9f 	dsb	st
ffffff8008753a08:	91001661 	add	x1, x19, #0x5
ffffff8008753a0c:	39400020 	ldrb	w0, [x1]
ffffff8008753a10:	53001c00 	ubfm	w0, w0, #0, #7
ffffff8008753a14:	d5033d9f 	dsb	ld
ffffff8008753a18:	52800502 	movz	w2, #0x28
ffffff8008753a1c:	121a7000 	and	w0, w0, #0xffffffc7
ffffff8008753a20:	2a020000 	orr	w0, w0, w2
ffffff8008753a24:	39000020 	strb	w0, [x1]
ffffff8008753a28:	d5033e9f 	dsb	st
ffffff8008753a2c:	91003662 	add	x2, x19, #0xd
ffffff8008753a30:	39400040 	ldrb	w0, [x2]
ffffff8008753a34:	53001c00 	ubfm	w0, w0, #0, #7
ffffff8008753a38:	d5033d9f 	dsb	ld
ffffff8008753a3c:	121e7800 	and	w0, w0, #0xfffffffd
ffffff8008753a40:	39000040 	strb	w0, [x2]
ffffff8008753a44:	d5033e9f 	dsb	st
ffffff8008753a48:	91004262 	add	x2, x19, #0x10
ffffff8008753a4c:	39400040 	ldrb	w0, [x2]
ffffff8008753a50:	53001c00 	ubfm	w0, w0, #0, #7
ffffff8008753a54:	d5033d9f 	dsb	ld
ffffff8008753a58:	321d0000 	orr	w0, w0, #0x8
ffffff8008753a5c:	39000040 	strb	w0, [x2]
ffffff8008753a60:	d5033e9f 	dsb	st
ffffff8008753a64:	91004662 	add	x2, x19, #0x11
ffffff8008753a68:	39400040 	ldrb	w0, [x2]
ffffff8008753a6c:	53001c00 	ubfm	w0, w0, #0, #7
ffffff8008753a70:	d5033d9f 	dsb	ld
ffffff8008753a74:	32196400 	orr	w0, w0, #0xffffff81
ffffff8008753a78:	39000040 	strb	w0, [x2]
ffffff8008753a7c:	b94063a0 	ldr	w0, [x29, #96]
ffffff8008753a80:	35000100 	cbnz	w0, 0xffffff8008753aa0
ffffff8008753a84:	d5033e9f 	dsb	st
ffffff8008753a88:	91005662 	add	x2, x19, #0x15
ffffff8008753a8c:	39400040 	ldrb	w0, [x2]
ffffff8008753a90:	53001c00 	ubfm	w0, w0, #0, #7
ffffff8008753a94:	d5033d9f 	dsb	ld
ffffff8008753a98:	32196000 	orr	w0, w0, #0xffffff80
ffffff8008753a9c:	39000040 	strb	w0, [x2]
ffffff8008753aa0:	d5033e9f 	dsb	st
ffffff8008753aa4:	9100a662 	add	x2, x19, #0x29
ffffff8008753aa8:	39400040 	ldrb	w0, [x2]
ffffff8008753aac:	53001c00 	ubfm	w0, w0, #0, #7
ffffff8008753ab0:	d5033d9f 	dsb	ld
ffffff8008753ab4:	321b0000 	orr	w0, w0, #0x20
ffffff8008753ab8:	39000040 	strb	w0, [x2]
ffffff8008753abc:	d5033e9f 	dsb	st
ffffff8008753ac0:	39400040 	ldrb	w0, [x2]
ffffff8008753ac4:	53001c00 	ubfm	w0, w0, #0, #7
ffffff8008753ac8:	d5033d9f 	dsb	ld
ffffff8008753acc:	321a0000 	orr	w0, w0, #0x40
ffffff8008753ad0:	39000040 	strb	w0, [x2]
ffffff8008753ad4:	d5033e9f 	dsb	st
ffffff8008753ad8:	91020262 	add	x2, x19, #0x80
ffffff8008753adc:	39400040 	ldrb	w0, [x2]
ffffff8008753ae0:	53001c00 	ubfm	w0, w0, #0, #7
ffffff8008753ae4:	d5033d9f 	dsb	ld
ffffff8008753ae8:	121b7800 	and	w0, w0, #0xffffffef
ffffff8008753aec:	39000040 	strb	w0, [x2]
ffffff8008753af0:	d5033e9f 	dsb	st
ffffff8008753af4:	394006a3 	ldrb	w3, [x21, #1]
ffffff8008753af8:	394ae320 	ldrb	w0, [x25, #696]
ffffff8008753afc:	2a000060 	orr	w0, w3, w0
ffffff8008753b00:	f94037a3 	ldr	x3, [x29, #104]
ffffff8008753b04:	39000060 	strb	w0, [x3]
ffffff8008753b08:	d5033e9f 	dsb	st
ffffff8008753b0c:	39400aa0 	ldrb	w0, [x21, #2]
ffffff8008753b10:	91021263 	add	x3, x19, #0x84
ffffff8008753b14:	39000060 	strb	w0, [x3]
ffffff8008753b18:	d5033e9f 	dsb	st
ffffff8008753b1c:	39400040 	ldrb	w0, [x2]
ffffff8008753b20:	53001c00 	ubfm	w0, w0, #0, #7
ffffff8008753b24:	d5033d9f 	dsb	ld
ffffff8008753b28:	121c7800 	and	w0, w0, #0xfffffff7
ffffff8008753b2c:	39000040 	strb	w0, [x2]
ffffff8008753b30:	d5033e9f 	dsb	st
ffffff8008753b34:	394002c0 	ldrb	w0, [x22]
ffffff8008753b38:	53001c02 	ubfm	w2, w0, #0, #7
ffffff8008753b3c:	d5033d9f 	dsb	ld
ffffff8008753b40:	394aef20 	ldrb	w0, [x25, #699]
ffffff8008753b44:	2a000040 	orr	w0, w2, w0
ffffff8008753b48:	390002c0 	strb	w0, [x22]
ffffff8008753b4c:	d5033e9f 	dsb	st
ffffff8008753b50:	91016663 	add	x3, x19, #0x59
ffffff8008753b54:	39400060 	ldrb	w0, [x3]
ffffff8008753b58:	53001c02 	ubfm	w2, w0, #0, #7
ffffff8008753b5c:	d5033d9f 	dsb	ld
ffffff8008753b60:	394af320 	ldrb	w0, [x25, #700]
ffffff8008753b64:	2a000040 	orr	w0, w2, w0
ffffff8008753b68:	39000060 	strb	w0, [x3]
ffffff8008753b6c:	d5033e9f 	dsb	st
ffffff8008753b70:	91017263 	add	x3, x19, #0x5c
ffffff8008753b74:	39400060 	ldrb	w0, [x3]
ffffff8008753b78:	53001c02 	ubfm	w2, w0, #0, #7
ffffff8008753b7c:	d5033d9f 	dsb	ld
ffffff8008753b80:	394af720 	ldrb	w0, [x25, #701]
ffffff8008753b84:	2a000040 	orr	w0, w2, w0
ffffff8008753b88:	39000060 	strb	w0, [x3]
ffffff8008753b8c:	d5033e9f 	dsb	st
ffffff8008753b90:	91017663 	add	x3, x19, #0x5d
ffffff8008753b94:	39400060 	ldrb	w0, [x3]
ffffff8008753b98:	53001c02 	ubfm	w2, w0, #0, #7
ffffff8008753b9c:	d5033d9f 	dsb	ld
ffffff8008753ba0:	394afb20 	ldrb	w0, [x25, #702]
ffffff8008753ba4:	2a000040 	orr	w0, w2, w0
ffffff8008753ba8:	39000060 	strb	w0, [x3]
ffffff8008753bac:	d5033e9f 	dsb	st
ffffff8008753bb0:	91002262 	add	x2, x19, #0x8
ffffff8008753bb4:	39400040 	ldrb	w0, [x2]
ffffff8008753bb8:	53001c00 	ubfm	w0, w0, #0, #7
ffffff8008753bbc:	d5033d9f 	dsb	ld
ffffff8008753bc0:	321a0000 	orr	w0, w0, #0x40
ffffff8008753bc4:	39000040 	strb	w0, [x2]
ffffff8008753bc8:	d5033e9f 	dsb	st
ffffff8008753bcc:	39400280 	ldrb	w0, [x20]
ffffff8008753bd0:	53001c00 	ubfm	w0, w0, #0, #7
ffffff8008753bd4:	d5033d9f 	dsb	ld
ffffff8008753bd8:	321a0000 	orr	w0, w0, #0x40
ffffff8008753bdc:	39000280 	strb	w0, [x20]
ffffff8008753be0:	d5033e9f 	dsb	st
ffffff8008753be4:	39400040 	ldrb	w0, [x2]
ffffff8008753be8:	53001c00 	ubfm	w0, w0, #0, #7
ffffff8008753bec:	d5033d9f 	dsb	ld
ffffff8008753bf0:	321b0000 	orr	w0, w0, #0x20
ffffff8008753bf4:	39000040 	strb	w0, [x2]
ffffff8008753bf8:	d5033e9f 	dsb	st
ffffff8008753bfc:	91008262 	add	x2, x19, #0x20
ffffff8008753c00:	39400040 	ldrb	w0, [x2]
ffffff8008753c04:	53001c00 	ubfm	w0, w0, #0, #7
ffffff8008753c08:	d5033d9f 	dsb	ld
ffffff8008753c0c:	321a0000 	orr	w0, w0, #0x40
ffffff8008753c10:	39000040 	strb	w0, [x2]
ffffff8008753c14:	d5033e9f 	dsb	st
ffffff8008753c18:	91008763 	add	x3, x27, #0x21
ffffff8008753c1c:	39400060 	ldrb	w0, [x3]
ffffff8008753c20:	53001c00 	ubfm	w0, w0, #0, #7
ffffff8008753c24:	d5033d9f 	dsb	ld
ffffff8008753c28:	321f0000 	orr	w0, w0, #0x2
ffffff8008753c2c:	39000060 	strb	w0, [x3]
ffffff8008753c30:	d5033e9f 	dsb	st
ffffff8008753c34:	91005364 	add	x4, x27, #0x14
ffffff8008753c38:	39400080 	ldrb	w0, [x4]
ffffff8008753c3c:	53001c00 	ubfm	w0, w0, #0, #7
ffffff8008753c40:	d5033d9f 	dsb	ld
ffffff8008753c44:	321a0000 	orr	w0, w0, #0x40
ffffff8008753c48:	39000080 	strb	w0, [x4]
ffffff8008753c4c:	d5033e9f 	dsb	st
ffffff8008753c50:	91005764 	add	x4, x27, #0x15
ffffff8008753c54:	39400080 	ldrb	w0, [x4]
ffffff8008753c58:	53001c00 	ubfm	w0, w0, #0, #7
ffffff8008753c5c:	d5033d9f 	dsb	ld
ffffff8008753c60:	121b6c00 	and	w0, w0, #0xffffffe1
ffffff8008753c64:	39000080 	strb	w0, [x4]
ffffff8008753c68:	d5033e9f 	dsb	st
ffffff8008753c6c:	9101f664 	add	x4, x19, #0x7d
ffffff8008753c70:	39400080 	ldrb	w0, [x4]
ffffff8008753c74:	53001c00 	ubfm	w0, w0, #0, #7
ffffff8008753c78:	d5033d9f 	dsb	ld
ffffff8008753c7c:	32196000 	orr	w0, w0, #0xffffff80
ffffff8008753c80:	39000080 	strb	w0, [x4]
ffffff8008753c84:	d5033e9f 	dsb	st
ffffff8008753c88:	91007764 	add	x4, x27, #0x1d
ffffff8008753c8c:	39400080 	ldrb	w0, [x4]
ffffff8008753c90:	53001c00 	ubfm	w0, w0, #0, #7
ffffff8008753c94:	d5033d9f 	dsb	ld
ffffff8008753c98:	321d0000 	orr	w0, w0, #0x8
ffffff8008753c9c:	39000080 	strb	w0, [x4]
ffffff8008753ca0:	d5033e9f 	dsb	st
ffffff8008753ca4:	91008364 	add	x4, x27, #0x20
ffffff8008753ca8:	39400080 	ldrb	w0, [x4]
ffffff8008753cac:	53001c00 	ubfm	w0, w0, #0, #7
ffffff8008753cb0:	d5033d9f 	dsb	ld
ffffff8008753cb4:	32000000 	orr	w0, w0, #0x1
ffffff8008753cb8:	39000080 	strb	w0, [x4]
ffffff8008753cbc:	d5033e9f 	dsb	st
ffffff8008753cc0:	39400080 	ldrb	w0, [x4]
ffffff8008753cc4:	53001c00 	ubfm	w0, w0, #0, #7
ffffff8008753cc8:	d5033d9f 	dsb	ld
ffffff8008753ccc:	321f0000 	orr	w0, w0, #0x2
ffffff8008753cd0:	39000080 	strb	w0, [x4]
ffffff8008753cd4:	d5033e9f 	dsb	st
ffffff8008753cd8:	39400020 	ldrb	w0, [x1]
ffffff8008753cdc:	53001c00 	ubfm	w0, w0, #0, #7
ffffff8008753ce0:	d5033d9f 	dsb	ld
ffffff8008753ce4:	321e0000 	orr	w0, w0, #0x4
ffffff8008753ce8:	39000020 	strb	w0, [x1]
ffffff8008753cec:	d5033e9f 	dsb	st
ffffff8008753cf0:	91009761 	add	x1, x27, #0x25
ffffff8008753cf4:	39400020 	ldrb	w0, [x1]
ffffff8008753cf8:	53001c00 	ubfm	w0, w0, #0, #7
ffffff8008753cfc:	d5033d9f 	dsb	ld
ffffff8008753d00:	32000000 	orr	w0, w0, #0x1
ffffff8008753d04:	39000020 	strb	w0, [x1]
ffffff8008753d08:	d5033e9f 	dsb	st
ffffff8008753d0c:	91010360 	add	x0, x27, #0x40
ffffff8008753d10:	39400001 	ldrb	w1, [x0]
ffffff8008753d14:	53001c21 	ubfm	w1, w1, #0, #7
ffffff8008753d18:	d5033d9f 	dsb	ld
ffffff8008753d1c:	32000021 	orr	w1, w1, #0x1
ffffff8008753d20:	39000001 	strb	w1, [x0]
ffffff8008753d24:	d5033e9f 	dsb	st
ffffff8008753d28:	39400001 	ldrb	w1, [x0]
ffffff8008753d2c:	53001c21 	ubfm	w1, w1, #0, #7
ffffff8008753d30:	d5033d9f 	dsb	ld
ffffff8008753d34:	321f0021 	orr	w1, w1, #0x2
ffffff8008753d38:	39000001 	strb	w1, [x0]
ffffff8008753d3c:	d5033e9f 	dsb	st
ffffff8008753d40:	39400001 	ldrb	w1, [x0]
ffffff8008753d44:	53001c21 	ubfm	w1, w1, #0, #7
ffffff8008753d48:	d5033d9f 	dsb	ld
ffffff8008753d4c:	321e0021 	orr	w1, w1, #0x4
ffffff8008753d50:	39000001 	strb	w1, [x0]
ffffff8008753d54:	d5033e9f 	dsb	st
ffffff8008753d58:	528000a1 	movz	w1, #0x5
ffffff8008753d5c:	91001764 	add	x4, x27, #0x5
ffffff8008753d60:	39000081 	strb	w1, [x4]
ffffff8008753d64:	d5033e9f 	dsb	st
ffffff8008753d68:	39400001 	ldrb	w1, [x0]
ffffff8008753d6c:	53001c21 	ubfm	w1, w1, #0, #7
ffffff8008753d70:	d5033d9f 	dsb	ld
ffffff8008753d74:	121b7821 	and	w1, w1, #0xffffffef
ffffff8008753d78:	39000001 	strb	w1, [x0]
ffffff8008753d7c:	d5033e9f 	dsb	st
ffffff8008753d80:	39400061 	ldrb	w1, [x3]
ffffff8008753d84:	53001c21 	ubfm	w1, w1, #0, #7
ffffff8008753d88:	d5033d9f 	dsb	ld
ffffff8008753d8c:	32196021 	orr	w1, w1, #0xffffff80
ffffff8008753d90:	39000061 	strb	w1, [x3]
ffffff8008753d94:	d5033e9f 	dsb	st
ffffff8008753d98:	91011363 	add	x3, x27, #0x44
ffffff8008753d9c:	39400061 	ldrb	w1, [x3]
ffffff8008753da0:	53001c21 	ubfm	w1, w1, #0, #7
ffffff8008753da4:	d5033d9f 	dsb	ld
ffffff8008753da8:	32000021 	orr	w1, w1, #0x1
ffffff8008753dac:	39000061 	strb	w1, [x3]
ffffff8008753db0:	d5033e9f 	dsb	st
ffffff8008753db4:	39400001 	ldrb	w1, [x0]
ffffff8008753db8:	53001c21 	ubfm	w1, w1, #0, #7
ffffff8008753dbc:	d5033d9f 	dsb	ld
ffffff8008753dc0:	32000021 	orr	w1, w1, #0x1
ffffff8008753dc4:	39000001 	strb	w1, [x0]
ffffff8008753dc8:	d5033e9f 	dsb	st
ffffff8008753dcc:	9101077b 	add	x27, x27, #0x41
ffffff8008753dd0:	39400360 	ldrb	w0, [x27]
ffffff8008753dd4:	53001c00 	ubfm	w0, w0, #0, #7
ffffff8008753dd8:	d5033d9f 	dsb	ld
ffffff8008753ddc:	121c7400 	and	w0, w0, #0xfffffff3
ffffff8008753de0:	39000360 	strb	w0, [x27]
ffffff8008753de4:	d5033e9f 	dsb	st
ffffff8008753de8:	39400360 	ldrb	w0, [x27]
ffffff8008753dec:	53001c00 	ubfm	w0, w0, #0, #7
ffffff8008753df0:	d5033d9f 	dsb	ld
ffffff8008753df4:	321c0400 	orr	w0, w0, #0x30
ffffff8008753df8:	39000360 	strb	w0, [x27]
ffffff8008753dfc:	d5033e9f 	dsb	st
ffffff8008753e00:	91026263 	add	x3, x19, #0x98
ffffff8008753e04:	39400060 	ldrb	w0, [x3]
ffffff8008753e08:	53001c01 	ubfm	w1, w0, #0, #7
ffffff8008753e0c:	d5033d9f 	dsb	ld
ffffff8008753e10:	52800120 	movz	w0, #0x9
ffffff8008753e14:	2a000020 	orr	w0, w1, w0
ffffff8008753e18:	39000060 	strb	w0, [x3]
ffffff8008753e1c:	b94067a0 	ldr	w0, [x29, #100]
ffffff8008753e20:	34000180 	cbz	w0, 0xffffff8008753e50
ffffff8008753e24:	d5033e9f 	dsb	st
ffffff8008753e28:	5280c000 	movz	w0, #0x600
ffffff8008753e2c:	9100a261 	add	x1, x19, #0x28
ffffff8008753e30:	79000020 	strh	w0, [x1]
ffffff8008753e34:	d5033e9f 	dsb	st
ffffff8008753e38:	52800f00 	movz	w0, #0x78
ffffff8008753e3c:	79000040 	strh	w0, [x2]
ffffff8008753e40:	d5033e9f 	dsb	st
ffffff8008753e44:	52817fc0 	movz	w0, #0xbfe
ffffff8008753e48:	91019273 	add	x19, x19, #0x64
ffffff8008753e4c:	79000260 	strh	w0, [x19]
ffffff8008753e50:	aa1703e0 	orr	x0, xzr, x23
ffffff8008753e54:	97ffd463 	bl	0xffffff8008748fe0
ffffff8008753e58:	a94153f3 	ldp	x19, x20, [sp, #16]
ffffff8008753e5c:	a9425bf5 	ldp	x21, x22, [sp, #32]
ffffff8008753e60:	a94363f7 	ldp	x23, x24, [sp, #48]
ffffff8008753e64:	a9446bf9 	ldp	x25, x26, [sp, #64]
ffffff8008753e68:	a94573fb 	ldp	x27, x28, [sp, #80]
ffffff8008753e6c:	a8c77bfd 	ldp	x29, x30, [sp], #112
ffffff8008753e70:	d65f03c0 	ret
ffffff8008753e74:	d5033e9f 	dsb	st
ffffff8008753e78:	91010264 	add	x4, x19, #0x40
ffffff8008753e7c:	39400080 	ldrb	w0, [x4]
ffffff8008753e80:	53001c01 	ubfm	w1, w0, #0, #7
ffffff8008753e84:	d5033d9f 	dsb	ld
ffffff8008753e88:	52800ec0 	movz	w0, #0x76
ffffff8008753e8c:	2a000020 	orr	w0, w1, w0
ffffff8008753e90:	39000080 	strb	w0, [x4]
ffffff8008753e94:	17fffe81 	b	0xffffff8008753898
ffffff8008753e98:	d5033e9f 	dsb	st
ffffff8008753e9c:	91010264 	add	x4, x19, #0x40
ffffff8008753ea0:	39400080 	ldrb	w0, [x4]
ffffff8008753ea4:	53001c01 	ubfm	w1, w0, #0, #7
ffffff8008753ea8:	d5033d9f 	dsb	ld
ffffff8008753eac:	12800e20 	movn	w0, #0x71
ffffff8008753eb0:	2a000020 	orr	w0, w1, w0
ffffff8008753eb4:	39000080 	strb	w0, [x4]
ffffff8008753eb8:	17fffe78 	b	0xffffff8008753898
ffffff8008753ebc:	d5033e9f 	dsb	st
ffffff8008753ec0:	91015260 	add	x0, x19, #0x54
ffffff8008753ec4:	f90037a0 	str	x0, [x29, #104]
ffffff8008753ec8:	aa0003e1 	orr	x1, xzr, x0
ffffff8008753ecc:	394006a0 	ldrb	w0, [x21, #1]
ffffff8008753ed0:	39000020 	strb	w0, [x1]
ffffff8008753ed4:	39400021 	ldrb	w1, [x1]
ffffff8008753ed8:	53001c21 	ubfm	w1, w1, #0, #7
ffffff8008753edc:	d5033d9f 	dsb	ld
ffffff8008753ee0:	b0003dc0 	adrp	x0, 0xffffff8008f0c000
ffffff8008753ee4:	910d4000 	add	x0, x0, #0x350
ffffff8008753ee8:	97ea6a54 	bl	0xffffff80081ee838
ffffff8008753eec:	17fffe77 	b	0xffffff80087538c8
ffffff8008753ef0:	b0003dc0 	adrp	x0, 0xffffff8008f0c000
ffffff8008753ef4:	910dc000 	add	x0, x0, #0x370
ffffff8008753ef8:	97ea6a50 	bl	0xffffff80081ee838
ffffff8008753efc:	17fffe93 	b	0xffffff8008753948
ffffff8008753f00:	a9be7bfd 	stp	x29, x30, [sp, #-32]!
ffffff8008753f04:	910003fd 	add	x29, sp, #0x0
ffffff8008753f08:	f9000bf3 	str	x19, [sp, #16]
ffffff8008753f0c:	aa0003f3 	orr	x19, xzr, x0
ffffff8008753f10:	aa1e03e0 	orr	x0, xzr, x30
ffffff8008753f14:	d503201f 	hint	#0x0
ffffff8008753f18:	b9428e64 	ldr	w4, [x19, #652]
ffffff8008753f1c:	aa1303e0 	orr	x0, xzr, x19
ffffff8008753f20:	f9411e63 	ldr	x3, [x19, #568]
ffffff8008753f24:	f9412262 	ldr	x2, [x19, #576]
ffffff8008753f28:	f9411a61 	ldr	x1, [x19, #560]
ffffff8008753f2c:	97fffe0e 	bl	0xffffff8008753764
ffffff8008753f30:	f9400bf3 	ldr	x19, [sp, #16]
ffffff8008753f34:	a8c27bfd 	ldp	x29, x30, [sp], #32
ffffff8008753f38:	d65f03c0 	ret
ffffff8008753f3c:	a9bc7bfd 	stp	x29, x30, [sp, #-64]!
ffffff8008753f40:	910003fd 	add	x29, sp, #0x0
ffffff8008753f44:	a90153f3 	stp	x19, x20, [sp, #16]
ffffff8008753f48:	a9025bf5 	stp	x21, x22, [sp, #32]
ffffff8008753f4c:	a90363f7 	stp	x23, x24, [sp, #48]
ffffff8008753f50:	aa0003f4 	orr	x20, xzr, x0
ffffff8008753f54:	aa1e03e0 	orr	x0, xzr, x30
ffffff8008753f58:	d503201f 	hint	#0x0
ffffff8008753f5c:	97ff3b06 	bl	0xffffff8008722b74
ffffff8008753f60:	2a0003f3 	orr	w19, wzr, w0
ffffff8008753f64:	34000100 	cbz	w0, 0xffffff8008753f84
ffffff8008753f68:	12800253 	movn	w19, #0x12
ffffff8008753f6c:	2a1303e0 	orr	w0, wzr, w19
ffffff8008753f70:	a94153f3 	ldp	x19, x20, [sp, #16]
ffffff8008753f74:	a9425bf5 	ldp	x21, x22, [sp, #32]
ffffff8008753f78:	a94363f7 	ldp	x23, x24, [sp, #48]
ffffff8008753f7c:	a8c47bfd 	ldp	x29, x30, [sp], #64
ffffff8008753f80:	d65f03c0 	ret
ffffff8008753f84:	f9400281 	ldr	x1, [x20]
ffffff8008753f88:	b0003dc0 	adrp	x0, 0xffffff8008f0c000
ffffff8008753f8c:	910e2000 	add	x0, x0, #0x388
ffffff8008753f90:	97ea6a2a 	bl	0xffffff80081ee838
ffffff8008753f94:	f9405a80 	ldr	x0, [x20, #176]
ffffff8008753f98:	b4001fe0 	cbz	x0, 0xffffff8008754394
ffffff8008753f9c:	f940f680 	ldr	x0, [x20, #488]
ffffff8008753fa0:	b40014a0 	cbz	x0, 0xffffff8008754234
ffffff8008753fa4:	b1004296 	adds	x22, x20, #0x10
ffffff8008753fa8:	540014c0 	b.eq	0xffffff8008754240  // b.none
ffffff8008753fac:	f9410ec0 	ldr	x0, [x22, #536]
ffffff8008753fb0:	b4001480 	cbz	x0, 0xffffff8008754240
ffffff8008753fb4:	f9404002 	ldr	x2, [x0, #128]
ffffff8008753fb8:	b4001202 	cbz	x2, 0xffffff80087541f8
ffffff8008753fbc:	b2407fe1 	orr	x1, xzr, #0xffffffff
ffffff8008753fc0:	aa1603e0 	orr	x0, xzr, x22
ffffff8008753fc4:	d63f0040 	blr	x2
ffffff8008753fc8:	35000140 	cbnz	w0, 0xffffff8008753ff0
ffffff8008753fcc:	b4000e76 	cbz	x22, 0xffffff8008754198
ffffff8008753fd0:	f9410ec0 	ldr	x0, [x22, #536]
ffffff8008753fd4:	b4000e20 	cbz	x0, 0xffffff8008754198
ffffff8008753fd8:	f9403c02 	ldr	x2, [x0, #120]
ffffff8008753fdc:	b4000162 	cbz	x2, 0xffffff8008754008
ffffff8008753fe0:	b2407fe1 	orr	x1, xzr, #0xffffffff
ffffff8008753fe4:	aa1603e0 	orr	x0, xzr, x22
ffffff8008753fe8:	d63f0040 	blr	x2
ffffff8008753fec:	350000e0 	cbnz	w0, 0xffffff8008754008
ffffff8008753ff0:	b0003dc0 	adrp	x0, 0xffffff8008f0c000
ffffff8008753ff4:	b2407fe1 	orr	x1, xzr, #0xffffffff
ffffff8008753ff8:	91102000 	add	x0, x0, #0x408
ffffff8008753ffc:	12800bd3 	movn	w19, #0x5e
ffffff8008754000:	97ea6a0e 	bl	0xffffff80081ee838
ffffff8008754004:	17ffffda 	b	0xffffff8008753f6c
ffffff8008754008:	b2407fe1 	orr	x1, xzr, #0xffffffff
ffffff800875400c:	f900f2c1 	str	x1, [x22, #480]
ffffff8008754010:	90003dc0 	adrp	x0, 0xffffff8008f0c000
ffffff8008754014:	f940f682 	ldr	x2, [x20, #488]
ffffff8008754018:	910f2000 	add	x0, x0, #0x3c8
ffffff800875401c:	f9400042 	ldr	x2, [x2]
ffffff8008754020:	97ea6a06 	bl	0xffffff80081ee838
ffffff8008754024:	f9412280 	ldr	x0, [x20, #576]
ffffff8008754028:	52800001 	movz	w1, #0x0
ffffff800875402c:	9403fac5 	bl	0xffffff8008852b40
ffffff8008754030:	2a0003f8 	orr	w24, wzr, w0
ffffff8008754034:	90003dc2 	adrp	x2, 0xffffff8008f0c000
ffffff8008754038:	f00053c0 	adrp	x0, 0xffffff80091cf000
ffffff800875403c:	91100042 	add	x2, x2, #0x400
ffffff8008754040:	aa1603e1 	orr	x1, xzr, x22
ffffff8008754044:	91006000 	add	x0, x0, #0x18
ffffff8008754048:	97ff628b 	bl	0xffffff800872ca74
ffffff800875404c:	aa0003f5 	orr	x21, xzr, x0
ffffff8008754050:	b4001aa0 	cbz	x0, 0xffffff80087543a4
ffffff8008754054:	f9400297 	ldr	x23, [x20]
ffffff8008754058:	900039a1 	adrp	x1, 0xffffff8008e88000
ffffff800875405c:	d2800182 	movz	x2, #0xc
ffffff8008754060:	91064021 	add	x1, x1, #0x190
ffffff8008754064:	aa1703e0 	orr	x0, xzr, x23
ffffff8008754068:	97f8c8ee 	bl	0xffffff8008586420
ffffff800875406c:	35000660 	cbnz	w0, 0xffffff8008754138
ffffff8008754070:	90006020 	adrp	x0, 0xffffff8009358000
ffffff8008754074:	52800021 	movz	w1, #0x1
ffffff8008754078:	b9022ea1 	str	w1, [x21, #556]
ffffff800875407c:	528004f7 	movz	w23, #0x27
ffffff8008754080:	f9402401 	ldr	x1, [x0, #72]
ffffff8008754084:	91481c24 	add	x4, x1, #0x207, lsl #12
ffffff8008754088:	91481023 	add	x3, x1, #0x204, lsl #12
ffffff800875408c:	91480022 	add	x2, x1, #0x200, lsl #12
ffffff8008754090:	91491821 	add	x1, x1, #0x246, lsl #12
ffffff8008754094:	91140084 	add	x4, x4, #0x500
ffffff8008754098:	91200063 	add	x3, x3, #0x800
ffffff800875409c:	91380042 	add	x2, x2, #0xe00
ffffff80087540a0:	91300021 	add	x1, x1, #0xc00
ffffff80087540a4:	f9011aa4 	str	x4, [x21, #560]
ffffff80087540a8:	f9011ea3 	str	x3, [x21, #568]
ffffff80087540ac:	f90122a2 	str	x2, [x21, #576]
ffffff80087540b0:	f90126a1 	str	x1, [x21, #584]
ffffff80087540b4:	f9402400 	ldr	x0, [x0, #72]
ffffff80087540b8:	f9411ea1 	ldr	x1, [x21, #568]
ffffff80087540bc:	11480002 	add	w2, w0, #0x200, lsl #12
ffffff80087540c0:	4a000040 	eor	w0, w2, w0
ffffff80087540c4:	93407c00 	sbfm	x0, x0, #0, #31
ffffff80087540c8:	ea01001f 	ands	xzr, x0, x1
ffffff80087540cc:	54000101 	b.ne	0xffffff80087540ec  // b.any
ffffff80087540d0:	b9422ea1 	ldr	w1, [x21, #556]
ffffff80087540d4:	90003dc0 	adrp	x0, 0xffffff8008f0c000
ffffff80087540d8:	91118000 	add	x0, x0, #0x460
ffffff80087540dc:	97ea69d7 	bl	0xffffff80081ee838
ffffff80087540e0:	b9428aa0 	ldr	w0, [x21, #648]
ffffff80087540e4:	321c0000 	orr	w0, w0, #0x10
ffffff80087540e8:	b9028aa0 	str	w0, [x21, #648]
ffffff80087540ec:	f9412281 	ldr	x1, [x20, #576]
ffffff80087540f0:	aa1503e0 	orr	x0, xzr, x21
ffffff80087540f4:	12800178 	movn	w24, #0xb
ffffff80087540f8:	97fffcdd 	bl	0xffffff800875346c
ffffff80087540fc:	aa1503e0 	orr	x0, xzr, x21
ffffff8008754100:	97ffff80 	bl	0xffffff8008753f00
ffffff8008754104:	3944c2a0 	ldrb	w0, [x21, #304]
ffffff8008754108:	d2803f82 	movz	x2, #0x1fc
ffffff800875410c:	f9411ea1 	ldr	x1, [x21, #568]
ffffff8008754110:	321a0000 	orr	w0, w0, #0x40
ffffff8008754114:	f900a2a1 	str	x1, [x21, #320]
ffffff8008754118:	f900a6a2 	str	x2, [x21, #328]
ffffff800875411c:	3904c2a0 	strb	w0, [x21, #304]
ffffff8008754120:	f9009ea1 	str	x1, [x21, #312]
ffffff8008754124:	b5000a61 	cbnz	x1, 0xffffff8008754270
ffffff8008754128:	aa1503e0 	orr	x0, xzr, x21
ffffff800875412c:	2a1803f3 	orr	w19, wzr, w24
ffffff8008754130:	97ff61b2 	bl	0xffffff800872c7f8
ffffff8008754134:	17ffff8e 	b	0xffffff8008753f6c
ffffff8008754138:	900039a1 	adrp	x1, 0xffffff8008e88000
ffffff800875413c:	d2800182 	movz	x2, #0xc
ffffff8008754140:	91060021 	add	x1, x1, #0x180
ffffff8008754144:	aa1703e0 	orr	x0, xzr, x23
ffffff8008754148:	97f8c8b6 	bl	0xffffff8008586420
ffffff800875414c:	350002e0 	cbnz	w0, 0xffffff80087541a8
ffffff8008754150:	90006020 	adrp	x0, 0xffffff8009358000
ffffff8008754154:	52800041 	movz	w1, #0x2
ffffff8008754158:	b9022ea1 	str	w1, [x21, #556]
ffffff800875415c:	52800837 	movz	w23, #0x41
ffffff8008754160:	f9402401 	ldr	x1, [x0, #72]
ffffff8008754164:	91481c24 	add	x4, x1, #0x207, lsl #12
ffffff8008754168:	91480423 	add	x3, x1, #0x201, lsl #12
ffffff800875416c:	91480022 	add	x2, x1, #0x200, lsl #12
ffffff8008754170:	91491821 	add	x1, x1, #0x246, lsl #12
ffffff8008754174:	91100084 	add	x4, x4, #0x400
ffffff8008754178:	91280063 	add	x3, x3, #0xa00
ffffff800875417c:	913c0042 	add	x2, x2, #0xf00
ffffff8008754180:	91310021 	add	x1, x1, #0xc40
ffffff8008754184:	f9011aa4 	str	x4, [x21, #560]
ffffff8008754188:	f9011ea3 	str	x3, [x21, #568]
ffffff800875418c:	f90122a2 	str	x2, [x21, #576]
ffffff8008754190:	f90126a1 	str	x1, [x21, #584]
ffffff8008754194:	17ffffc8 	b	0xffffff80087540b4
ffffff8008754198:	90006020 	adrp	x0, 0xffffff8009358000
ffffff800875419c:	f947a000 	ldr	x0, [x0, #3904]
ffffff80087541a0:	b4fff280 	cbz	x0, 0xffffff8008753ff0
ffffff80087541a4:	17ffff8d 	b	0xffffff8008753fd8
ffffff80087541a8:	900039a1 	adrp	x1, 0xffffff8008e88000
ffffff80087541ac:	d2800182 	movz	x2, #0xc
ffffff80087541b0:	9105c021 	add	x1, x1, #0x170
ffffff80087541b4:	aa1703e0 	orr	x0, xzr, x23
ffffff80087541b8:	97f8c89a 	bl	0xffffff8008586420
ffffff80087541bc:	35000480 	cbnz	w0, 0xffffff800875424c
ffffff80087541c0:	90006020 	adrp	x0, 0xffffff8009358000
ffffff80087541c4:	52800061 	movz	w1, #0x3
ffffff80087541c8:	b9022ea1 	str	w1, [x21, #556]
ffffff80087541cc:	52800897 	movz	w23, #0x44
ffffff80087541d0:	f9402401 	ldr	x1, [x0, #72]
ffffff80087541d4:	91408821 	add	x1, x1, #0x22, lsl #12
ffffff80087541d8:	f90126a1 	str	x1, [x21, #584]
ffffff80087541dc:	91240023 	add	x3, x1, #0x900
ffffff80087541e0:	91180022 	add	x2, x1, #0x600
ffffff80087541e4:	f9011aa3 	str	x3, [x21, #560]
ffffff80087541e8:	91100021 	add	x1, x1, #0x400
ffffff80087541ec:	f9011ea2 	str	x2, [x21, #568]
ffffff80087541f0:	f90122a1 	str	x1, [x21, #576]
ffffff80087541f4:	17ffffb0 	b	0xffffff80087540b4
ffffff80087541f8:	f940eec0 	ldr	x0, [x22, #472]
ffffff80087541fc:	b4ffefa0 	cbz	x0, 0xffffff8008753ff0
ffffff8008754200:	b4000c36 	cbz	x22, 0xffffff8008754384
ffffff8008754204:	f9410ec0 	ldr	x0, [x22, #536]
ffffff8008754208:	b4000be0 	cbz	x0, 0xffffff8008754384
ffffff800875420c:	f9403c02 	ldr	x2, [x0, #120]
ffffff8008754210:	b40000a2 	cbz	x2, 0xffffff8008754224
ffffff8008754214:	b2407fe1 	orr	x1, xzr, #0xffffffff
ffffff8008754218:	aa1603e0 	orr	x0, xzr, x22
ffffff800875421c:	d63f0040 	blr	x2
ffffff8008754220:	34ffee80 	cbz	w0, 0xffffff8008753ff0
ffffff8008754224:	f940eec0 	ldr	x0, [x22, #472]
ffffff8008754228:	b2407fe1 	orr	x1, xzr, #0xffffffff
ffffff800875422c:	f9000001 	str	x1, [x0]
ffffff8008754230:	17ffff67 	b	0xffffff8008753fcc
ffffff8008754234:	9107c280 	add	x0, x20, #0x1f0
ffffff8008754238:	f900f680 	str	x0, [x20, #488]
ffffff800875423c:	17ffff5a 	b	0xffffff8008753fa4
ffffff8008754240:	90006020 	adrp	x0, 0xffffff8009358000
ffffff8008754244:	f947a000 	ldr	x0, [x0, #3904]
ffffff8008754248:	17ffff5b 	b	0xffffff8008753fb4
ffffff800875424c:	900039a1 	adrp	x1, 0xffffff8008e88000
ffffff8008754250:	d2800182 	movz	x2, #0xc
ffffff8008754254:	91058021 	add	x1, x1, #0x160
ffffff8008754258:	aa1703e0 	orr	x0, xzr, x23
ffffff800875425c:	97f8c871 	bl	0xffffff8008586420
ffffff8008754260:	34000a60 	cbz	w0, 0xffffff80087543ac
ffffff8008754264:	2a1803f7 	orr	w23, wzr, w24
ffffff8008754268:	90006020 	adrp	x0, 0xffffff8009358000
ffffff800875426c:	17ffff92 	b	0xffffff80087540b4
ffffff8008754270:	910b22a2 	add	x2, x21, #0x2c8
ffffff8008754274:	9278dc20 	and	x0, x1, #0xffffffffffffff00
ffffff8008754278:	f9006041 	str	x1, [x2, #192]
ffffff800875427c:	8b210400 	add	x0, x0, w1, uxtb #1
ffffff8008754280:	b9400004 	ldr	w4, [x0]
ffffff8008754284:	d5033d9f 	dsb	ld
ffffff8008754288:	91001000 	add	x0, x0, #0x4
ffffff800875428c:	b9400000 	ldr	w0, [x0]
ffffff8008754290:	d5033d9f 	dsb	ld
ffffff8008754294:	f9406043 	ldr	x3, [x2, #192]
ffffff8008754298:	8b240021 	add	x1, x1, w4, uxtb
ffffff800875429c:	f9006441 	str	x1, [x2, #200]
ffffff80087542a0:	91001063 	add	x3, x3, #0x4
ffffff80087542a4:	9278dc60 	and	x0, x3, #0xffffffffffffff00
ffffff80087542a8:	8b230403 	add	x3, x0, w3, uxtb #1
ffffff80087542ac:	b9400060 	ldr	w0, [x3]
ffffff80087542b0:	d5033d9f 	dsb	ld
ffffff80087542b4:	91001063 	add	x3, x3, #0x4
ffffff80087542b8:	b9400063 	ldr	w3, [x3]
ffffff80087542bc:	d5033d9f 	dsb	ld
ffffff80087542c0:	12003c00 	and	w0, w0, #0xffff
ffffff80087542c4:	52800001 	movz	w1, #0x0
ffffff80087542c8:	2a034003 	orr	w3, w0, w3, lsl #16
ffffff80087542cc:	aa1503e0 	orr	x0, xzr, x21
ffffff80087542d0:	b900d843 	str	w3, [x2, #216]
ffffff80087542d4:	97ffc6fc 	bl	0xffffff8008745ec4
ffffff80087542d8:	52800021 	movz	w1, #0x1
ffffff80087542dc:	aa1503e0 	orr	x0, xzr, x21
ffffff80087542e0:	97ffc67f 	bl	0xffffff8008745cdc
ffffff80087542e4:	f9400281 	ldr	x1, [x20]
ffffff80087542e8:	90003dc0 	adrp	x0, 0xffffff8008f0c000
ffffff80087542ec:	2a1703e2 	orr	w2, wzr, w23
ffffff80087542f0:	9110e000 	add	x0, x0, #0x438
ffffff80087542f4:	97ea6951 	bl	0xffffff80081ee838
ffffff80087542f8:	d2800002 	movz	x2, #0x0
ffffff80087542fc:	2a1703e1 	orr	w1, wzr, w23
ffffff8008754300:	aa1503e0 	orr	x0, xzr, x21
ffffff8008754304:	97ff649a 	bl	0xffffff800872d56c
ffffff8008754308:	2a0003f8 	orr	w24, wzr, w0
ffffff800875430c:	90006603 	adrp	x3, 0xffffff8009414000
ffffff8008754310:	90000005 	adrp	x5, 0xffffff8008754000
ffffff8008754314:	91018063 	add	x3, x3, #0x60
ffffff8008754318:	f0ffffc4 	adrp	x4, 0xffffff800874f000
ffffff800875431c:	90003dc0 	adrp	x0, 0xffffff8008f0c000
ffffff8008754320:	9100a062 	add	x2, x3, #0x28
ffffff8008754324:	aa1603e1 	orr	x1, xzr, x22
ffffff8008754328:	91043084 	add	x4, x4, #0x10c
ffffff800875432c:	b90292bf 	str	wzr, [x21, #656]
ffffff8008754330:	d2800007 	movz	x7, #0x0
ffffff8008754334:	390a52bf 	strb	wzr, [x21, #660]
ffffff8008754338:	d2800006 	movz	x6, #0x0
ffffff800875433c:	390a56bf 	strb	wzr, [x21, #661]
ffffff8008754340:	910fa0a5 	add	x5, x5, #0x3e8
ffffff8008754344:	790542bf 	strh	wzr, [x21, #672]
ffffff8008754348:	91114000 	add	x0, x0, #0x450
ffffff800875434c:	790546bf 	strh	wzr, [x21, #674]
ffffff8008754350:	97fca1f7 	bl	0xffffff800867cb2c
ffffff8008754354:	f0005882 	adrp	x2, 0xffffff8009267000
ffffff8008754358:	f94002a0 	ldr	x0, [x21]
ffffff800875435c:	91378042 	add	x2, x2, #0xde0
ffffff8008754360:	528036c3 	movz	w3, #0x1b6
ffffff8008754364:	91012042 	add	x2, x2, #0x48
ffffff8008754368:	aa0203e1 	orr	x1, xzr, x2
ffffff800875436c:	79401044 	ldrh	w4, [x2, #8]
ffffff8008754370:	2a030083 	orr	w3, w4, w3
ffffff8008754374:	79001043 	strh	w3, [x2, #8]
ffffff8008754378:	97fc383c 	bl	0xffffff8008662468
ffffff800875437c:	35ffed78 	cbnz	w24, 0xffffff8008754128
ffffff8008754380:	17fffefb 	b	0xffffff8008753f6c
ffffff8008754384:	90006020 	adrp	x0, 0xffffff8009358000
ffffff8008754388:	f947a000 	ldr	x0, [x0, #3904]
ffffff800875438c:	b4ffe320 	cbz	x0, 0xffffff8008753ff0
ffffff8008754390:	17ffff9f 	b	0xffffff800875420c
ffffff8008754394:	90003dc0 	adrp	x0, 0xffffff8008f0c000
ffffff8008754398:	910e6000 	add	x0, x0, #0x398
ffffff800875439c:	97ea6927 	bl	0xffffff80081ee838
ffffff80087543a0:	17fffeff 	b	0xffffff8008753f9c
ffffff80087543a4:	12800173 	movn	w19, #0xb
ffffff80087543a8:	17fffef1 	b	0xffffff8008753f6c
ffffff80087543ac:	90006020 	adrp	x0, 0xffffff8009358000
ffffff80087543b0:	52800081 	movz	w1, #0x4
ffffff80087543b4:	b9022ea1 	str	w1, [x21, #556]
ffffff80087543b8:	52800bd7 	movz	w23, #0x5e
ffffff80087543bc:	f9402401 	ldr	x1, [x0, #72]
ffffff80087543c0:	915b8821 	add	x1, x1, #0x6e2, lsl #12
ffffff80087543c4:	91100024 	add	x4, x1, #0x400
ffffff80087543c8:	91200023 	add	x3, x1, #0x800
ffffff80087543cc:	91080022 	add	x2, x1, #0x200
ffffff80087543d0:	f9011aa4 	str	x4, [x21, #560]
ffffff80087543d4:	91190021 	add	x1, x1, #0x640
ffffff80087543d8:	f9011ea3 	str	x3, [x21, #568]
ffffff80087543dc:	f90122a2 	str	x2, [x21, #576]
ffffff80087543e0:	f90126a1 	str	x1, [x21, #584]
ffffff80087543e4:	17ffff34 	b	0xffffff80087540b4
ffffff80087543e8:	a9be7bfd 	stp	x29, x30, [sp, #-32]!
ffffff80087543ec:	910003fd 	add	x29, sp, #0x0
ffffff80087543f0:	f9000bf3 	str	x19, [sp, #16]
ffffff80087543f4:	aa0003f3 	orr	x19, xzr, x0
ffffff80087543f8:	aa1e03e0 	orr	x0, xzr, x30
ffffff80087543fc:	d503201f 	hint	#0x0
ffffff8008754400:	f100427f 	subs	xzr, x19, #0x10
ffffff8008754404:	540010a0 	b.eq	0xffffff8008754618  // b.none
ffffff8008754408:	90006600 	adrp	x0, 0xffffff8009414000
ffffff800875440c:	f9403400 	ldr	x0, [x0, #104]
ffffff8008754410:	b4000060 	cbz	x0, 0xffffff800875441c
ffffff8008754414:	91034000 	add	x0, x0, #0xd0
ffffff8008754418:	94154ff0 	bl	0xffffff8008ca83d8
ffffff800875441c:	f9405673 	ldr	x19, [x19, #168]
ffffff8008754420:	90003dc0 	adrp	x0, 0xffffff8008f0c000
ffffff8008754424:	91122000 	add	x0, x0, #0x488
ffffff8008754428:	b9422e61 	ldr	w1, [x19, #556]
ffffff800875442c:	97ea6903 	bl	0xffffff80081ee838
ffffff8008754430:	b9428a60 	ldr	w0, [x19, #648]
ffffff8008754434:	910b2262 	add	x2, x19, #0x2c8
ffffff8008754438:	372003e0 	tbnz	w0, #4, 0xffffff80087544b4
ffffff800875443c:	f9406441 	ldr	x1, [x2, #200]
ffffff8008754440:	91007021 	add	x1, x1, #0x1c
ffffff8008754444:	9278dc20 	and	x0, x1, #0xffffffffffffff00
ffffff8008754448:	8b210401 	add	x1, x0, w1, uxtb #1
ffffff800875444c:	b9400020 	ldr	w0, [x1]
ffffff8008754450:	d5033d9f 	dsb	ld
ffffff8008754454:	91001021 	add	x1, x1, #0x4
ffffff8008754458:	b9400022 	ldr	w2, [x1]
ffffff800875445c:	d5033d9f 	dsb	ld
ffffff8008754460:	12003c01 	and	w1, w0, #0xffff
ffffff8008754464:	2a024021 	orr	w1, w1, w2, lsl #16
ffffff8008754468:	7100043f 	subs	wzr, w1, #0x1
ffffff800875446c:	540000c0 	b.eq	0xffffff8008754484  // b.none
ffffff8008754470:	aa1303e0 	orr	x0, xzr, x19
ffffff8008754474:	97fffea3 	bl	0xffffff8008753f00
ffffff8008754478:	52800001 	movz	w1, #0x0
ffffff800875447c:	aa1303e0 	orr	x0, xzr, x19
ffffff8008754480:	97ffc691 	bl	0xffffff8008745ec4
ffffff8008754484:	52800001 	movz	w1, #0x0
ffffff8008754488:	aa1303e0 	orr	x0, xzr, x19
ffffff800875448c:	97ffdb52 	bl	0xffffff800874b1d4
ffffff8008754490:	9104a261 	add	x1, x19, #0x128
ffffff8008754494:	52800040 	movz	w0, #0x2
ffffff8008754498:	97f8c282 	bl	0xffffff8008584ea0
ffffff800875449c:	aa1303e0 	orr	x0, xzr, x19
ffffff80087544a0:	97ff63cc 	bl	0xffffff800872d3d0
ffffff80087544a4:	f9400bf3 	ldr	x19, [sp, #16]
ffffff80087544a8:	52800000 	movz	w0, #0x0
ffffff80087544ac:	a8c27bfd 	ldp	x29, x30, [sp], #32
ffffff80087544b0:	d65f03c0 	ret
ffffff80087544b4:	d5033e9f 	dsb	st
ffffff80087544b8:	f9411a60 	ldr	x0, [x19, #560]
ffffff80087544bc:	91008000 	add	x0, x0, #0x20
ffffff80087544c0:	39400000 	ldrb	w0, [x0]
ffffff80087544c4:	53001c00 	ubfm	w0, w0, #0, #7
ffffff80087544c8:	d5033d9f 	dsb	ld
ffffff80087544cc:	f9411a61 	ldr	x1, [x19, #560]
ffffff80087544d0:	321a0000 	orr	w0, w0, #0x40
ffffff80087544d4:	91008021 	add	x1, x1, #0x20
ffffff80087544d8:	39000020 	strb	w0, [x1]
ffffff80087544dc:	d5033e9f 	dsb	st
ffffff80087544e0:	f9411a60 	ldr	x0, [x19, #560]
ffffff80087544e4:	91000400 	add	x0, x0, #0x1
ffffff80087544e8:	39400000 	ldrb	w0, [x0]
ffffff80087544ec:	53001c00 	ubfm	w0, w0, #0, #7
ffffff80087544f0:	d5033d9f 	dsb	ld
ffffff80087544f4:	f9411a61 	ldr	x1, [x19, #560]
ffffff80087544f8:	12196000 	and	w0, w0, #0xffffff80
ffffff80087544fc:	91000421 	add	x1, x1, #0x1
ffffff8008754500:	39000020 	strb	w0, [x1]
ffffff8008754504:	d5033e9f 	dsb	st
ffffff8008754508:	f9411a60 	ldr	x0, [x19, #560]
ffffff800875450c:	39400000 	ldrb	w0, [x0]
ffffff8008754510:	53001c00 	ubfm	w0, w0, #0, #7
ffffff8008754514:	d5033d9f 	dsb	ld
ffffff8008754518:	121d7800 	and	w0, w0, #0xfffffffb
ffffff800875451c:	f9411a61 	ldr	x1, [x19, #560]
ffffff8008754520:	39000020 	strb	w0, [x1]
ffffff8008754524:	90006021 	adrp	x1, 0xffffff8009358000
ffffff8008754528:	f9402420 	ldr	x0, [x1, #72]
ffffff800875452c:	91408800 	add	x0, x0, #0x22, lsl #12
ffffff8008754530:	91080000 	add	x0, x0, #0x200
ffffff8008754534:	39400000 	ldrb	w0, [x0]
ffffff8008754538:	53001c00 	ubfm	w0, w0, #0, #7
ffffff800875453c:	d5033d9f 	dsb	ld
ffffff8008754540:	d5033e9f 	dsb	st
ffffff8008754544:	f9402421 	ldr	x1, [x1, #72]
ffffff8008754548:	121e7800 	and	w0, w0, #0xfffffffd
ffffff800875454c:	91408821 	add	x1, x1, #0x22, lsl #12
ffffff8008754550:	91080021 	add	x1, x1, #0x200
ffffff8008754554:	39000020 	strb	w0, [x1]
ffffff8008754558:	d28dbc00 	movz	x0, #0x6de0
ffffff800875455c:	f2a00680 	movk	x0, #0x34, lsl #16
ffffff8008754560:	97f8c51e 	bl	0xffffff80085859d8
ffffff8008754564:	b9428a60 	ldr	w0, [x19, #648]
ffffff8008754568:	910b2262 	add	x2, x19, #0x2c8
ffffff800875456c:	361ff680 	tbz	w0, #3, 0xffffff800875443c
ffffff8008754570:	f9406441 	ldr	x1, [x2, #200]
ffffff8008754574:	91009020 	add	x0, x1, #0x24
ffffff8008754578:	9278dc01 	and	x1, x0, #0xffffffffffffff00
ffffff800875457c:	8b200421 	add	x1, x1, w0, uxtb #1
ffffff8008754580:	b9400020 	ldr	w0, [x1]
ffffff8008754584:	d5033d9f 	dsb	ld
ffffff8008754588:	91001021 	add	x1, x1, #0x4
ffffff800875458c:	b9400021 	ldr	w1, [x1]
ffffff8008754590:	d5033d9f 	dsb	ld
ffffff8008754594:	f9406443 	ldr	x3, [x2, #200]
ffffff8008754598:	12003c00 	and	w0, w0, #0xffff
ffffff800875459c:	2a014000 	orr	w0, w0, w1, lsl #16
ffffff80087545a0:	91009061 	add	x1, x3, #0x24
ffffff80087545a4:	9278dc23 	and	x3, x1, #0xffffffffffffff00
ffffff80087545a8:	8b210461 	add	x1, x3, w1, uxtb #1
ffffff80087545ac:	d5033e9f 	dsb	st
ffffff80087545b0:	12003c03 	and	w3, w0, #0xffff
ffffff80087545b4:	321a0063 	orr	w3, w3, #0x40
ffffff80087545b8:	b9000023 	str	w3, [x1]
ffffff80087545bc:	d5033e9f 	dsb	st
ffffff80087545c0:	53107c00 	ubfm	w0, w0, #16, #31
ffffff80087545c4:	91001021 	add	x1, x1, #0x4
ffffff80087545c8:	b9000020 	str	w0, [x1]
ffffff80087545cc:	f9406440 	ldr	x0, [x2, #200]
ffffff80087545d0:	91009000 	add	x0, x0, #0x24
ffffff80087545d4:	9278dc01 	and	x1, x0, #0xffffffffffffff00
ffffff80087545d8:	8b200420 	add	x0, x1, w0, uxtb #1
ffffff80087545dc:	b9400001 	ldr	w1, [x0]
ffffff80087545e0:	d5033d9f 	dsb	ld
ffffff80087545e4:	91001000 	add	x0, x0, #0x4
ffffff80087545e8:	b9400000 	ldr	w0, [x0]
ffffff80087545ec:	d5033d9f 	dsb	ld
ffffff80087545f0:	f9406440 	ldr	x0, [x2, #200]
ffffff80087545f4:	91008000 	add	x0, x0, #0x20
ffffff80087545f8:	9278dc01 	and	x1, x0, #0xffffffffffffff00
ffffff80087545fc:	8b200420 	add	x0, x1, w0, uxtb #1
ffffff8008754600:	b9400001 	ldr	w1, [x0]
ffffff8008754604:	d5033d9f 	dsb	ld
ffffff8008754608:	91001000 	add	x0, x0, #0x4
ffffff800875460c:	b9400000 	ldr	w0, [x0]
ffffff8008754610:	d5033d9f 	dsb	ld
ffffff8008754614:	17ffff8a 	b	0xffffff800875443c
ffffff8008754618:	d4210000 	brk	#0x800
ffffff800875461c:	12800240 	movn	w0, #0x12
ffffff8008754620:	f9400bf3 	ldr	x19, [sp, #16]
ffffff8008754624:	a8c27bfd 	ldp	x29, x30, [sp], #32
ffffff8008754628:	d65f03c0 	ret
ffffff800875462c:	a9bd7bfd 	stp	x29, x30, [sp, #-48]!
ffffff8008754630:	910003fd 	add	x29, sp, #0x0
ffffff8008754634:	f9000bf3 	str	x19, [sp, #16]
ffffff8008754638:	aa0003f3 	orr	x19, xzr, x0
ffffff800875463c:	aa1e03e0 	orr	x0, xzr, x30
ffffff8008754640:	b9002fa1 	str	w1, [x29, #44]
ffffff8008754644:	d503201f 	hint	#0x0
ffffff8008754648:	b9402fa1 	ldr	w1, [x29, #44]
ffffff800875464c:	340002a1 	cbz	w1, 0xffffff80087546a0
ffffff8008754650:	910b2260 	add	x0, x19, #0x2c8
ffffff8008754654:	51000421 	sub	w1, w1, #0x1
ffffff8008754658:	f9400402 	ldr	x2, [x0, #8]
ffffff800875465c:	91004021 	add	x1, x1, #0x10
ffffff8008754660:	d37ef421 	ubfm	x1, x1, #62, #61
ffffff8008754664:	8b010042 	add	x2, x2, x1
ffffff8008754668:	91005042 	add	x2, x2, #0x14
ffffff800875466c:	b9400042 	ldr	w2, [x2]
ffffff8008754670:	d5033d9f 	dsb	ld
ffffff8008754674:	360001a2 	tbz	w2, #0, 0xffffff80087546a8
ffffff8008754678:	f9400400 	ldr	x0, [x0, #8]
ffffff800875467c:	8b010001 	add	x1, x0, x1
ffffff8008754680:	91005021 	add	x1, x1, #0x14
ffffff8008754684:	d5033e9f 	dsb	st
ffffff8008754688:	52800200 	movz	w0, #0x10
ffffff800875468c:	b9000020 	str	w0, [x1]
ffffff8008754690:	52800000 	movz	w0, #0x0
ffffff8008754694:	f9400bf3 	ldr	x19, [sp, #16]
ffffff8008754698:	a8c37bfd 	ldp	x29, x30, [sp], #48
ffffff800875469c:	d65f03c0 	ret
ffffff80087546a0:	128002a0 	movn	w0, #0x15
ffffff80087546a4:	17fffffc 	b	0xffffff8008754694
ffffff80087546a8:	12800240 	movn	w0, #0x12
ffffff80087546ac:	17fffffa 	b	0xffffff8008754694
ffffff80087546b0:	a9bd7bfd 	stp	x29, x30, [sp, #-48]!
ffffff80087546b4:	910003fd 	add	x29, sp, #0x0
ffffff80087546b8:	f9000bf3 	str	x19, [sp, #16]
ffffff80087546bc:	aa0003f3 	orr	x19, xzr, x0
ffffff80087546c0:	aa1e03e0 	orr	x0, xzr, x30
ffffff80087546c4:	f90017a1 	str	x1, [x29, #40]
ffffff80087546c8:	d503201f 	hint	#0x0
ffffff80087546cc:	f94017a1 	ldr	x1, [x29, #40]
ffffff80087546d0:	b9400020 	ldr	w0, [x1]
ffffff80087546d4:	32120000 	orr	w0, w0, #0x4000
ffffff80087546d8:	b9000020 	str	w0, [x1]
ffffff80087546dc:	d5033e9f 	dsb	st
ffffff80087546e0:	39414420 	ldrb	w0, [x1, #81]
ffffff80087546e4:	52800022 	movz	w2, #0x1
ffffff80087546e8:	39014022 	strb	w2, [x1, #80]
ffffff80087546ec:	7100081f 	subs	wzr, w0, #0x2
ffffff80087546f0:	540007c0 	b.eq	0xffffff80087547e8  // b.none
ffffff80087546f4:	71000c1f 	subs	wzr, w0, #0x3
ffffff80087546f8:	54000241 	b.ne	0xffffff8008754740  // b.any
ffffff80087546fc:	f9401420 	ldr	x0, [x1, #40]
ffffff8008754700:	b4000b60 	cbz	x0, 0xffffff800875486c
ffffff8008754704:	f9401022 	ldr	x2, [x1, #32]
ffffff8008754708:	f9001002 	str	x2, [x0, #32]
ffffff800875470c:	f9401420 	ldr	x0, [x1, #40]
ffffff8008754710:	b9400c22 	ldr	w2, [x1, #12]
ffffff8008754714:	b9000c02 	str	w2, [x0, #12]
ffffff8008754718:	f9401660 	ldr	x0, [x19, #40]
ffffff800875471c:	eb01001f 	subs	xzr, x0, x1
ffffff8008754720:	540009c0 	b.eq	0xffffff8008754858  // b.none
ffffff8008754724:	f9401020 	ldr	x0, [x1, #32]
ffffff8008754728:	b4000060 	cbz	x0, 0xffffff8008754734
ffffff800875472c:	f9401421 	ldr	x1, [x1, #40]
ffffff8008754730:	f9001401 	str	x1, [x0, #40]
ffffff8008754734:	f9400bf3 	ldr	x19, [sp, #16]
ffffff8008754738:	a8c37bfd 	ldp	x29, x30, [sp], #48
ffffff800875473c:	d65f03c0 	ret
ffffff8008754740:	39414825 	ldrb	w5, [x1, #82]
ffffff8008754744:	71007cbf 	subs	wzr, w5, #0x1f
ffffff8008754748:	54000bac 	b.gt	0xffffff80087548bc
ffffff800875474c:	93407ca4 	sbfm	x4, x5, #0, #31
ffffff8008754750:	f9400a60 	ldr	x0, [x19, #16]
ffffff8008754754:	91001883 	add	x3, x4, #0x6
ffffff8008754758:	8b030e62 	add	x2, x19, x3, lsl #3
ffffff800875475c:	f9400443 	ldr	x3, [x2, #8]
ffffff8008754760:	b4000123 	cbz	x3, 0xffffff8008754784
ffffff8008754764:	eb03003f 	subs	xzr, x1, x3
ffffff8008754768:	54000081 	b.ne	0xffffff8008754778  // b.any
ffffff800875476c:	1400002e 	b	0xffffff8008754824
ffffff8008754770:	540002e0 	b.eq	0xffffff80087547cc  // b.none
ffffff8008754774:	aa0203e3 	orr	x3, xzr, x2
ffffff8008754778:	f9401062 	ldr	x2, [x3, #32]
ffffff800875477c:	eb02003f 	subs	xzr, x1, x2
ffffff8008754780:	b5ffff82 	cbnz	x2, 0xffffff8008754770
ffffff8008754784:	8b040a64 	add	x4, x19, x4, lsl #2
ffffff8008754788:	7940ac20 	ldrh	w0, [x1, #86]
ffffff800875478c:	b9438882 	ldr	w2, [x4, #904]
ffffff8008754790:	4b000042 	sub	w2, w2, w0
ffffff8008754794:	b9038882 	str	w2, [x4, #904]
ffffff8008754798:	7940a820 	ldrh	w0, [x1, #84]
ffffff800875479c:	0b0000a5 	add	w5, w5, w0
ffffff80087547a0:	71007cbf 	subs	wzr, w5, #0x1f
ffffff80087547a4:	54fffd4d 	b.le	0xffffff800875474c
ffffff80087547a8:	7940ac22 	ldrh	w2, [x1, #86]
ffffff80087547ac:	d10b2273 	sub	x19, x19, #0x2c8
ffffff80087547b0:	1ac00840 	udiv	w0, w2, w0
ffffff80087547b4:	b9407a61 	ldr	w1, [x19, #120]
ffffff80087547b8:	4b000020 	sub	w0, w1, w0
ffffff80087547bc:	b9007a60 	str	w0, [x19, #120]
ffffff80087547c0:	f9400bf3 	ldr	x19, [sp, #16]
ffffff80087547c4:	a8c37bfd 	ldp	x29, x30, [sp], #48
ffffff80087547c8:	d65f03c0 	ret
ffffff80087547cc:	91003060 	add	x0, x3, #0xc
ffffff80087547d0:	91008063 	add	x3, x3, #0x20
ffffff80087547d4:	b9400c22 	ldr	w2, [x1, #12]
ffffff80087547d8:	b9000002 	str	w2, [x0]
ffffff80087547dc:	f9401020 	ldr	x0, [x1, #32]
ffffff80087547e0:	f9000060 	str	x0, [x3]
ffffff80087547e4:	17ffffe8 	b	0xffffff8008754784
ffffff80087547e8:	f9401420 	ldr	x0, [x1, #40]
ffffff80087547ec:	b4000220 	cbz	x0, 0xffffff8008754830
ffffff80087547f0:	f9401022 	ldr	x2, [x1, #32]
ffffff80087547f4:	f9001002 	str	x2, [x0, #32]
ffffff80087547f8:	f9401420 	ldr	x0, [x1, #40]
ffffff80087547fc:	b9400c22 	ldr	w2, [x1, #12]
ffffff8008754800:	b9000c02 	str	w2, [x0, #12]
ffffff8008754804:	f9401a60 	ldr	x0, [x19, #48]
ffffff8008754808:	eb01001f 	subs	xzr, x0, x1
ffffff800875480c:	54fff8c1 	b.ne	0xffffff8008754724  // b.any
ffffff8008754810:	f9401420 	ldr	x0, [x1, #40]
ffffff8008754814:	f9001a60 	str	x0, [x19, #48]
ffffff8008754818:	b4fff8e0 	cbz	x0, 0xffffff8008754734
ffffff800875481c:	f900101f 	str	xzr, [x0, #32]
ffffff8008754820:	17ffffc5 	b	0xffffff8008754734
ffffff8008754824:	91002043 	add	x3, x2, #0x8
ffffff8008754828:	8b040800 	add	x0, x0, x4, lsl #2
ffffff800875482c:	17ffffea 	b	0xffffff80087547d4
ffffff8008754830:	b9400c22 	ldr	w2, [x1, #12]
ffffff8008754834:	350003a2 	cbnz	w2, 0xffffff80087548a8
ffffff8008754838:	b9440a60 	ldr	w0, [x19, #1032]
ffffff800875483c:	f9400662 	ldr	x2, [x19, #8]
ffffff8008754840:	121b7800 	and	w0, w0, #0xffffffef
ffffff8008754844:	b9040a60 	str	w0, [x19, #1032]
ffffff8008754848:	91001042 	add	x2, x2, #0x4
ffffff800875484c:	d5033e9f 	dsb	st
ffffff8008754850:	b9000040 	str	w0, [x2]
ffffff8008754854:	17ffffec 	b	0xffffff8008754804
ffffff8008754858:	f9401420 	ldr	x0, [x1, #40]
ffffff800875485c:	f9001660 	str	x0, [x19, #40]
ffffff8008754860:	b4fff6a0 	cbz	x0, 0xffffff8008754734
ffffff8008754864:	f900101f 	str	xzr, [x0, #32]
ffffff8008754868:	17ffffb3 	b	0xffffff8008754734
ffffff800875486c:	b9400c22 	ldr	w2, [x1, #12]
ffffff8008754870:	35000122 	cbnz	w2, 0xffffff8008754894
ffffff8008754874:	b9440a60 	ldr	w0, [x19, #1032]
ffffff8008754878:	f9400662 	ldr	x2, [x19, #8]
ffffff800875487c:	121a7800 	and	w0, w0, #0xffffffdf
ffffff8008754880:	b9040a60 	str	w0, [x19, #1032]
ffffff8008754884:	91001042 	add	x2, x2, #0x4
ffffff8008754888:	d5033e9f 	dsb	st
ffffff800875488c:	b9000040 	str	w0, [x2]
ffffff8008754890:	17ffffa2 	b	0xffffff8008754718
ffffff8008754894:	f9400660 	ldr	x0, [x19, #8]
ffffff8008754898:	9100a000 	add	x0, x0, #0x28
ffffff800875489c:	d5033e9f 	dsb	st
ffffff80087548a0:	b9000002 	str	w2, [x0]
ffffff80087548a4:	17ffff9d 	b	0xffffff8008754718
ffffff80087548a8:	f9400660 	ldr	x0, [x19, #8]
ffffff80087548ac:	91008000 	add	x0, x0, #0x20
ffffff80087548b0:	d5033e9f 	dsb	st
ffffff80087548b4:	b9000002 	str	w2, [x0]
ffffff80087548b8:	17ffffd3 	b	0xffffff8008754804
ffffff80087548bc:	7940a820 	ldrh	w0, [x1, #84]
ffffff80087548c0:	17ffffba 	b	0xffffff80087547a8
ffffff80087548c4:	a9be7bfd 	stp	x29, x30, [sp, #-32]!
ffffff80087548c8:	910003fd 	add	x29, sp, #0x0
ffffff80087548cc:	a90153f3 	stp	x19, x20, [sp, #16]
ffffff80087548d0:	aa0103f3 	orr	x19, xzr, x1
ffffff80087548d4:	aa0003f4 	orr	x20, xzr, x0
ffffff80087548d8:	aa1e03e0 	orr	x0, xzr, x30
ffffff80087548dc:	d503201f 	hint	#0x0
ffffff80087548e0:	b9400262 	ldr	w2, [x19]
ffffff80087548e4:	aa1403e0 	orr	x0, xzr, x20
ffffff80087548e8:	aa1303e1 	orr	x1, xzr, x19
ffffff80087548ec:	32050042 	orr	w2, w2, #0x8000000
ffffff80087548f0:	b9000262 	str	w2, [x19]
ffffff80087548f4:	97ffff6f 	bl	0xffffff80087546b0
ffffff80087548f8:	f9401280 	ldr	x0, [x20, #32]
ffffff80087548fc:	f9001260 	str	x0, [x19, #32]
ffffff8008754900:	f900167f 	str	xzr, [x19, #40]
ffffff8008754904:	f9001293 	str	x19, [x20, #32]
ffffff8008754908:	f9400680 	ldr	x0, [x20, #8]
ffffff800875490c:	91003000 	add	x0, x0, #0xc
ffffff8008754910:	d5033e9f 	dsb	st
ffffff8008754914:	52800081 	movz	w1, #0x4
ffffff8008754918:	b9000001 	str	w1, [x0]
ffffff800875491c:	f9400680 	ldr	x0, [x20, #8]
ffffff8008754920:	91004000 	add	x0, x0, #0x10
ffffff8008754924:	d5033e9f 	dsb	st
ffffff8008754928:	b9000001 	str	w1, [x0]
ffffff800875492c:	f9400680 	ldr	x0, [x20, #8]
ffffff8008754930:	91001000 	add	x0, x0, #0x4
ffffff8008754934:	b9400000 	ldr	w0, [x0]
ffffff8008754938:	d5033d9f 	dsb	ld
ffffff800875493c:	f9400a80 	ldr	x0, [x20, #16]
ffffff8008754940:	b9408000 	ldr	w0, [x0, #128]
ffffff8008754944:	11000400 	add	w0, w0, #0x1
ffffff8008754948:	7900b660 	strh	w0, [x19, #90]
ffffff800875494c:	a94153f3 	ldp	x19, x20, [sp, #16]
ffffff8008754950:	a8c27bfd 	ldp	x29, x30, [sp], #32
ffffff8008754954:	d65f03c0 	ret
ffffff8008754958:	a9bc7bfd 	stp	x29, x30, [sp, #-64]!
ffffff800875495c:	910003fd 	add	x29, sp, #0x0
ffffff8008754960:	f9000bf3 	str	x19, [sp, #16]
ffffff8008754964:	aa0003f3 	orr	x19, xzr, x0
ffffff8008754968:	aa1e03e0 	orr	x0, xzr, x30
ffffff800875496c:	f90013a4 	str	x4, [x29, #32]
ffffff8008754970:	b9002fa1 	str	w1, [x29, #44]
ffffff8008754974:	b9003ba5 	str	w5, [x29, #56]
ffffff8008754978:	f9001ba2 	str	x2, [x29, #48]
ffffff800875497c:	b9003fa3 	str	w3, [x29, #60]
ffffff8008754980:	d503201f 	hint	#0x0
ffffff8008754984:	f94013a4 	ldr	x4, [x29, #32]
ffffff8008754988:	b9403ba5 	ldr	w5, [x29, #56]
ffffff800875498c:	b9402fa1 	ldr	w1, [x29, #44]
ffffff8008754990:	f9400487 	ldr	x7, [x4, #8]
ffffff8008754994:	1210002b 	and	w11, w1, #0x10000
ffffff8008754998:	b9403fa3 	ldr	w3, [x29, #60]
ffffff800875499c:	f9401ba2 	ldr	x2, [x29, #48]
ffffff80087549a0:	794010e6 	ldrh	w6, [x7, #8]
ffffff80087549a4:	510004c6 	sub	w6, w6, #0x1
ffffff80087549a8:	6b0500df 	subs	wzr, w6, w5
ffffff80087549ac:	54000720 	b.eq	0xffffff8008754a90  // b.none
ffffff80087549b0:	320a0421 	orr	w1, w1, #0xc00000
ffffff80087549b4:	f94000ea 	ldr	x10, [x7]
ffffff80087549b8:	8b25cce0 	add	x0, x7, w5, sxtw #3
ffffff80087549bc:	f9401009 	ldr	x9, [x0, #32]
ffffff80087549c0:	6b1f007f 	subs	wzr, w3, wzr
ffffff80087549c4:	1a9f1048 	csel	w8, w2, wzr, ne  // ne = any
ffffff80087549c8:	6b1f007f 	subs	wzr, w3, wzr
ffffff80087549cc:	f9400d46 	ldr	x6, [x10, #24]
ffffff80087549d0:	f9001006 	str	x6, [x0, #32]
ffffff80087549d4:	f9000d49 	str	x9, [x10, #24]
ffffff80087549d8:	f94000e7 	ldr	x7, [x7]
ffffff80087549dc:	f9000cc7 	str	x7, [x6, #24]
ffffff80087549e0:	f90020c2 	str	x2, [x6, #64]
ffffff80087549e4:	9a9f1042 	csel	x2, x2, xzr, ne  // ne = any
ffffff80087549e8:	f90014df 	str	xzr, [x6, #40]
ffffff80087549ec:	390050c5 	strb	w5, [x6, #20]
ffffff80087549f0:	f90018c4 	str	x4, [x6, #48]
ffffff80087549f4:	b90000c1 	str	w1, [x6]
ffffff80087549f8:	3400040b 	cbz	w11, 0xffffff8008754a78
ffffff80087549fc:	12002c41 	and	w1, w2, #0xfff
ffffff8008754a00:	12144d00 	and	w0, w8, #0xfffff000
ffffff8008754a04:	32134821 	orr	w1, w1, #0xffffe000
ffffff8008754a08:	b90004c0 	str	w0, [x6, #4]
ffffff8008754a0c:	790020c1 	strh	w1, [x6, #16]
ffffff8008754a10:	b5000382 	cbnz	x2, 0xffffff8008754a80
ffffff8008754a14:	b9000cdf 	str	wzr, [x6, #12]
ffffff8008754a18:	f9401d20 	ldr	x0, [x9, #56]
ffffff8008754a1c:	910120c1 	add	x1, x6, #0x48
ffffff8008754a20:	b90008c0 	str	w0, [x6, #8]
ffffff8008754a24:	9100c0e0 	add	x0, x7, #0x30
ffffff8008754a28:	f9401ce2 	ldr	x2, [x7, #56]
ffffff8008754a2c:	f9001ce1 	str	x1, [x7, #56]
ffffff8008754a30:	f90024c0 	str	x0, [x6, #72]
ffffff8008754a34:	f90028c2 	str	x2, [x6, #80]
ffffff8008754a38:	f9000041 	str	x1, [x2]
ffffff8008754a3c:	f9401cc1 	ldr	x1, [x6, #56]
ffffff8008754a40:	d346fc20 	ubfm	x0, x1, #6, #63
ffffff8008754a44:	4a010001 	eor	w1, w0, w1
ffffff8008754a48:	d37d1421 	ubfm	x1, x1, #61, #5
ffffff8008754a4c:	8b010260 	add	x0, x19, x1
ffffff8008754a50:	f940a801 	ldr	x1, [x0, #336]
ffffff8008754a54:	f90010c1 	str	x1, [x6, #32]
ffffff8008754a58:	f900a806 	str	x6, [x0, #336]
ffffff8008754a5c:	d5033e9f 	dsb	st
ffffff8008754a60:	f9400cc0 	ldr	x0, [x6, #24]
ffffff8008754a64:	b94008c1 	ldr	w1, [x6, #8]
ffffff8008754a68:	b9000401 	str	w1, [x0, #4]
ffffff8008754a6c:	f9400bf3 	ldr	x19, [sp, #16]
ffffff8008754a70:	a8c47bfd 	ldp	x29, x30, [sp], #64
ffffff8008754a74:	d65f03c0 	ret
ffffff8008754a78:	b90004c8 	str	w8, [x6, #4]
ffffff8008754a7c:	b4fffcc2 	cbz	x2, 0xffffff8008754a14
ffffff8008754a80:	51000463 	sub	w3, w3, #0x1
ffffff8008754a84:	0b080063 	add	w3, w3, w8
ffffff8008754a88:	b9000cc3 	str	w3, [x6, #12]
ffffff8008754a8c:	17ffffe3 	b	0xffffff8008754a18
ffffff8008754a90:	b9406480 	ldr	w0, [x4, #100]
ffffff8008754a94:	363ff900 	tbz	w0, #7, 0xffffff80087549b4
ffffff8008754a98:	17ffffc6 	b	0xffffff80087549b0
ffffff8008754a9c:	a9be7bfd 	stp	x29, x30, [sp, #-32]!
ffffff8008754aa0:	910003fd 	add	x29, sp, #0x0
ffffff8008754aa4:	f9000bf3 	str	x19, [sp, #16]
ffffff8008754aa8:	aa0003f3 	orr	x19, xzr, x0
ffffff8008754aac:	aa1e03e0 	orr	x0, xzr, x30
ffffff8008754ab0:	d503201f 	hint	#0x0
ffffff8008754ab4:	f9416e60 	ldr	x0, [x19, #728]
ffffff8008754ab8:	f9400bf3 	ldr	x19, [sp, #16]
ffffff8008754abc:	a8c27bfd 	ldp	x29, x30, [sp], #32
ffffff8008754ac0:	79410000 	ldrh	w0, [x0, #128]
ffffff8008754ac4:	d65f03c0 	ret
ffffff8008754ac8:	a9be7bfd 	stp	x29, x30, [sp, #-32]!
ffffff8008754acc:	910003fd 	add	x29, sp, #0x0
ffffff8008754ad0:	f9000bf3 	str	x19, [sp, #16]
ffffff8008754ad4:	aa0003f3 	orr	x19, xzr, x0
ffffff8008754ad8:	aa1e03e0 	orr	x0, xzr, x30
ffffff8008754adc:	d503201f 	hint	#0x0
ffffff8008754ae0:	f9400661 	ldr	x1, [x19, #8]
ffffff8008754ae4:	91001021 	add	x1, x1, #0x4
ffffff8008754ae8:	b9400021 	ldr	w1, [x1]
ffffff8008754aec:	d5033d9f 	dsb	ld
ffffff8008754af0:	f9400660 	ldr	x0, [x19, #8]
ffffff8008754af4:	12170021 	and	w1, w1, #0x200
ffffff8008754af8:	b9040a61 	str	w1, [x19, #1032]
ffffff8008754afc:	91001000 	add	x0, x0, #0x4
ffffff8008754b00:	d5033e9f 	dsb	st
ffffff8008754b04:	b9000001 	str	w1, [x0]
ffffff8008754b08:	b903827f 	str	wzr, [x19, #896]
ffffff8008754b0c:	f9400bf3 	ldr	x19, [sp, #16]
ffffff8008754b10:	a8c27bfd 	ldp	x29, x30, [sp], #32
ffffff8008754b14:	d65f03c0 	ret
ffffff8008754b18:	a9be7bfd 	stp	x29, x30, [sp, #-32]!
ffffff8008754b1c:	910003fd 	add	x29, sp, #0x0
ffffff8008754b20:	a90153f3 	stp	x19, x20, [sp, #16]
ffffff8008754b24:	aa0003f3 	orr	x19, xzr, x0
ffffff8008754b28:	aa1e03e0 	orr	x0, xzr, x30
ffffff8008754b2c:	aa0103f4 	orr	x20, xzr, x1
ffffff8008754b30:	d503201f 	hint	#0x0
ffffff8008754b34:	d2802c02 	movz	x2, #0x160
ffffff8008754b38:	52800001 	movz	w1, #0x0
ffffff8008754b3c:	aa1303e0 	orr	x0, xzr, x19
ffffff8008754b40:	97f8c530 	bl	0xffffff8008586000
ffffff8008754b44:	900030a0 	adrp	x0, 0xffffff8008d68000
ffffff8008754b48:	91278000 	add	x0, x0, #0x9e0
ffffff8008754b4c:	f9000260 	str	x0, [x19]
ffffff8008754b50:	90003dc0 	adrp	x0, 0xffffff8008f0c000
ffffff8008754b54:	9113c000 	add	x0, x0, #0x4f0
ffffff8008754b58:	f9000660 	str	x0, [x19, #8]
ffffff8008754b5c:	d2809500 	movz	x0, #0x4a8
ffffff8008754b60:	f9000a60 	str	x0, [x19, #16]
ffffff8008754b64:	b0000020 	adrp	x0, 0xffffff8008759000
ffffff8008754b68:	910ff000 	add	x0, x0, #0x3fc
ffffff8008754b6c:	f9000e60 	str	x0, [x19, #24]
ffffff8008754b70:	52800220 	movz	w0, #0x11
ffffff8008754b74:	b9002260 	str	w0, [x19, #32]
ffffff8008754b78:	90000020 	adrp	x0, 0xffffff8008758000
ffffff8008754b7c:	910c1000 	add	x0, x0, #0x304
ffffff8008754b80:	f9001660 	str	x0, [x19, #40]
ffffff8008754b84:	b0000020 	adrp	x0, 0xffffff8008759000
ffffff8008754b88:	910e7000 	add	x0, x0, #0x39c
ffffff8008754b8c:	f9001a60 	str	x0, [x19, #48]
ffffff8008754b90:	f0000000 	adrp	x0, 0xffffff8008757000
ffffff8008754b94:	9138a000 	add	x0, x0, #0xe28
ffffff8008754b98:	f9002660 	str	x0, [x19, #72]
ffffff8008754b9c:	b0000000 	adrp	x0, 0xffffff8008755000
ffffff8008754ba0:	91065000 	add	x0, x0, #0x194
ffffff8008754ba4:	f9002a60 	str	x0, [x19, #80]
ffffff8008754ba8:	90000000 	adrp	x0, 0xffffff8008754000
ffffff8008754bac:	912a7000 	add	x0, x0, #0xa9c
ffffff8008754bb0:	f9002e60 	str	x0, [x19, #88]
ffffff8008754bb4:	b0000020 	adrp	x0, 0xffffff8008759000
ffffff8008754bb8:	91180000 	add	x0, x0, #0x600
ffffff8008754bbc:	f9003260 	str	x0, [x19, #96]
ffffff8008754bc0:	d0000000 	adrp	x0, 0xffffff8008756000
ffffff8008754bc4:	91243000 	add	x0, x0, #0x90c
ffffff8008754bc8:	f9003660 	str	x0, [x19, #104]
ffffff8008754bcc:	d0000000 	adrp	x0, 0xffffff8008756000
ffffff8008754bd0:	911e7000 	add	x0, x0, #0x79c
ffffff8008754bd4:	f9004260 	str	x0, [x19, #128]
ffffff8008754bd8:	90000020 	adrp	x0, 0xffffff8008758000
ffffff8008754bdc:	9134b000 	add	x0, x0, #0xd2c
ffffff8008754be0:	f9004a60 	str	x0, [x19, #144]
ffffff8008754be4:	b0000000 	adrp	x0, 0xffffff8008755000
ffffff8008754be8:	91085000 	add	x0, x0, #0x214
ffffff8008754bec:	f9004e60 	str	x0, [x19, #152]
ffffff8008754bf0:	d0000000 	adrp	x0, 0xffffff8008756000
ffffff8008754bf4:	911c3000 	add	x0, x0, #0x70c
ffffff8008754bf8:	f9005260 	str	x0, [x19, #160]
ffffff8008754bfc:	b0000020 	adrp	x0, 0xffffff8008759000
ffffff8008754c00:	910bb000 	add	x0, x0, #0x2ec
ffffff8008754c04:	f9005660 	str	x0, [x19, #168]
ffffff8008754c08:	90000000 	adrp	x0, 0xffffff8008754000
ffffff8008754c0c:	9118b000 	add	x0, x0, #0x62c
ffffff8008754c10:	f9005a60 	str	x0, [x19, #176]
ffffff8008754c14:	b4000134 	cbz	x20, 0xffffff8008754c38
ffffff8008754c18:	f9400280 	ldr	x0, [x20]
ffffff8008754c1c:	f9000660 	str	x0, [x19, #8]
ffffff8008754c20:	f9400680 	ldr	x0, [x20, #8]
ffffff8008754c24:	9112a000 	add	x0, x0, #0x4a8
ffffff8008754c28:	f9000a60 	str	x0, [x19, #16]
ffffff8008754c2c:	f9400a80 	ldr	x0, [x20, #16]
ffffff8008754c30:	b4000040 	cbz	x0, 0xffffff8008754c38
ffffff8008754c34:	f9001660 	str	x0, [x19, #40]
ffffff8008754c38:	a94153f3 	ldp	x19, x20, [sp, #16]
ffffff8008754c3c:	a8c27bfd 	ldp	x29, x30, [sp], #32
ffffff8008754c40:	d65f03c0 	ret
ffffff8008754c44:	a9bd7bfd 	stp	x29, x30, [sp, #-48]!
ffffff8008754c48:	910003fd 	add	x29, sp, #0x0
ffffff8008754c4c:	f9000bf3 	str	x19, [sp, #16]
ffffff8008754c50:	aa0003f3 	orr	x19, xzr, x0
ffffff8008754c54:	aa1e03e0 	orr	x0, xzr, x30
ffffff8008754c58:	f90017a1 	str	x1, [x29, #40]
ffffff8008754c5c:	d503201f 	hint	#0x0
ffffff8008754c60:	f94017a1 	ldr	x1, [x29, #40]
ffffff8008754c64:	f900143f 	str	xzr, [x1, #40]
ffffff8008754c68:	f900103f 	str	xzr, [x1, #32]
ffffff8008754c6c:	b9000c3f 	str	wzr, [x1, #12]
ffffff8008754c70:	d5033e9f 	dsb	st
ffffff8008754c74:	39414420 	ldrb	w0, [x1, #81]
ffffff8008754c78:	7100081f 	subs	wzr, w0, #0x2
ffffff8008754c7c:	54000da0 	b.eq	0xffffff8008754e30  // b.none
ffffff8008754c80:	71000c1f 	subs	wzr, w0, #0x3
ffffff8008754c84:	54000241 	b.ne	0xffffff8008754ccc  // b.any
ffffff8008754c88:	f9401660 	ldr	x0, [x19, #40]
ffffff8008754c8c:	b40013c0 	cbz	x0, 0xffffff8008754f04
ffffff8008754c90:	f9001001 	str	x1, [x0, #32]
ffffff8008754c94:	f9401660 	ldr	x0, [x19, #40]
ffffff8008754c98:	f9400822 	ldr	x2, [x1, #16]
ffffff8008754c9c:	b9000c02 	str	w2, [x0, #12]
ffffff8008754ca0:	f9401660 	ldr	x0, [x19, #40]
ffffff8008754ca4:	f9001420 	str	x0, [x1, #40]
ffffff8008754ca8:	f9401660 	ldr	x0, [x19, #40]
ffffff8008754cac:	b4000da0 	cbz	x0, 0xffffff8008754e60
ffffff8008754cb0:	f9001661 	str	x1, [x19, #40]
ffffff8008754cb4:	52800042 	movz	w2, #0x2
ffffff8008754cb8:	52800000 	movz	w0, #0x0
ffffff8008754cbc:	39014022 	strb	w2, [x1, #80]
ffffff8008754cc0:	f9400bf3 	ldr	x19, [sp, #16]
ffffff8008754cc4:	a8c37bfd 	ldp	x29, x30, [sp], #48
ffffff8008754cc8:	d65f03c0 	ret
ffffff8008754ccc:	7940a828 	ldrh	w8, [x1, #84]
ffffff8008754cd0:	52800404 	movz	w4, #0x20
ffffff8008754cd4:	7940ac25 	ldrh	w5, [x1, #86]
ffffff8008754cd8:	7100811f 	subs	wzr, w8, #0x20
ffffff8008754cdc:	1a84d104 	csel	w4, w8, w4, le
ffffff8008754ce0:	340012a4 	cbz	w4, 0xffffff8008754f34
ffffff8008754ce4:	910e2267 	add	x7, x19, #0x388
ffffff8008754ce8:	52800006 	movz	w6, #0x0
ffffff8008754cec:	12800360 	movn	w0, #0x1b
ffffff8008754cf0:	37f809c0 	tbnz	w0, #31, 0xffffff8008754e28
ffffff8008754cf4:	b94000e2 	ldr	w2, [x7]
ffffff8008754cf8:	8b20ca63 	add	x3, x19, w0, sxtw #2
ffffff8008754cfc:	b9438863 	ldr	w3, [x3, #904]
ffffff8008754d00:	6b02007f 	subs	wzr, w3, w2
ffffff8008754d04:	5400018d 	b.le	0xffffff8008754d34
ffffff8008754d08:	2a0603e3 	orr	w3, wzr, w6
ffffff8008754d0c:	14000002 	b	0xffffff8008754d14
ffffff8008754d10:	b9438842 	ldr	w2, [x2, #904]
ffffff8008754d14:	0b0200a2 	add	w2, w5, w2
ffffff8008754d18:	0b040063 	add	w3, w3, w4
ffffff8008754d1c:	710e105f 	subs	wzr, w2, #0x384
ffffff8008754d20:	8b23ca62 	add	x2, x19, w3, sxtw #2
ffffff8008754d24:	5400008c 	b.gt	0xffffff8008754d34
ffffff8008754d28:	71007c7f 	subs	wzr, w3, #0x1f
ffffff8008754d2c:	54ffff2d 	b.le	0xffffff8008754d10
ffffff8008754d30:	2a0603e0 	orr	w0, wzr, w6
ffffff8008754d34:	110004c6 	add	w6, w6, #0x1
ffffff8008754d38:	910010e7 	add	x7, x7, #0x4
ffffff8008754d3c:	6b0400df 	subs	wzr, w6, w4
ffffff8008754d40:	54fffd81 	b.ne	0xffffff8008754cf0  // b.any
ffffff8008754d44:	37fffbe0 	tbnz	w0, #31, 0xffffff8008754cc0
ffffff8008754d48:	12001c07 	and	w7, w0, #0xff
ffffff8008754d4c:	39014820 	strb	w0, [x1, #82]
ffffff8008754d50:	71007cff 	subs	wzr, w7, #0x1f
ffffff8008754d54:	5400054c 	b.gt	0xffffff8008754dfc
ffffff8008754d58:	2a0703e6 	orr	w6, wzr, w7
ffffff8008754d5c:	f9400a60 	ldr	x0, [x19, #16]
ffffff8008754d60:	910018c2 	add	x2, x6, #0x6
ffffff8008754d64:	8b060800 	add	x0, x0, x6, lsl #2
ffffff8008754d68:	8b020e62 	add	x2, x19, x2, lsl #3
ffffff8008754d6c:	91002044 	add	x4, x2, #0x8
ffffff8008754d70:	f9400442 	ldr	x2, [x2, #8]
ffffff8008754d74:	eb02003f 	subs	xzr, x1, x2
ffffff8008754d78:	540004e0 	b.eq	0xffffff8008754e14  // b.none
ffffff8008754d7c:	b40004c2 	cbz	x2, 0xffffff8008754e14
ffffff8008754d80:	7940a825 	ldrh	w5, [x1, #84]
ffffff8008754d84:	7940a843 	ldrh	w3, [x2, #84]
ffffff8008754d88:	6b05007f 	subs	wzr, w3, w5
ffffff8008754d8c:	54000143 	b.cc	0xffffff8008754db4  // b.lo, b.ul, b.last
ffffff8008754d90:	91008044 	add	x4, x2, #0x20
ffffff8008754d94:	91003040 	add	x0, x2, #0xc
ffffff8008754d98:	f9401042 	ldr	x2, [x2, #32]
ffffff8008754d9c:	eb02003f 	subs	xzr, x1, x2
ffffff8008754da0:	540003a0 	b.eq	0xffffff8008754e14  // b.none
ffffff8008754da4:	b4000382 	cbz	x2, 0xffffff8008754e14
ffffff8008754da8:	7940a843 	ldrh	w3, [x2, #84]
ffffff8008754dac:	6b05007f 	subs	wzr, w3, w5
ffffff8008754db0:	54ffff02 	b.cs	0xffffff8008754d90  // b.hs, b.nlast
ffffff8008754db4:	f9001022 	str	x2, [x1, #32]
ffffff8008754db8:	b9400002 	ldr	w2, [x0]
ffffff8008754dbc:	b9000c22 	str	w2, [x1, #12]
ffffff8008754dc0:	d5033e9f 	dsb	st
ffffff8008754dc4:	f9000081 	str	x1, [x4]
ffffff8008754dc8:	f9400822 	ldr	x2, [x1, #16]
ffffff8008754dcc:	b9000002 	str	w2, [x0]
ffffff8008754dd0:	d5033e9f 	dsb	st
ffffff8008754dd4:	8b060a66 	add	x6, x19, x6, lsl #2
ffffff8008754dd8:	7940ac20 	ldrh	w0, [x1, #86]
ffffff8008754ddc:	b94388c2 	ldr	w2, [x6, #904]
ffffff8008754de0:	0b000040 	add	w0, w2, w0
ffffff8008754de4:	b90388c0 	str	w0, [x6, #904]
ffffff8008754de8:	7940a828 	ldrh	w8, [x1, #84]
ffffff8008754dec:	0b0800e7 	add	w7, w7, w8
ffffff8008754df0:	71007cff 	subs	wzr, w7, #0x1f
ffffff8008754df4:	54fffb29 	b.ls	0xffffff8008754d58  // b.plast
ffffff8008754df8:	7940ac25 	ldrh	w5, [x1, #86]
ffffff8008754dfc:	d10b2273 	sub	x19, x19, #0x2c8
ffffff8008754e00:	1ac808a5 	udiv	w5, w5, w8
ffffff8008754e04:	b9407a60 	ldr	w0, [x19, #120]
ffffff8008754e08:	0b050005 	add	w5, w0, w5
ffffff8008754e0c:	b9007a65 	str	w5, [x19, #120]
ffffff8008754e10:	17ffffa9 	b	0xffffff8008754cb4
ffffff8008754e14:	eb02003f 	subs	xzr, x1, x2
ffffff8008754e18:	54fffde0 	b.eq	0xffffff8008754dd4  // b.none
ffffff8008754e1c:	f9001022 	str	x2, [x1, #32]
ffffff8008754e20:	b5fffcc2 	cbnz	x2, 0xffffff8008754db8
ffffff8008754e24:	17ffffe7 	b	0xffffff8008754dc0
ffffff8008754e28:	b94000e2 	ldr	w2, [x7]
ffffff8008754e2c:	17ffffb7 	b	0xffffff8008754d08
ffffff8008754e30:	f9401a60 	ldr	x0, [x19, #48]
ffffff8008754e34:	b4000580 	cbz	x0, 0xffffff8008754ee4
ffffff8008754e38:	f9001001 	str	x1, [x0, #32]
ffffff8008754e3c:	f9401a60 	ldr	x0, [x19, #48]
ffffff8008754e40:	f9400822 	ldr	x2, [x1, #16]
ffffff8008754e44:	b9000c02 	str	w2, [x0, #12]
ffffff8008754e48:	f9401a60 	ldr	x0, [x19, #48]
ffffff8008754e4c:	f9001420 	str	x0, [x1, #40]
ffffff8008754e50:	f9401a60 	ldr	x0, [x19, #48]
ffffff8008754e54:	b4000260 	cbz	x0, 0xffffff8008754ea0
ffffff8008754e58:	f9001a61 	str	x1, [x19, #48]
ffffff8008754e5c:	17ffff96 	b	0xffffff8008754cb4
ffffff8008754e60:	f9401260 	ldr	x0, [x19, #32]
ffffff8008754e64:	b5fff260 	cbnz	x0, 0xffffff8008754cb0
ffffff8008754e68:	d5033e9f 	dsb	st
ffffff8008754e6c:	b9440a62 	ldr	w2, [x19, #1032]
ffffff8008754e70:	f9400660 	ldr	x0, [x19, #8]
ffffff8008754e74:	321b0042 	orr	w2, w2, #0x20
ffffff8008754e78:	b9040a62 	str	w2, [x19, #1032]
ffffff8008754e7c:	9100b000 	add	x0, x0, #0x2c
ffffff8008754e80:	d5033e9f 	dsb	st
ffffff8008754e84:	b900001f 	str	wzr, [x0]
ffffff8008754e88:	f9400660 	ldr	x0, [x19, #8]
ffffff8008754e8c:	b9440a62 	ldr	w2, [x19, #1032]
ffffff8008754e90:	91001000 	add	x0, x0, #0x4
ffffff8008754e94:	d5033e9f 	dsb	st
ffffff8008754e98:	b9000002 	str	w2, [x0]
ffffff8008754e9c:	17ffff85 	b	0xffffff8008754cb0
ffffff8008754ea0:	f9401260 	ldr	x0, [x19, #32]
ffffff8008754ea4:	b5fffda0 	cbnz	x0, 0xffffff8008754e58
ffffff8008754ea8:	d5033e9f 	dsb	st
ffffff8008754eac:	b9440a62 	ldr	w2, [x19, #1032]
ffffff8008754eb0:	f9400660 	ldr	x0, [x19, #8]
ffffff8008754eb4:	321c0042 	orr	w2, w2, #0x10
ffffff8008754eb8:	b9040a62 	str	w2, [x19, #1032]
ffffff8008754ebc:	91009000 	add	x0, x0, #0x24
ffffff8008754ec0:	d5033e9f 	dsb	st
ffffff8008754ec4:	b900001f 	str	wzr, [x0]
ffffff8008754ec8:	f9400660 	ldr	x0, [x19, #8]
ffffff8008754ecc:	b9440a62 	ldr	w2, [x19, #1032]
ffffff8008754ed0:	91001000 	add	x0, x0, #0x4
ffffff8008754ed4:	d5033e9f 	dsb	st
ffffff8008754ed8:	b9000002 	str	w2, [x0]
ffffff8008754edc:	f9001a61 	str	x1, [x19, #48]
ffffff8008754ee0:	17ffff75 	b	0xffffff8008754cb4
ffffff8008754ee4:	b9440a60 	ldr	w0, [x19, #1032]
ffffff8008754ee8:	37200220 	tbnz	w0, #4, 0xffffff8008754f2c
ffffff8008754eec:	f9400660 	ldr	x0, [x19, #8]
ffffff8008754ef0:	f9400822 	ldr	x2, [x1, #16]
ffffff8008754ef4:	91008000 	add	x0, x0, #0x20
ffffff8008754ef8:	d5033e9f 	dsb	st
ffffff8008754efc:	b9000002 	str	w2, [x0]
ffffff8008754f00:	17ffffd2 	b	0xffffff8008754e48
ffffff8008754f04:	b9440a60 	ldr	w0, [x19, #1032]
ffffff8008754f08:	372800e0 	tbnz	w0, #5, 0xffffff8008754f24
ffffff8008754f0c:	f9400660 	ldr	x0, [x19, #8]
ffffff8008754f10:	f9400822 	ldr	x2, [x1, #16]
ffffff8008754f14:	9100a000 	add	x0, x0, #0x28
ffffff8008754f18:	d5033e9f 	dsb	st
ffffff8008754f1c:	b9000002 	str	w2, [x0]
ffffff8008754f20:	17ffff60 	b	0xffffff8008754ca0
ffffff8008754f24:	d4210000 	brk	#0x800
ffffff8008754f28:	17fffff9 	b	0xffffff8008754f0c
ffffff8008754f2c:	d4210000 	brk	#0x800
ffffff8008754f30:	17ffffef 	b	0xffffff8008754eec
ffffff8008754f34:	12800360 	movn	w0, #0x1b
ffffff8008754f38:	17ffff62 	b	0xffffff8008754cc0
ffffff8008754f3c:	a9bd7bfd 	stp	x29, x30, [sp, #-48]!
ffffff8008754f40:	910003fd 	add	x29, sp, #0x0
ffffff8008754f44:	f9000bf3 	str	x19, [sp, #16]
ffffff8008754f48:	aa0003f3 	orr	x19, xzr, x0
ffffff8008754f4c:	aa1e03e0 	orr	x0, xzr, x30
ffffff8008754f50:	f90017a1 	str	x1, [x29, #40]
ffffff8008754f54:	d503201f 	hint	#0x0
ffffff8008754f58:	f94017a1 	ldr	x1, [x29, #40]
ffffff8008754f5c:	f9401c22 	ldr	x2, [x1, #56]
ffffff8008754f60:	ca421844 	eor	x4, x2, x2, lsr #6
ffffff8008754f64:	92401484 	and	x4, x4, #0x3f
ffffff8008754f68:	9100a883 	add	x3, x4, #0x2a
ffffff8008754f6c:	f8637a64 	ldr	x4, [x19, x3, lsl #3]
ffffff8008754f70:	b4000124 	cbz	x4, 0xffffff8008754f94
ffffff8008754f74:	eb04003f 	subs	xzr, x1, x4
ffffff8008754f78:	54000081 	b.ne	0xffffff8008754f88  // b.any
ffffff8008754f7c:	14000014 	b	0xffffff8008754fcc
ffffff8008754f80:	54000140 	b.eq	0xffffff8008754fa8  // b.none
ffffff8008754f84:	aa0303e4 	orr	x4, xzr, x3
ffffff8008754f88:	f9401083 	ldr	x3, [x4, #32]
ffffff8008754f8c:	eb03003f 	subs	xzr, x1, x3
ffffff8008754f90:	b5ffff83 	cbnz	x3, 0xffffff8008754f80
ffffff8008754f94:	f940a260 	ldr	x0, [x19, #320]
ffffff8008754f98:	97ec6886 	bl	0xffffff800826f1b0
ffffff8008754f9c:	f9400bf3 	ldr	x19, [sp, #16]
ffffff8008754fa0:	a8c37bfd 	ldp	x29, x30, [sp], #48
ffffff8008754fa4:	d65f03c0 	ret
ffffff8008754fa8:	91008084 	add	x4, x4, #0x20
ffffff8008754fac:	f9401020 	ldr	x0, [x1, #32]
ffffff8008754fb0:	f9000080 	str	x0, [x4]
ffffff8008754fb4:	f940a260 	ldr	x0, [x19, #320]
ffffff8008754fb8:	f9401c22 	ldr	x2, [x1, #56]
ffffff8008754fbc:	97ec687d 	bl	0xffffff800826f1b0
ffffff8008754fc0:	f9400bf3 	ldr	x19, [sp, #16]
ffffff8008754fc4:	a8c37bfd 	ldp	x29, x30, [sp], #48
ffffff8008754fc8:	d65f03c0 	ret
ffffff8008754fcc:	8b030e64 	add	x4, x19, x3, lsl #3
ffffff8008754fd0:	17fffff7 	b	0xffffff8008754fac
ffffff8008754fd4:	a9bd7bfd 	stp	x29, x30, [sp, #-48]!
ffffff8008754fd8:	910003fd 	add	x29, sp, #0x0
ffffff8008754fdc:	a90153f3 	stp	x19, x20, [sp, #16]
ffffff8008754fe0:	a9025bf5 	stp	x21, x22, [sp, #32]
ffffff8008754fe4:	aa0103f4 	orr	x20, xzr, x1
ffffff8008754fe8:	aa0003f6 	orr	x22, xzr, x0
ffffff8008754fec:	aa1e03e0 	orr	x0, xzr, x30
ffffff8008754ff0:	52800013 	movz	w19, #0x0
ffffff8008754ff4:	d503201f 	hint	#0x0
ffffff8008754ff8:	79401280 	ldrh	w0, [x20, #8]
ffffff8008754ffc:	51000415 	sub	w21, w0, #0x1
ffffff8008755000:	34000140 	cbz	w0, 0xffffff8008755028
ffffff8008755004:	8b33ce82 	add	x2, x20, w19, sxtw #3
ffffff8008755008:	f9401042 	ldr	x2, [x2, #32]
ffffff800875500c:	11000673 	add	w19, w19, #0x1
ffffff8008755010:	aa1603e0 	orr	x0, xzr, x22
ffffff8008755014:	aa0203e1 	orr	x1, xzr, x2
ffffff8008755018:	b4000042 	cbz	x2, 0xffffff8008755020
ffffff800875501c:	97ffffc8 	bl	0xffffff8008754f3c
ffffff8008755020:	6b1302bf 	subs	wzr, w21, w19
ffffff8008755024:	54ffff0a 	b.ge	0xffffff8008755004  // b.tcont
ffffff8008755028:	f9400a84 	ldr	x4, [x20, #16]
ffffff800875502c:	d2802002 	movz	x2, #0x100
ffffff8008755030:	f9400e83 	ldr	x3, [x20, #24]
ffffff8008755034:	d2804001 	movz	x1, #0x200
ffffff8008755038:	f2fbd5a2 	movk	x2, #0xdead, lsl #48
ffffff800875503c:	f2fbd5a1 	movk	x1, #0xdead, lsl #48
ffffff8008755040:	f9000483 	str	x3, [x4, #8]
ffffff8008755044:	aa1403e0 	orr	x0, xzr, x20
ffffff8008755048:	f9000064 	str	x4, [x3]
ffffff800875504c:	f9000a82 	str	x2, [x20, #16]
ffffff8008755050:	f9000e81 	str	x1, [x20, #24]
ffffff8008755054:	97ecb6f6 	bl	0xffffff8008282c2c
ffffff8008755058:	a94153f3 	ldp	x19, x20, [sp, #16]
ffffff800875505c:	a9425bf5 	ldp	x21, x22, [sp, #32]
ffffff8008755060:	a8c37bfd 	ldp	x29, x30, [sp], #48
ffffff8008755064:	d65f03c0 	ret
ffffff8008755068:	a9bb7bfd 	stp	x29, x30, [sp, #-80]!
ffffff800875506c:	910003fd 	add	x29, sp, #0x0
ffffff8008755070:	a90153f3 	stp	x19, x20, [sp, #16]
ffffff8008755074:	a9025bf5 	stp	x21, x22, [sp, #32]
ffffff8008755078:	a90363f7 	stp	x23, x24, [sp, #48]
ffffff800875507c:	f90023f9 	str	x25, [sp, #64]
ffffff8008755080:	aa0103f4 	orr	x20, xzr, x1
ffffff8008755084:	aa0003f5 	orr	x21, xzr, x0
ffffff8008755088:	aa1e03e0 	orr	x0, xzr, x30
ffffff800875508c:	2a0203f7 	orr	w23, wzr, w2
ffffff8008755090:	d10b22b3 	sub	x19, x21, #0x2c8
ffffff8008755094:	d503201f 	hint	#0x0
ffffff8008755098:	f9402a98 	ldr	x24, [x20, #80]
ffffff800875509c:	f9400681 	ldr	x1, [x20, #8]
ffffff80087550a0:	aa1503e0 	orr	x0, xzr, x21
ffffff80087550a4:	91006319 	add	x25, x24, #0x18
ffffff80087550a8:	97ffffcb 	bl	0xffffff8008754fd4
ffffff80087550ac:	f900069f 	str	xzr, [x20, #8]
ffffff80087550b0:	3101ceff 	adds	wzr, w23, #0x73
ffffff80087550b4:	1a9f12f7 	csel	w23, w23, wzr, ne  // ne = any
ffffff80087550b8:	1400002a 	b	0xffffff8008755160
ffffff80087550bc:	7100047f 	subs	wzr, w3, #0x1
ffffff80087550c0:	54000081 	b.ne	0xffffff80087550d0  // b.any
ffffff80087550c4:	b9407e60 	ldr	w0, [x19, #124]
ffffff80087550c8:	51000400 	sub	w0, w0, #0x1
ffffff80087550cc:	b9007e60 	str	w0, [x19, #124]
ffffff80087550d0:	aa1403e1 	orr	x1, xzr, x20
ffffff80087550d4:	aa1303e0 	orr	x0, xzr, x19
ffffff80087550d8:	97ff5ce2 	bl	0xffffff800872c460
ffffff80087550dc:	aa1503e0 	orr	x0, xzr, x21
ffffff80087550e0:	94155a91 	bl	0xffffff8008cabb24
ffffff80087550e4:	2a1703e2 	orr	w2, wzr, w23
ffffff80087550e8:	aa1403e1 	orr	x1, xzr, x20
ffffff80087550ec:	aa1303e0 	orr	x0, xzr, x19
ffffff80087550f0:	97ff6071 	bl	0xffffff800872d2b4
ffffff80087550f4:	aa1503e0 	orr	x0, xzr, x21
ffffff80087550f8:	94155a4e 	bl	0xffffff8008caba30
ffffff80087550fc:	b9408260 	ldr	w0, [x19, #128]
ffffff8008755100:	35000140 	cbnz	w0, 0xffffff8008755128
ffffff8008755104:	b9407e60 	ldr	w0, [x19, #124]
ffffff8008755108:	35000100 	cbnz	w0, 0xffffff8008755128
ffffff800875510c:	b9440aa0 	ldr	w0, [x21, #1032]
ffffff8008755110:	f94006a1 	ldr	x1, [x21, #8]
ffffff8008755114:	121c7400 	and	w0, w0, #0xfffffff3
ffffff8008755118:	b9040aa0 	str	w0, [x21, #1032]
ffffff800875511c:	91001021 	add	x1, x1, #0x4
ffffff8008755120:	d5033e9f 	dsb	st
ffffff8008755124:	b9000020 	str	w0, [x1]
ffffff8008755128:	f9400f00 	ldr	x0, [x24, #24]
ffffff800875512c:	eb00033f 	subs	xzr, x25, x0
ffffff8008755130:	54000260 	b.eq	0xffffff800875517c  // b.none
ffffff8008755134:	f9400f16 	ldr	x22, [x24, #24]
ffffff8008755138:	d10082d4 	sub	x20, x22, #0x20
ffffff800875513c:	f85e82c1 	ldur	x1, [x22, #-24]
ffffff8008755140:	79401422 	ldrh	w2, [x1, #10]
ffffff8008755144:	79401020 	ldrh	w0, [x1, #8]
ffffff8008755148:	6b00005f 	subs	wzr, w2, w0
ffffff800875514c:	54000189 	b.ls	0xffffff800875517c  // b.plast
ffffff8008755150:	aa1503e0 	orr	x0, xzr, x21
ffffff8008755154:	52800017 	movz	w23, #0x0
ffffff8008755158:	97ffff9f 	bl	0xffffff8008754fd4
ffffff800875515c:	f81e82df 	stur	xzr, [x22, #-24]
ffffff8008755160:	b9405a83 	ldr	w3, [x20, #88]
ffffff8008755164:	531e7c63 	ubfm	w3, w3, #30, #31
ffffff8008755168:	35fffaa3 	cbnz	w3, 0xffffff80087550bc
ffffff800875516c:	b9408260 	ldr	w0, [x19, #128]
ffffff8008755170:	51000400 	sub	w0, w0, #0x1
ffffff8008755174:	b9008260 	str	w0, [x19, #128]
ffffff8008755178:	17ffffd6 	b	0xffffff80087550d0
ffffff800875517c:	a94153f3 	ldp	x19, x20, [sp, #16]
ffffff8008755180:	a9425bf5 	ldp	x21, x22, [sp, #32]
ffffff8008755184:	a94363f7 	ldp	x23, x24, [sp, #48]
ffffff8008755188:	f94023f9 	ldr	x25, [sp, #64]
ffffff800875518c:	a8c57bfd 	ldp	x29, x30, [sp], #80
ffffff8008755190:	d65f03c0 	ret
ffffff8008755194:	a9be7bfd 	stp	x29, x30, [sp, #-32]!
ffffff8008755198:	910003fd 	add	x29, sp, #0x0
ffffff800875519c:	f9000bf3 	str	x19, [sp, #16]
ffffff80087551a0:	aa0003f3 	orr	x19, xzr, x0
ffffff80087551a4:	aa1e03e0 	orr	x0, xzr, x30
ffffff80087551a8:	910b2273 	add	x19, x19, #0x2c8
ffffff80087551ac:	d503201f 	hint	#0x0
ffffff80087551b0:	f9400660 	ldr	x0, [x19, #8]
ffffff80087551b4:	91005000 	add	x0, x0, #0x14
ffffff80087551b8:	d5033e9f 	dsb	st
ffffff80087551bc:	12800001 	movn	w1, #0x0
ffffff80087551c0:	b9000001 	str	w1, [x0]
ffffff80087551c4:	f9400660 	ldr	x0, [x19, #8]
ffffff80087551c8:	91002000 	add	x0, x0, #0x8
ffffff80087551cc:	d5033e9f 	dsb	st
ffffff80087551d0:	52800021 	movz	w1, #0x1
ffffff80087551d4:	b9000001 	str	w1, [x0]
ffffff80087551d8:	f9400660 	ldr	x0, [x19, #8]
ffffff80087551dc:	91002000 	add	x0, x0, #0x8
ffffff80087551e0:	b9400000 	ldr	w0, [x0]
ffffff80087551e4:	d5033d9f 	dsb	ld
ffffff80087551e8:	d294f8c0 	movz	x0, #0xa7c6
ffffff80087551ec:	97f8c1fb 	bl	0xffffff80085859d8
ffffff80087551f0:	f9400660 	ldr	x0, [x19, #8]
ffffff80087551f4:	b9441a61 	ldr	w1, [x19, #1048]
ffffff80087551f8:	9100d000 	add	x0, x0, #0x34
ffffff80087551fc:	d5033e9f 	dsb	st
ffffff8008755200:	b9000001 	str	w1, [x0]
ffffff8008755204:	b903827f 	str	wzr, [x19, #896]
ffffff8008755208:	f9400bf3 	ldr	x19, [sp, #16]
ffffff800875520c:	a8c27bfd 	ldp	x29, x30, [sp], #32
ffffff8008755210:	d65f03c0 	ret
ffffff8008755214:	a9ba7bfd 	stp	x29, x30, [sp, #-96]!
ffffff8008755218:	910003fd 	add	x29, sp, #0x0
ffffff800875521c:	a90153f3 	stp	x19, x20, [sp, #16]
ffffff8008755220:	a9025bf5 	stp	x21, x22, [sp, #32]
ffffff8008755224:	a90363f7 	stp	x23, x24, [sp, #48]
ffffff8008755228:	f90023f9 	str	x25, [sp, #64]
ffffff800875522c:	aa0003f4 	orr	x20, xzr, x0
ffffff8008755230:	aa1e03e0 	orr	x0, xzr, x30
ffffff8008755234:	53003c33 	ubfm	w19, w1, #0, #15
ffffff8008755238:	f9002fa4 	str	x4, [x29, #88]
ffffff800875523c:	53003c56 	ubfm	w22, w2, #0, #15
ffffff8008755240:	53003c75 	ubfm	w21, w3, #0, #15
ffffff8008755244:	d503201f 	hint	#0x0
ffffff8008755248:	b9464e81 	ldr	w1, [x20, #1612]
ffffff800875524c:	910b2285 	add	x5, x20, #0x2c8
ffffff8008755250:	f9409680 	ldr	x0, [x20, #296]
ffffff8008755254:	f9402fa4 	ldr	x4, [x29, #88]
ffffff8008755258:	360017c0 	tbz	w0, #0, 0xffffff8008755550
ffffff800875525c:	52846060 	movz	w0, #0x2303
ffffff8008755260:	6b00027f 	subs	wzr, w19, w0
ffffff8008755264:	54001460 	b.eq	0xffffff80087554f0  // b.none
ffffff8008755268:	54000209 	b.ls	0xffffff80087552a8  // b.plast
ffffff800875526c:	529400c0 	movz	w0, #0xa006
ffffff8008755270:	6b00027f 	subs	wzr, w19, w0
ffffff8008755274:	54000ba0 	b.eq	0xffffff80087553e8  // b.none
ffffff8008755278:	52946000 	movz	w0, #0xa300
ffffff800875527c:	6b00027f 	subs	wzr, w19, w0
ffffff8008755280:	540003a0 	b.eq	0xffffff80087552f4  // b.none
ffffff8008755284:	71402a7f 	subs	wzr, w19, #0xa, lsl #12
ffffff8008755288:	54000960 	b.eq	0xffffff80087553b4  // b.none
ffffff800875528c:	128003e0 	movn	w0, #0x1f
ffffff8008755290:	a94153f3 	ldp	x19, x20, [sp, #16]
ffffff8008755294:	a9425bf5 	ldp	x21, x22, [sp, #32]
ffffff8008755298:	a94363f7 	ldp	x23, x24, [sp, #48]
ffffff800875529c:	f94023f9 	ldr	x25, [sp, #64]
ffffff80087552a0:	a8c67bfd 	ldp	x29, x30, [sp], #96
ffffff80087552a4:	d65f03c0 	ret
ffffff80087552a8:	52840060 	movz	w0, #0x2003
ffffff80087552ac:	6b00027f 	subs	wzr, w19, w0
ffffff80087552b0:	540010e0 	b.eq	0xffffff80087554cc  // b.none
ffffff80087552b4:	52846020 	movz	w0, #0x2301
ffffff80087552b8:	6b00027f 	subs	wzr, w19, w0
ffffff80087552bc:	540005e0 	b.eq	0xffffff8008755378  // b.none
ffffff80087552c0:	52840020 	movz	w0, #0x2001
ffffff80087552c4:	6b00027f 	subs	wzr, w19, w0
ffffff80087552c8:	54fffe21 	b.ne	0xffffff800875528c  // b.any
ffffff80087552cc:	34001a36 	cbz	w22, 0xffffff8008755610
ffffff80087552d0:	710006df 	subs	wzr, w22, #0x1
ffffff80087552d4:	54fffdc1 	b.ne	0xffffff800875528c  // b.any
ffffff80087552d8:	f94004a0 	ldr	x0, [x5, #8]
ffffff80087552dc:	91014000 	add	x0, x0, #0x50
ffffff80087552e0:	d5033e9f 	dsb	st
ffffff80087552e4:	52a00041 	movz	w1, #0x2, lsl #16
ffffff80087552e8:	b9000001 	str	w1, [x0]
ffffff80087552ec:	52800000 	movz	w0, #0x0
ffffff80087552f0:	17ffffe8 	b	0xffffff8008755290
ffffff80087552f4:	128003e0 	movn	w0, #0x1f
ffffff80087552f8:	34fffcd5 	cbz	w21, 0xffffff8008755290
ffffff80087552fc:	6b15003f 	subs	wzr, w1, w21
ffffff8008755300:	54fffc8b 	b.lt	0xffffff8008755290  // b.tstop
ffffff8008755304:	510006b5 	sub	w21, w21, #0x1
ffffff8008755308:	f94004a0 	ldr	x0, [x5, #8]
ffffff800875530c:	53003eb5 	ubfm	w21, w21, #0, #15
ffffff8008755310:	8b150800 	add	x0, x0, x21, lsl #2
ffffff8008755314:	91015000 	add	x0, x0, #0x54
ffffff8008755318:	b9400000 	ldr	w0, [x0]
ffffff800875531c:	d5033d9f 	dsb	ld
ffffff8008755320:	3100041f 	adds	wzr, w0, #0x1
ffffff8008755324:	54001900 	b.eq	0xffffff8008755644  // b.none
ffffff8008755328:	f94210a1 	ldr	x1, [x5, #1056]
ffffff800875532c:	36000201 	tbz	w1, #0, 0xffffff800875536c
ffffff8008755330:	529f9c01 	movz	w1, #0xfce0
ffffff8008755334:	72bffc01 	movk	w1, #0xffe0, lsl #16
ffffff8008755338:	6a01001f 	ands	wzr, w0, w1
ffffff800875533c:	54000180 	b.eq	0xffffff800875536c  // b.none
ffffff8008755340:	910042a2 	add	x2, x21, #0x10
ffffff8008755344:	d37ef442 	ubfm	x2, x2, #62, #61
ffffff8008755348:	f94004a0 	ldr	x0, [x5, #8]
ffffff800875534c:	8b020000 	add	x0, x0, x2
ffffff8008755350:	91005000 	add	x0, x0, #0x14
ffffff8008755354:	b9400000 	ldr	w0, [x0]
ffffff8008755358:	d5033d9f 	dsb	ld
ffffff800875535c:	529f9c01 	movz	w1, #0xfce0
ffffff8008755360:	72bffc01 	movk	w1, #0xffe0, lsl #16
ffffff8008755364:	6a01001f 	ands	wzr, w0, w1
ffffff8008755368:	54ffff01 	b.ne	0xffffff8008755348  // b.any
ffffff800875536c:	b9000080 	str	w0, [x4]
ffffff8008755370:	52800000 	movz	w0, #0x0
ffffff8008755374:	17ffffc7 	b	0xffffff8008755290
ffffff8008755378:	128003e0 	movn	w0, #0x1f
ffffff800875537c:	34fff8b5 	cbz	w21, 0xffffff8008755290
ffffff8008755380:	6b15003f 	subs	wzr, w1, w21
ffffff8008755384:	54fff86b 	b.lt	0xffffff8008755290  // b.tstop
ffffff8008755388:	510006d6 	sub	w22, w22, #0x1
ffffff800875538c:	510006b5 	sub	w21, w21, #0x1
ffffff8008755390:	71004edf 	subs	wzr, w22, #0x13
ffffff8008755394:	53003eb5 	ubfm	w21, w21, #0, #15
ffffff8008755398:	54fff7a8 	b.hi	0xffffff800875528c  // b.pmore
ffffff800875539c:	f0003080 	adrp	x0, 0xffffff8008d68000
ffffff80087553a0:	9126c000 	add	x0, x0, #0x9b0
ffffff80087553a4:	78765800 	ldrh	w0, [x0, w22, uxtw #1]
ffffff80087553a8:	10000061 	adr	x1, 0xffffff80087553b4
ffffff80087553ac:	8b20a820 	add	x0, x1, w0, sxth #2
ffffff80087553b0:	d61f0000 	br	x0
ffffff80087553b4:	f9416a81 	ldr	x1, [x20, #720]
ffffff80087553b8:	91014021 	add	x1, x1, #0x50
ffffff80087553bc:	b9400021 	ldr	w1, [x1]
ffffff80087553c0:	d5033d9f 	dsb	ld
ffffff80087553c4:	1200b821 	and	w1, w1, #0x7fff7fff
ffffff80087553c8:	b9000081 	str	w1, [x4]
ffffff80087553cc:	52800000 	movz	w0, #0x0
ffffff80087553d0:	a94153f3 	ldp	x19, x20, [sp, #16]
ffffff80087553d4:	a9425bf5 	ldp	x21, x22, [sp, #32]
ffffff80087553d8:	a94363f7 	ldp	x23, x24, [sp, #48]
ffffff80087553dc:	f94023f9 	ldr	x25, [sp, #64]
ffffff80087553e0:	a8c67bfd 	ldp	x29, x30, [sp], #96
ffffff80087553e4:	d65f03c0 	ret
ffffff80087553e8:	f94004a1 	ldr	x1, [x5, #8]
ffffff80087553ec:	91012021 	add	x1, x1, #0x48
ffffff80087553f0:	b9400021 	ldr	w1, [x1]
ffffff80087553f4:	d5033d9f 	dsb	ld
ffffff80087553f8:	3100043f 	adds	wzr, w1, #0x1
ffffff80087553fc:	54001180 	b.eq	0xffffff800875562c  // b.none
ffffff8008755400:	f94210a0 	ldr	x0, [x5, #1056]
ffffff8008755404:	370005a0 	tbnz	w0, #0, 0xffffff80087554b8
ffffff8008755408:	53187c20 	ubfm	w0, w1, #24, #31
ffffff800875540c:	12170027 	and	w7, w1, #0x200
ffffff8008755410:	12180026 	and	w6, w1, #0x100
ffffff8008755414:	12140023 	and	w3, w1, #0x1000
ffffff8008755418:	39001480 	strb	w0, [x4, #5]
ffffff800875541c:	52800520 	movz	w0, #0x29
ffffff8008755420:	3900189f 	strb	wzr, [x4, #6]
ffffff8008755424:	39000480 	strb	w0, [x4, #1]
ffffff8008755428:	b94384a0 	ldr	w0, [x5, #900]
ffffff800875542c:	39000880 	strb	w0, [x4, #2]
ffffff8008755430:	b94384a2 	ldr	w2, [x5, #900]
ffffff8008755434:	6b1f005f 	subs	wzr, w2, wzr
ffffff8008755438:	11001c40 	add	w0, w2, #0x7
ffffff800875543c:	1a82b000 	csel	w0, w0, w2, lt  // lt = tstop
ffffff8008755440:	6b1f00ff 	subs	wzr, w7, wzr
ffffff8008755444:	13037c00 	sbfm	w0, w0, #3, #31
ffffff8008755448:	52800042 	movz	w2, #0x2
ffffff800875544c:	531f7800 	ubfm	w0, w0, #31, #30
ffffff8008755450:	1a9f1042 	csel	w2, w2, wzr, ne  // ne = any
ffffff8008755454:	11002400 	add	w0, w0, #0x9
ffffff8008755458:	39000080 	strb	w0, [x4]
ffffff800875545c:	34000066 	cbz	w6, 0xffffff8008755468
ffffff8008755460:	32000042 	orr	w2, w2, #0x1
ffffff8008755464:	53003c42 	ubfm	w2, w2, #0, #15
ffffff8008755468:	34000823 	cbz	w3, 0xffffff800875556c
ffffff800875546c:	321c0042 	orr	w2, w2, #0x10
ffffff8008755470:	78003082 	sturh	w2, [x4, #3]
ffffff8008755474:	f9416a80 	ldr	x0, [x20, #720]
ffffff8008755478:	91013000 	add	x0, x0, #0x4c
ffffff800875547c:	b9400000 	ldr	w0, [x0]
ffffff8008755480:	d5033d9f 	dsb	ld
ffffff8008755484:	12800001 	movn	w1, #0x0
ffffff8008755488:	b8007081 	stur	w1, [x4, #7]
ffffff800875548c:	39001c80 	strb	w0, [x4, #7]
ffffff8008755490:	b94384a2 	ldr	w2, [x5, #900]
ffffff8008755494:	71001c5f 	subs	wzr, w2, #0x7
ffffff8008755498:	54000c0c 	b.gt	0xffffff8008755618
ffffff800875549c:	39002081 	strb	w1, [x4, #8]
ffffff80087554a0:	52800000 	movz	w0, #0x0
ffffff80087554a4:	17ffff7b 	b	0xffffff8008755290
ffffff80087554a8:	f94004a1 	ldr	x1, [x5, #8]
ffffff80087554ac:	91012021 	add	x1, x1, #0x48
ffffff80087554b0:	b9400021 	ldr	w1, [x1]
ffffff80087554b4:	d5033d9f 	dsb	ld
ffffff80087554b8:	529c0000 	movz	w0, #0xe000
ffffff80087554bc:	72bf81e0 	movk	w0, #0xfc0f, lsl #16
ffffff80087554c0:	6a00003f 	ands	wzr, w1, w0
ffffff80087554c4:	54ffff21 	b.ne	0xffffff80087554a8  // b.any
ffffff80087554c8:	17ffffd0 	b	0xffffff8008755408
ffffff80087554cc:	710006df 	subs	wzr, w22, #0x1
ffffff80087554d0:	128003e0 	movn	w0, #0x1f
ffffff80087554d4:	a94153f3 	ldp	x19, x20, [sp, #16]
ffffff80087554d8:	a9425bf5 	ldp	x21, x22, [sp, #32]
ffffff80087554dc:	a94363f7 	ldp	x23, x24, [sp, #48]
ffffff80087554e0:	f94023f9 	ldr	x25, [sp, #64]
ffffff80087554e4:	1a9f8000 	csel	w0, w0, wzr, hi  // hi = pmore
ffffff80087554e8:	a8c67bfd 	ldp	x29, x30, [sp], #96
ffffff80087554ec:	d65f03c0 	ret
ffffff80087554f0:	128003e0 	movn	w0, #0x1f
ffffff80087554f4:	34ffecf5 	cbz	w21, 0xffffff8008755290
ffffff80087554f8:	6b15003f 	subs	wzr, w1, w21
ffffff80087554fc:	54ffecab 	b.lt	0xffffff8008755290  // b.tstop
ffffff8008755500:	510006b5 	sub	w21, w21, #0x1
ffffff8008755504:	710012df 	subs	wzr, w22, #0x4
ffffff8008755508:	53003eb5 	ubfm	w21, w21, #0, #15
ffffff800875550c:	54000b00 	b.eq	0xffffff800875566c  // b.none
ffffff8008755510:	710022df 	subs	wzr, w22, #0x8
ffffff8008755514:	540009c0 	b.eq	0xffffff800875564c  // b.none
ffffff8008755518:	71000adf 	subs	wzr, w22, #0x2
ffffff800875551c:	54ffeba1 	b.ne	0xffffff8008755290  // b.any
ffffff8008755520:	39406a81 	ldrb	w1, [x20, #26]
ffffff8008755524:	110006a0 	add	w0, w21, #0x1
ffffff8008755528:	6b00003f 	subs	wzr, w1, w0
ffffff800875552c:	54000d00 	b.eq	0xffffff80087556cc  // b.none
ffffff8008755530:	f94004a0 	ldr	x0, [x5, #8]
ffffff8008755534:	8b35c815 	add	x21, x0, w21, sxtw #2
ffffff8008755538:	910152b5 	add	x21, x21, #0x54
ffffff800875553c:	d5033e9f 	dsb	st
ffffff8008755540:	52800080 	movz	w0, #0x4
ffffff8008755544:	b90002a0 	str	w0, [x21]
ffffff8008755548:	52800000 	movz	w0, #0x0
ffffff800875554c:	17ffff51 	b	0xffffff8008755290
ffffff8008755550:	a94153f3 	ldp	x19, x20, [sp, #16]
ffffff8008755554:	a9425bf5 	ldp	x21, x22, [sp, #32]
ffffff8008755558:	a94363f7 	ldp	x23, x24, [sp, #48]
ffffff800875555c:	f94023f9 	ldr	x25, [sp, #64]
ffffff8008755560:	12800d60 	movn	w0, #0x6b
ffffff8008755564:	a8c67bfd 	ldp	x29, x30, [sp], #96
ffffff8008755568:	d65f03c0 	ret
ffffff800875556c:	365ff821 	tbz	w1, #11, 0xffffff8008755470
ffffff8008755570:	321d0042 	orr	w2, w2, #0x8
ffffff8008755574:	17ffffbf 	b	0xffffff8008755470
ffffff8008755578:	52800021 	movz	w1, #0x1
ffffff800875557c:	f94004a0 	ldr	x0, [x5, #8]
ffffff8008755580:	8b35c815 	add	x21, x0, w21, sxtw #2
ffffff8008755584:	910152b5 	add	x21, x21, #0x54
ffffff8008755588:	d5033e9f 	dsb	st
ffffff800875558c:	b90002a1 	str	w1, [x21]
ffffff8008755590:	52800000 	movz	w0, #0x0
ffffff8008755594:	17ffff3f 	b	0xffffff8008755290
ffffff8008755598:	52a00201 	movz	w1, #0x10, lsl #16
ffffff800875559c:	17fffff8 	b	0xffffff800875557c
ffffff80087555a0:	52a00101 	movz	w1, #0x8, lsl #16
ffffff80087555a4:	17fffff6 	b	0xffffff800875557c
ffffff80087555a8:	52a00081 	movz	w1, #0x4, lsl #16
ffffff80087555ac:	17fffff4 	b	0xffffff800875557c
ffffff80087555b0:	52a00041 	movz	w1, #0x2, lsl #16
ffffff80087555b4:	17fffff2 	b	0xffffff800875557c
ffffff80087555b8:	52800101 	movz	w1, #0x8
ffffff80087555bc:	17fffff0 	b	0xffffff800875557c
ffffff80087555c0:	52a00021 	movz	w1, #0x1, lsl #16
ffffff80087555c4:	17ffffee 	b	0xffffff800875557c
ffffff80087555c8:	52804001 	movz	w1, #0x200
ffffff80087555cc:	17ffffec 	b	0xffffff800875557c
ffffff80087555d0:	36000200 	tbz	w0, #0, 0xffffff8008755610
ffffff80087555d4:	36a00060 	tbz	w0, #20, 0xffffff80087555e0
ffffff80087555d8:	d5033e9f 	dsb	st
ffffff80087555dc:	b9000279 	str	w25, [x19]
ffffff80087555e0:	d5033e9f 	dsb	st
ffffff80087555e4:	b9000278 	str	w24, [x19]
ffffff80087555e8:	52800140 	movz	w0, #0xa
ffffff80087555ec:	97e7fe27 	bl	0xffffff8008154e88
ffffff80087555f0:	f9416a80 	ldr	x0, [x20, #720]
ffffff80087555f4:	9100f000 	add	x0, x0, #0x3c
ffffff80087555f8:	b9400000 	ldr	w0, [x0]
ffffff80087555fc:	d5033d9f 	dsb	ld
ffffff8008755600:	4b160000 	sub	w0, w0, w22
ffffff8008755604:	36780060 	tbz	w0, #15, 0xffffff8008755610
ffffff8008755608:	710006f7 	subs	w23, w23, #0x1
ffffff800875560c:	54000461 	b.ne	0xffffff8008755698  // b.any
ffffff8008755610:	52800000 	movz	w0, #0x0
ffffff8008755614:	17ffff1f 	b	0xffffff8008755290
ffffff8008755618:	d3483c00 	ubfm	x0, x0, #8, #15
ffffff800875561c:	39002481 	strb	w1, [x4, #9]
ffffff8008755620:	39002080 	strb	w0, [x4, #8]
ffffff8008755624:	52800000 	movz	w0, #0x0
ffffff8008755628:	17ffff1a 	b	0xffffff8008755290
ffffff800875562c:	b90380bf 	str	wzr, [x5, #896]
ffffff8008755630:	52820003 	movz	w3, #0x1000
ffffff8008755634:	52802006 	movz	w6, #0x100
ffffff8008755638:	52804007 	movz	w7, #0x200
ffffff800875563c:	52801fe0 	movz	w0, #0xff
ffffff8008755640:	17ffff76 	b	0xffffff8008755418
ffffff8008755644:	b90380bf 	str	wzr, [x5, #896]
ffffff8008755648:	17ffff49 	b	0xffffff800875536c
ffffff800875564c:	f94004a0 	ldr	x0, [x5, #8]
ffffff8008755650:	8b35c815 	add	x21, x0, w21, sxtw #2
ffffff8008755654:	910152b5 	add	x21, x21, #0x54
ffffff8008755658:	d5033e9f 	dsb	st
ffffff800875565c:	52802000 	movz	w0, #0x100
ffffff8008755660:	b90002a0 	str	w0, [x21]
ffffff8008755664:	52800000 	movz	w0, #0x0
ffffff8008755668:	17ffff0a 	b	0xffffff8008755290
ffffff800875566c:	f9416a80 	ldr	x0, [x20, #720]
ffffff8008755670:	8b352815 	add	x21, x0, w21, uxth #2
ffffff8008755674:	910152b3 	add	x19, x21, #0x54
ffffff8008755678:	9100f016 	add	x22, x0, #0x3c
ffffff800875567c:	b94002d6 	ldr	w22, [x22]
ffffff8008755680:	d5033d9f 	dsb	ld
ffffff8008755684:	1100cad6 	add	w22, w22, #0x32
ffffff8008755688:	528000d7 	movz	w23, #0x6
ffffff800875568c:	52a00219 	movz	w25, #0x10, lsl #16
ffffff8008755690:	52800218 	movz	w24, #0x10
ffffff8008755694:	53003ed6 	ubfm	w22, w22, #0, #15
ffffff8008755698:	52800295 	movz	w21, #0x14
ffffff800875569c:	b9400260 	ldr	w0, [x19]
ffffff80087556a0:	d5033d9f 	dsb	ld
ffffff80087556a4:	3100041f 	adds	wzr, w0, #0x1
ffffff80087556a8:	54fff540 	b.eq	0xffffff8008755550  // b.none
ffffff80087556ac:	3627f920 	tbz	w0, #4, 0xffffff80087555d0
ffffff80087556b0:	d2989580 	movz	x0, #0xc4ac
ffffff80087556b4:	f2a00400 	movk	x0, #0x20, lsl #16
ffffff80087556b8:	97f8c0c8 	bl	0xffffff80085859d8
ffffff80087556bc:	710006b5 	subs	w21, w21, #0x1
ffffff80087556c0:	54fffee1 	b.ne	0xffffff800875569c  // b.any
ffffff80087556c4:	52800000 	movz	w0, #0x0
ffffff80087556c8:	17fffef2 	b	0xffffff8008755290
ffffff80087556cc:	39406e80 	ldrb	w0, [x20, #27]
ffffff80087556d0:	360ff300 	tbz	w0, #1, 0xffffff8008755530
ffffff80087556d4:	f9409ca1 	ldr	x1, [x5, #312]
ffffff80087556d8:	aa0503e0 	orr	x0, xzr, x5
ffffff80087556dc:	d63f0020 	blr	x1
ffffff80087556e0:	52800000 	movz	w0, #0x0
ffffff80087556e4:	17fffeeb 	b	0xffffff8008755290
ffffff80087556e8:	a9bd7bfd 	stp	x29, x30, [sp, #-48]!
ffffff80087556ec:	910003fd 	add	x29, sp, #0x0
ffffff80087556f0:	f9000bf3 	str	x19, [sp, #16]
ffffff80087556f4:	aa1e03e0 	orr	x0, xzr, x30
ffffff80087556f8:	f90017a1 	str	x1, [x29, #40]
ffffff80087556fc:	d503201f 	hint	#0x0
ffffff8008755700:	f94017a1 	ldr	x1, [x29, #40]
ffffff8008755704:	f9406c33 	ldr	x19, [x1, #216]
ffffff8008755708:	b40000f3 	cbz	x19, 0xffffff8008755724
ffffff800875570c:	f9402660 	ldr	x0, [x19, #72]
ffffff8008755710:	b4000060 	cbz	x0, 0xffffff800875571c
ffffff8008755714:	52800001 	movz	w1, #0x0
ffffff8008755718:	97ea9585 	bl	0xffffff80081fad2c
ffffff800875571c:	aa1303e0 	orr	x0, xzr, x19
ffffff8008755720:	97ecb543 	bl	0xffffff8008282c2c
ffffff8008755724:	f9400bf3 	ldr	x19, [sp, #16]
ffffff8008755728:	52800000 	movz	w0, #0x0
ffffff800875572c:	a8c37bfd 	ldp	x29, x30, [sp], #48
ffffff8008755730:	d65f03c0 	ret
ffffff8008755734:	d10303ff 	sub	sp, sp, #0xc0
ffffff8008755738:	a9037bfd 	stp	x29, x30, [sp, #48]
ffffff800875573c:	9100c3fd 	add	x29, sp, #0x30
ffffff8008755740:	a90453f3 	stp	x19, x20, [sp, #64]
ffffff8008755744:	a9055bf5 	stp	x21, x22, [sp, #80]
ffffff8008755748:	a90663f7 	stp	x23, x24, [sp, #96]
ffffff800875574c:	a9076bf9 	stp	x25, x26, [sp, #112]
ffffff8008755750:	a90873fb 	stp	x27, x28, [sp, #128]
ffffff8008755754:	aa0003f4 	orr	x20, xzr, x0
ffffff8008755758:	aa1e03e0 	orr	x0, xzr, x30
ffffff800875575c:	d503201f 	hint	#0x0
ffffff8008755760:	b00061e0 	adrp	x0, 0xffffff8009392000
