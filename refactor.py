import os, re
D=os.path.expanduser("~/Debian/m7642/probes/fcie")

# ---- 1. fcie_read.c: 换成共享头，删掉重复定义 ----
p=os.path.join(D,"fcie_read.c"); s=open(p).read()
if '#include "fcie_regs.h"' not in s:
    # 删掉 typedefs（4 行）与它到 "/* ---- the block read" 之前的所有定义/helper
    start=s.index("typedef unsigned char      u8;")
    end=s.index("/* ---- the block read")
    s = s[:start] + '#include "fcie_regs.h"\n\n' + s[end:]
    open(p,"w").write(s); print("fcie_read.c 已改用共享头")

# ---- 2. fcie_write.c: 用本地名字的 memcpy/memcmp，避免与 libc 冲突 ----
p=os.path.join(D,"fcie_write.c"); s=open(p).read()
s=s.replace("""void *memcpy(void *d, const void *s, u64 n);
int memcmp(const void *a, const void *b, u64 n);""",
"""/* freestanding: no libc, so bring our own two (named to avoid a clash if a
 * libc ever gets linked in). */
static void m_copy(void *d, const void *s, u64 n)
{
	u8 *dd = (u8 *)d; const u8 *ss = (const u8 *)s;
	while (n--) *dd++ = *ss++;
}

static int m_cmp(const void *a, const void *b, u64 n)
{
	const u8 *x = (const u8 *)a, *y = (const u8 *)b;
	while (n--) { if (*x != *y) return (int)*x - (int)*y; x++; y++; }
	return 0;
}""")
s=s.replace("if (memcmp(wbuf, rbuf, 512) == 0)","if (m_cmp(wbuf, rbuf, 512) == 0)")
open(p,"w").write(s); print("fcie_write.c memcpy/memcmp 本地化")
