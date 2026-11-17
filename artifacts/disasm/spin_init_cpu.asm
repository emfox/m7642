
spin_init_cpu.bin:     file format binary


Disassembly of section .data:

ffffff8009028814 <.data>:
ffffff8009028814:	a9be7bfd 	stp	x29, x30, [sp, #-32]!
ffffff8009028818:	d2800001 	movz	x1, #0x0
ffffff800902881c:	910003fd 	add	x29, sp, #0x0
ffffff8009028820:	f9000bf3 	str	x19, [sp, #16]
ffffff8009028824:	2a0003f3 	orr	w19, wzr, w0
ffffff8009028828:	97e091d5 	bl	0xffffff800884cf7c
ffffff800902882c:	12800242 	movn	w2, #0x12
ffffff8009028830:	b40001c0 	cbz	x0, 0xffffff8009028868
ffffff8009028834:	90fff301 	adrp	x1, 0xffffff8008e88000
ffffff8009028838:	90001982 	adrp	x2, 0xffffff8009358000
ffffff800902883c:	9103e021 	add	x1, x1, #0xf8
ffffff8009028840:	911a8042 	add	x2, x2, #0x6a0
ffffff8009028844:	8b334c42 	add	x2, x2, w19, uxtw #3
ffffff8009028848:	97e08a8c 	bl	0xffffff800884b278
ffffff800902884c:	2a0003e2 	orr	w2, wzr, w0
ffffff8009028850:	340000c0 	cbz	w0, 0xffffff8009028868
ffffff8009028854:	90fff300 	adrp	x0, 0xffffff8008e88000
ffffff8009028858:	2a1303e1 	orr	w1, wzr, w19
ffffff800902885c:	91044000 	add	x0, x0, #0x110
ffffff8009028860:	97c717f6 	bl	0xffffff80081ee838
ffffff8009028864:	12800002 	movn	w2, #0x0
ffffff8009028868:	2a0203e0 	orr	w0, wzr, w2
ffffff800902886c:	f9400bf3 	ldr	x19, [sp, #16]
ffffff8009028870:	a8c27bfd 	ldp	x29, x30, [sp], #32
ffffff8009028874:	d65f03c0 	ret
ffffff8009028878:	a9bf7bfd 	stp	x29, x30, [sp, #-16]!
ffffff800902887c:	d0001982 	adrp	x2, 0xffffff800935a000
ffffff8009028880:	90ff8301 	adrp	x1, 0xffffff8008088000
ffffff8009028884:	910003fd 	add	x29, sp, #0x0
ffffff8009028888:	9126e021 	add	x1, x1, #0x9b8
ffffff800902888c:	d0000da0 	adrp	x0, 0xffffff80091de000
ffffff8009028890:	f900b441 	str	x1, [x2, #360]
ffffff8009028894:	90001982 	adrp	x2, 0xffffff8009358000
ffffff8009028898:	90ff8301 	adrp	x1, 0xffffff8008088000
ffffff800902889c:	9121c000 	add	x0, x0, #0x870
ffffff80090288a0:	91263021 	add	x1, x1, #0x98c
ffffff80090288a4:	f904e441 	str	x1, [x2, #2504]
ffffff80090288a8:	97c42d6c 	bl	0xffffff8008133e58
ffffff80090288ac:	52800000 	movz	w0, #0x0
ffffff80090288b0:	a8c17bfd 	ldp	x29, x30, [sp], #16
ffffff80090288b4:	d65f03c0 	ret
	...
ffffff80090288c0:	d0000da1 	adrp	x1, 0xffffff80091de000
ffffff80090288c4:	52800000 	movz	w0, #0x0
ffffff80090288c8:	3927803f 	strb	wzr, [x1, #2528]
ffffff80090288cc:	d65f03c0 	ret
ffffff80090288d0:	a9bf7bfd 	stp	x29, x30, [sp, #-16]!
ffffff80090288d4:	52800043 	movz	w3, #0x2
ffffff80090288d8:	90fff304 	adrp	x4, 0xffffff8008e88000
ffffff80090288dc:	d0ff8301 	adrp	x1, 0xffffff800808a000
ffffff80090288e0:	910003fd 	add	x29, sp, #0x0
ffffff80090288e4:	72a00063 	movk	w3, #0x3, lsl #16
ffffff80090288e8:	9110a084 	add	x4, x4, #0x428
ffffff80090288ec:	528000a2 	movz	w2, #0x5
ffffff80090288f0:	912e4021 	add	x1, x1, #0xb90
ffffff80090288f4:	52800020 	movz	w0, #0x1
ffffff80090288f8:	94003d7a 	bl	0xffffff8009037ee0
ffffff80090288fc:	52800023 	movz	w3, #0x1
ffffff8009028900:	90fff304 	adrp	x4, 0xffffff8008e88000
ffffff8009028904:	d0ff8301 	adrp	x1, 0xffffff800808a000
ffffff8009028908:	72a00063 	movk	w3, #0x3, lsl #16
ffffff800902890c:	528000c0 	movz	w0, #0x6
ffffff8009028910:	91110084 	add	x4, x4, #0x440
ffffff8009028914:	528000a2 	movz	w2, #0x5
ffffff8009028918:	912ac021 	add	x1, x1, #0xab0
ffffff800902891c:	94003d71 	bl	0xffffff8009037ee0
ffffff8009028920:	52800000 	movz	w0, #0x0
ffffff8009028924:	a8c17bfd 	ldp	x29, x30, [sp], #16
ffffff8009028928:	d65f03c0 	ret
ffffff800902892c:	90001981 	adrp	x1, 0xffffff8009358000
ffffff8009028930:	9126e021 	add	x1, x1, #0x9b8
ffffff8009028934:	f9400422 	ldr	x2, [x1, #8]
ffffff8009028938:	b5000042 	cbnz	x2, 0xffffff8009028940
ffffff800902893c:	f9000420 	str	x0, [x1, #8]
ffffff8009028940:	d65f03c0 	ret
ffffff8009028944:	a9bf7bfd 	stp	x29, x30, [sp, #-16]!
ffffff8009028948:	910003fd 	add	x29, sp, #0x0
ffffff800902894c:	94026385 	bl	0xffffff80090c1760
ffffff8009028950:	90001980 	adrp	x0, 0xffffff8009358000
ffffff8009028954:	f944e000 	ldr	x0, [x0, #2496]
ffffff8009028958:	b5000080 	cbnz	x0, 0xffffff8009028968
ffffff800902895c:	90fff300 	adrp	x0, 0xffffff8008e88000
ffffff8009028960:	91136000 	add	x0, x0, #0x4d8
ffffff8009028964:	97c7168c 	bl	0xffffff80081ee394
ffffff8009028968:	a8c17bfd 	ldp	x29, x30, [sp], #16
ffffff800902896c:	d65f03c0 	ret
ffffff8009028970:	a9be7bfd 	stp	x29, x30, [sp, #-32]!
ffffff8009028974:	90000d20 	adrp	x0, 0xffffff80091cc000
ffffff8009028978:	910003fd 	add	x29, sp, #0x0
ffffff800902897c:	f9000bf3 	str	x19, [sp, #16]
ffffff8009028980:	aa0003f3 	orr	x19, xzr, x0
ffffff8009028984:	f9438c00 	ldr	x0, [x0, #1816]
ffffff8009028988:	360001c0 	tbz	w0, #0, 0xffffff80090289c0
ffffff800902898c:	d0000da0 	adrp	x0, 0xffffff80091de000
ffffff8009028990:	91282000 	add	x0, x0, #0xa08
ffffff8009028994:	97c676ba 	bl	0xffffff80081c647c
ffffff8009028998:	f0ff8304 	adrp	x4, 0xffffff800808b000
ffffff800902899c:	90fff301 	adrp	x1, 0xffffff8008e88000
ffffff80090289a0:	52800005 	movz	w5, #0x0
ffffff80090289a4:	91113084 	add	x4, x4, #0x44c
ffffff80090289a8:	d2800003 	movz	x3, #0x0
ffffff80090289ac:	52800002 	movz	w2, #0x0
ffffff80090289b0:	9113e021 	add	x1, x1, #0x4f8
ffffff80090289b4:	52800220 	movz	w0, #0x11
ffffff80090289b8:	97c2992c 	bl	0xffffff80080cee68
ffffff80090289bc:	14000004 	b	0xffffff80090289cc
ffffff80090289c0:	90fff300 	adrp	x0, 0xffffff8008e88000
ffffff80090289c4:	91144000 	add	x0, x0, #0x510
ffffff80090289c8:	97c7179c 	bl	0xffffff80081ee838
ffffff80090289cc:	f9438e60 	ldr	x0, [x19, #1816]
ffffff80090289d0:	37080080 	tbnz	w0, #1, 0xffffff80090289e0
ffffff80090289d4:	90fff300 	adrp	x0, 0xffffff8008e88000
ffffff80090289d8:	9114e000 	add	x0, x0, #0x538
ffffff80090289dc:	97c71797 	bl	0xffffff80081ee838
ffffff80090289e0:	52800000 	movz	w0, #0x0
ffffff80090289e4:	f9400bf3 	ldr	x19, [sp, #16]
ffffff80090289e8:	a8c27bfd 	ldp	x29, x30, [sp], #32
ffffff80090289ec:	d65f03c0 	ret
ffffff80090289f0:	d0000da1 	adrp	x1, 0xffffff80091de000
ffffff80090289f4:	52800000 	movz	w0, #0x0
ffffff80090289f8:	9128a021 	add	x1, x1, #0xa28
ffffff80090289fc:	b9407022 	ldr	w2, [x1, #112]
ffffff8009028a00:	321f0042 	orr	w2, w2, #0x2
ffffff8009028a04:	b9007022 	str	w2, [x1, #112]
ffffff8009028a08:	d65f03c0 	ret
ffffff8009028a0c:	d0000da1 	adrp	x1, 0xffffff80091de000
ffffff8009028a10:	52800000 	movz	w0, #0x0
ffffff8009028a14:	9128a021 	add	x1, x1, #0xa28
ffffff8009028a18:	b9410822 	ldr	w2, [x1, #264]
ffffff8009028a1c:	321f0042 	orr	w2, w2, #0x2
ffffff8009028a20:	b9010822 	str	w2, [x1, #264]
ffffff8009028a24:	d65f03c0 	ret
ffffff8009028a28:	a9be7bfd 	stp	x29, x30, [sp, #-32]!
ffffff8009028a2c:	52800104 	movz	w4, #0x8
ffffff8009028a30:	f0fffa42 	adrp	x2, 0xffffff8008f73000
ffffff8009028a34:	910003fd 	add	x29, sp, #0x0
ffffff8009028a38:	a90153f3 	stp	x19, x20, [sp, #16]
ffffff8009028a3c:	90fff773 	adrp	x19, 0xffffff8008f14000
ffffff8009028a40:	52800006 	movz	w6, #0x0
ffffff8009028a44:	91038273 	add	x19, x19, #0xe0
ffffff8009028a48:	52800025 	movz	w5, #0x1
ffffff8009028a4c:	2a0403e3 	orr	w3, wzr, w4
ffffff8009028a50:	913ac042 	add	x2, x2, #0xeb0
ffffff8009028a54:	aa1303e1 	orr	x1, xzr, x19
ffffff8009028a58:	aa0003f4 	orr	x20, xzr, x0
ffffff8009028a5c:	97c63cf1 	bl	0xffffff80081b7e20
ffffff8009028a60:	35000140 	cbnz	w0, 0xffffff8009028a88
ffffff8009028a64:	90fff302 	adrp	x2, 0xffffff8008e88000
ffffff8009028a68:	52800006 	movz	w6, #0x0
ffffff8009028a6c:	52800025 	movz	w5, #0x1
ffffff8009028a70:	52800104 	movz	w4, #0x8
ffffff8009028a74:	52800203 	movz	w3, #0x10
ffffff8009028a78:	911ac042 	add	x2, x2, #0x6b0
ffffff8009028a7c:	aa1303e1 	orr	x1, xzr, x19
ffffff8009028a80:	aa1403e0 	orr	x0, xzr, x20
ffffff8009028a84:	97c63ce7 	bl	0xffffff80081b7e20
ffffff8009028a88:	a94153f3 	ldp	x19, x20, [sp, #16]
ffffff8009028a8c:	a8c27bfd 	ldp	x29, x30, [sp], #32
ffffff8009028a90:	d65f03c0 	ret
ffffff8009028a94:	a9be7bfd 	stp	x29, x30, [sp, #-32]!
ffffff8009028a98:	52800104 	movz	w4, #0x8
ffffff8009028a9c:	f0fffa42 	adrp	x2, 0xffffff8008f73000
ffffff8009028aa0:	90fff761 	adrp	x1, 0xffffff8008f14000
ffffff8009028aa4:	910003fd 	add	x29, sp, #0x0
ffffff8009028aa8:	52800006 	movz	w6, #0x0
ffffff8009028aac:	52800025 	movz	w5, #0x1
ffffff8009028ab0:	2a0403e3 	orr	w3, wzr, w4
ffffff8009028ab4:	913ac042 	add	x2, x2, #0xeb0
ffffff8009028ab8:	91038021 	add	x1, x1, #0xe0
ffffff8009028abc:	f9000bf3 	str	x19, [sp, #16]
ffffff8009028ac0:	aa0003f3 	orr	x19, xzr, x0
ffffff8009028ac4:	97c63cd7 	bl	0xffffff80081b7e20
ffffff8009028ac8:	35000160 	cbnz	w0, 0xffffff8009028af4
ffffff8009028acc:	90fff302 	adrp	x2, 0xffffff8008e88000
ffffff8009028ad0:	90fff301 	adrp	x1, 0xffffff8008e88000
ffffff8009028ad4:	52800006 	movz	w6, #0x0
ffffff8009028ad8:	52800005 	movz	w5, #0x0
ffffff8009028adc:	52800604 	movz	w4, #0x30
ffffff8009028ae0:	52800203 	movz	w3, #0x10
ffffff8009028ae4:	911ae042 	add	x2, x2, #0x6b8
ffffff8009028ae8:	911b0021 	add	x1, x1, #0x6c0
ffffff8009028aec:	aa1303e0 	orr	x0, xzr, x19
ffffff8009028af0:	97c63ccc 	bl	0xffffff80081b7e20
ffffff8009028af4:	f9400bf3 	ldr	x19, [sp, #16]
ffffff8009028af8:	a8c27bfd 	ldp	x29, x30, [sp], #32
ffffff8009028afc:	d65f03c0 	ret
ffffff8009028b00:	a9bd7bfd 	stp	x29, x30, [sp, #-48]!
ffffff8009028b04:	910003fd 	add	x29, sp, #0x0
ffffff8009028b08:	a9025bf5 	stp	x21, x22, [sp, #32]
ffffff8009028b0c:	90000d36 	adrp	x22, 0xffffff80091cc000
ffffff8009028b10:	90000d35 	adrp	x21, 0xffffff80091cc000
ffffff8009028b14:	a90153f3 	stp	x19, x20, [sp, #16]
ffffff8009028b18:	911d62d6 	add	x22, x22, #0x758
ffffff8009028b1c:	12800013 	movn	w19, #0x0
ffffff8009028b20:	912282b5 	add	x21, x21, #0x8a0
ffffff8009028b24:	f0000b34 	adrp	x20, 0xffffff800918f000
ffffff8009028b28:	91136294 	add	x20, x20, #0x4d8
ffffff8009028b2c:	11000662 	add	w2, w19, #0x1
ffffff8009028b30:	d2800081 	movz	x1, #0x4
ffffff8009028b34:	aa1603e0 	orr	x0, xzr, x22
ffffff8009028b38:	93407c42 	sbfm	x2, x2, #0, #31
ffffff8009028b3c:	97d5ecd8 	bl	0xffffff80085a3e9c
ffffff8009028b40:	2a0003f3 	orr	w19, wzr, w0
ffffff8009028b44:	b94002a1 	ldr	w1, [x21]
ffffff8009028b48:	6b01001f 	subs	wzr, w0, w1
ffffff8009028b4c:	2a0003e1 	orr	w1, wzr, w0
ffffff8009028b50:	5400014a 	b.ge	0xffffff8009028b78  // b.tcont
ffffff8009028b54:	b0000d22 	adrp	x2, 0xffffff80091cd000
ffffff8009028b58:	91314042 	add	x2, x2, #0xc50
ffffff8009028b5c:	f860d843 	ldr	x3, [x2, w0, sxtw #3]
ffffff8009028b60:	52800022 	movz	w2, #0x1
ffffff8009028b64:	8b030283 	add	x3, x20, x3
ffffff8009028b68:	aa0303e0 	orr	x0, xzr, x3
ffffff8009028b6c:	b9000462 	str	w2, [x3, #4]
ffffff8009028b70:	97d90a71 	bl	0xffffff800866b534
ffffff8009028b74:	17ffffee 	b	0xffffff8009028b2c
ffffff8009028b78:	52800000 	movz	w0, #0x0
ffffff8009028b7c:	a94153f3 	ldp	x19, x20, [sp, #16]
ffffff8009028b80:	a9425bf5 	ldp	x21, x22, [sp, #32]
ffffff8009028b84:	a8c37bfd 	ldp	x29, x30, [sp], #48
ffffff8009028b88:	d65f03c0 	ret
ffffff8009028b8c:	a9bf7bfd 	stp	x29, x30, [sp, #-16]!
ffffff8009028b90:	d0000da1 	adrp	x1, 0xffffff80091de000
ffffff8009028b94:	b0001980 	adrp	x0, 0xffffff8009359000
ffffff8009028b98:	910003fd 	add	x29, sp, #0x0
ffffff8009028b9c:	91312021 	add	x1, x1, #0xc48
ffffff8009028ba0:	91176000 	add	x0, x0, #0x5d8
ffffff8009028ba4:	97c332da 	bl	0xffffff80080f570c
ffffff8009028ba8:	52800000 	movz	w0, #0x0
ffffff8009028bac:	a8c17bfd 	ldp	x29, x30, [sp], #16
ffffff8009028bb0:	d65f03c0 	ret
ffffff8009028bb4:	a9bf7bfd 	stp	x29, x30, [sp, #-16]!
ffffff8009028bb8:	910003fd 	add	x29, sp, #0x0
ffffff8009028bbc:	d53800a1 	mrs	x1, mpidr_el1
ffffff8009028bc0:	b2405fe0 	orr	x0, xzr, #0xffffff
ffffff8009028bc4:	f2c01fe0 	movk	x0, #0xff, lsl #32
ffffff8009028bc8:	8a000021 	and	x1, x1, x0
ffffff8009028bcc:	d0000da0 	adrp	x0, 0xffffff80091de000
ffffff8009028bd0:	f9063001 	str	x1, [x0, #3168]
ffffff8009028bd4:	d2800000 	movz	x0, #0x0
ffffff8009028bd8:	d518d080 	msr	tpidr_el1, x0
ffffff8009028bdc:	90fff300 	adrp	x0, 0xffffff8008e88000
ffffff8009028be0:	91202000 	add	x0, x0, #0x808
ffffff8009028be4:	97c71715 	bl	0xffffff80081ee838
ffffff8009028be8:	a8c17bfd 	ldp	x29, x30, [sp], #16
ffffff8009028bec:	d65f03c0 	ret
ffffff8009028bf0:	a9b67bfd 	stp	x29, x30, [sp, #-160]!
ffffff8009028bf4:	910003fd 	add	x29, sp, #0x0
ffffff8009028bf8:	a9025bf5 	stp	x21, x22, [sp, #32]
ffffff8009028bfc:	a90153f3 	stp	x19, x20, [sp, #16]
ffffff8009028c00:	a90363f7 	stp	x23, x24, [sp, #48]
ffffff8009028c04:	a9046bf9 	stp	x25, x26, [sp, #64]
ffffff8009028c08:	f9002bfb 	str	x27, [sp, #80]
ffffff8009028c0c:	90000d35 	adrp	x21, 0xffffff80091cc000
ffffff8009028c10:	aa0003f6 	orr	x22, xzr, x0
