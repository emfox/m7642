import os, re
H = os.path.expanduser("~/Debian/m7642/probes/handoff")

# --- 1) build-postmmu.sh: 传 SAVE_PA 与 SYM*_VA ---
p = os.path.join(H, "build-postmmu.sh"); s = open(p).read()
if "SAVE_PA" not in s:
    s = s.replace('echo "defs: $DEFS  WORLD_VA=${WORLD_VA:-0}"',
'''# SAVE_VA lives in the image; the handover stub runs with the MMU off, so it
# needs the physical address.  PA = VA - KIMAGE_OFFSET.
SAVE_VA=${SAVE_VA:-0xffffffc080603000}
SAVE_PA=$(python3 -c "print(hex($SAVE_VA - ${DEFS##*-DKIMAGE_OFFSET=}))" 2>/dev/null || echo 0x20883000)
SYMDEFS=""
i=0
for spec in ${READOUT_SYMS:-}; do
	SYMDEFS="$SYMDEFS -DSYM${i}_VA=$spec"
	i=$((i+1))
	[ $i -ge 8 ] && break
done
DEFS="$DEFS -DSAVE_PA=$SAVE_PA $SYMDEFS"
echo "defs: $DEFS  WORLD_VA=${WORLD_VA:-0}"''')
    open(p, "w").write(s); print("build-postmmu.sh: SAVE_PA/SYM 已接")

# --- 2) abort-postmmu.S: 把 SAVE 页的 8 个 qword 抄进记录 ---
p = os.path.join(H, "abort-postmmu.S"); s = open(p).read()
if "SAVE_PA" not in s:
    s = s.replace("""	mrs	x17, mpidr_el1
	str	x17, [x6, #168]
	dsb	sy""",
"""	mrs	x17, mpidr_el1
	str	x17, [x6, #168]
#ifdef SAVE_PA
	/* The readout probe parked kernel variables here; the 32 MB copy below
	 * overwrites the whole image, so rescue them into the record first. */
	movz	x16, #(SAVE_PA & 0xffff)
	movk	x16, #((SAVE_PA >> 16) & 0xffff), lsl #16
	ldp	x17, x18, [x16, #0x40]
	stp	x17, x18, [x6, #0xb0]
	ldp	x17, x18, [x16, #0x50]
	stp	x17, x18, [x6, #0xc0]
	ldp	x17, x18, [x16, #0x60]
	stp	x17, x18, [x6, #0xd0]
	ldp	x17, x18, [x16, #0x70]
	stp	x17, x18, [x6, #0xe0]
	mov	w7, #0xf0
	str	w7, [x6, #8]
#endif
	dsb	sy""")
    open(p, "w").write(s); print("abort-postmmu.S: SAVE 页 → 记录(0xB0..0xEF)")

# --- 3) mk-multi.sh: 支持 readout 入口 + 符号解析 ---
p = os.path.join(H, "mk-multi.sh"); s = open(p).read()
if "readout" not in s:
    s = s.replace('	restore) tgt=$(( TRAMP_AT + 0x500 )) ;;',
                  '	restore) tgt=$(( TRAMP_AT + 0x500 )) ;;\n\treadout) tgt=$(( TRAMP_AT + 0x600 )) ;;')
    s = s.replace('''resolve() { python3 ../../tools/host/ckpt.py --sysmap "$SYSMAP" --env "$1" | cut -d= -f2; }''',
'''resolve() { python3 ../../tools/host/ckpt.py --sysmap "$SYSMAP" --env "$1" | cut -d= -f2; }
# readout symbols: "name" or "name+delta", comma or space separated
syms_to_vas() {
	python3 - "$SYSMAP" "$1" <<'PY'
import sys
syms = {}
for line in open(sys.argv[1]):
    p = line.split()
    if len(p) >= 3: syms[p[2]] = int(p[0], 16)
out = []
for spec in sys.argv[2].replace(",", " ").split():
    name, _, delta = spec.partition("+")
    if name in syms: out.append(hex(syms[name] + (int(delta, 0) if delta else 0)))
    else: sys.stderr.write("no such symbol: %s\\n" % name)
print(" ".join(out))
PY
}
READOUT_SYMS=$(syms_to_vas "${READOUT_SYMS:-totalram_pages memblock+32 memblock+72 max_pfn}")
export READOUT_SYMS''')
    open(p, "w").write(s); print("mk-multi.sh: readout 入口 + 符号解析")
