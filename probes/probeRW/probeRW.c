// probeRW: physical memory read/write through ioremap.
//
// Same loading trick as probeG: module_init is never invoked on this ROM
// (struct module layout differs by 8 bytes), so all the work happens in
// module_exit and is triggered by rmmod.
//
// Usage:
//   insmod probeRW.ko addr=0x2d100000 len=64 op=r      # hexdump
//   insmod probeRW.ko addr=0x42300000 len=16 op=w val=0x5aa5c33c
//   insmod probeRW.ko addr=0x2d100000 len=0x300000 op=f val=0x00ff0000
//
// ioremap is used rather than __va because the interesting regions are outside
// the kernel's linear map: 0x42300000 sits in the DRAM hole between the two
// memory nodes, so it has no struct page and no linear alias.
#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/io.h>
#include <linux/mm.h>
#include <linux/fs.h>
#include <linux/string.h>
#include <linux/err.h>

#define BUFSZ 262144

static unsigned long addr;
static unsigned int  len = 64;
static char *op = "r";
static unsigned int val;
static unsigned int stride = 4;

module_param(addr, ulong, 0644);
module_param(len, uint, 0644);
module_param(op, charp, 0644);
module_param(val, uint, 0644);
module_param(stride, uint, 0644);

static char pbuf[BUFSZ];
static int  plen;

static void emit(const char *fmt, ...)
{
	va_list ap;
	int n;

	if (plen >= BUFSZ - 1)
		return;
	va_start(ap, fmt);
	n = vscnprintf(pbuf + plen, BUFSZ - plen - 1, fmt, ap);
	va_end(ap);
	plen += n;
}

static void put_file(const char *path, const char *data, int l)
{
	struct file *f;
	loff_t pos = 0;

	f = filp_open(path, O_WRONLY | O_CREAT | O_TRUNC, 0644);
	if (IS_ERR(f))
		return;
	kernel_write(f, data, (size_t)l, pos);
	filp_close(f, NULL);
}

static int __init proberw_init(void)
{
	return 0;
}

static void __exit proberw_exit(void)
{
	volatile unsigned char *p;
	unsigned int i;
	int linear = 0;

	emit("probeRW op=%s addr=%#lx len=%u val=%#x\n", op, addr, len, val);

	if (!addr || len > 262144) {
		emit("bad args\n");
		goto out;
	}

	/*
	 * Two very different kinds of target live here.  Anything with a struct
	 * page is already in the kernel's linear map and ioremap() refuses it
	 * outright; the DRAM hole between the memory nodes has no page and no
	 * linear alias, so it must go through ioremap().  Same test the ramoops
	 * feasibility check used.
	 */
	if (pfn_valid(addr >> PAGE_SHIFT)) {
		p = (volatile unsigned char *)phys_to_virt(addr);
		linear = 1;
		emit("linear alias\n");
	} else {
		p = (volatile unsigned char *)ioremap(addr, len);
		emit("ioremap\n");
	}
	if (!p) {
		emit("map failed\n");
		goto out;
	}

	if (!strcmp(op, "r")) {
		for (i = 0; i < len; i += 16) {
			unsigned int j;

			emit("%016lx:", addr + i);
			for (j = 0; j < 16 && i + j < len; j++)
				emit(" %02x", p[i + j]);
			emit("\n");
		}
	} else if (!strcmp(op, "w")) {
		unsigned int s = stride ? stride : 4;

		for (i = 0; i + s <= len; i += s)
			*(volatile unsigned int *)(p + i) = val;
		emit("wrote %#x every %u bytes, %u bytes total\n",
		     val, s, len);
	} else if (!strcmp(op, "f")) {
		for (i = 0; i + 4 <= len; i += 4)
			*(volatile unsigned int *)(p + i) = val;
		emit("filled %u bytes with %#x\n", len, val);
	} else {
		emit("unknown op\n");
	}

	if (!linear)
		iounmap((void __iomem *)p);

out:
	put_file("/data/local/tmp/probeRW.out", pbuf, plen);
}

module_init(proberw_init);
module_exit(proberw_exit);
MODULE_LICENSE("GPL");
MODULE_DESCRIPTION("physical memory read/write probe");
