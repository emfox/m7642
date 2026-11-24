import os
D=os.path.expanduser("~/Debian/m7642/probes/handoff")

# ---- tramp: 在 _start_kva 里自校准，x27=kimage x28=memstart_addr x29=lin ----
p=os.path.join(D,"tramp-postmmu.S"); s=open(p).read()
old="""_start_kva:
	adr	x16, 1f
	movz	x17, #(KIMAGE_OFFSET & 0xffff)
	movk	x17, #((KIMAGE_OFFSET >> 16) & 0xffff), lsl #16
	movk	x17, #((KIMAGE_OFFSET >> 32) & 0xffff), lsl #32
	movk	x17, #((KIMAGE_OFFSET >> 48) & 0xffff), lsl #48	/* KIMAGE_VADDR - PA(_text) */
	sub	x16, x16, x17
	br	x16"""
new="""_start_kva:
	adr	x16, 1f
	/* Self-calibration: the idmap may or may not exist here, so never assume
	 * a VA->PA offset.  Ask the MMU for our own physical address. */
	at	s1e1r, x16
	mrs	x17, par_el1
	tst	x17, #1			/* F = 1 -> this VA was not translatable */
	b.ne	3f
	and	x17, x17, #0x0000fffffffff000
	and	x18, x16, #0xfff
	orr	x17, x17, x18		/* PA of label 1f */
	sub	x27, x16, x17		/* x27 = kimage = VA - PA */
	/* memstart_addr (link VA ffffffc080441dd8) is inside the image, so it is
	 * reachable through the image mapping with the offset we just measured. */
	movz	x19, #0x1dd8
	movk	x19, #0x8044, lsl #16
	movk	x19, #0xffc0, lsl #32
	add	x19, x19, x27
	ldr	x28, [x19]		/* x28 = memstart_addr */
	/* PAGE_OFFSET for VA_BITS=39 */
	movz	x20, #0x0000
	movk	x20, #0xff80, lsl #48
	sub	x29, x20, x28		/* x29 = lin = PAGE_OFFSET - memstart_addr */
	b	4f
3:	mov	x27, xzr			/* untranslatable: fall back to PA mode */
	mov	x28, xzr
	mov	x29, xzr
4:
	adr	x16, 1f
	movz	x17, #(KIMAGE_OFFSET & 0xffff)
	movk	x17, #((KIMAGE_OFFSET >> 16) & 0xffff), lsl #16
	movk	x17, #((KIMAGE_OFFSET >> 32) & 0xffff), lsl #32
	movk	x17, #((KIMAGE_OFFSET >> 48) & 0xffff), lsl #48
	sub	x16, x16, x17
	br	x16"""
assert old in s, "tramp anchor missing"
s=s.replace(old,new,1); open(p,"w").write(s); print("tramp: 自校准已加")

# ---- abort: 记录 x27/x28/x29 ----
p=os.path.join(D,"abort-postmmu.S"); s=open(p).read()
if "str\tx27" not in s:
    s=s.replace("""	str	x26, [x6, #104]""","""	str	x26, [x6, #104]
	str	x27, [x6, #112]		/* kimage = VA - PA (measured with AT) */
	str	x28, [x6, #120]		/* memstart_addr */
	str	x29, [x6, #128]		/* lin = PAGE_OFFSET - memstart_addr */""",1)
    s=s.replace("mov\tw7, #0x70","mov\tw7, #0x90",1)
    open(p,"w").write(s); print("abort: 三个校准值已记录（size 0x90）")
