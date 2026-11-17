// probeG: generic probe driven by module parameters.
// Module params are applied by the loader itself, so they work even though
// module_init is never invoked on this ROM (struct module layout mismatch).
// The work happens in module_exit, triggered by `rmmod`.
//
// Usage:
//   insmod probeG.ko sym=MHal_GFLIP_ReadGopReg len=256    # dump code
//   insmod probeG.ko csym=MDrv_PM_GetChipID               # call, print ret
//   insmod probeG.ko addr=0xffffff8009358048 len=64       # raw dump
#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/fs.h>
#include <linux/string.h>
#include <linux/kallsyms.h>
#include <linux/err.h>

#define BUFSZ 262144

static unsigned long addr;
static unsigned int  len = 256;
static char *what = "dump";
static char *sym;
static char *csym;
static unsigned long a0, a1, a2, a3;

module_param(addr, ulong, 0644);
module_param(len, uint, 0644);
module_param(what, charp, 0644);
module_param(sym, charp, 0644);
module_param(csym, charp, 0644);
module_param(a0, ulong, 0644);
module_param(a1, ulong, 0644);
module_param(a2, ulong, 0644);
module_param(a3, ulong, 0644);

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

static void hexdump(unsigned long base, unsigned int n)
{
	unsigned int i;

	if (n > 131072)
		n = 131072;
	for (i = 0; i < n; i += 16) {
		unsigned int j;

		emit("%016lx:", base + i);
		for (j = 0; j < 16 && i + j < n; j++)
			emit(" %02x", *(volatile unsigned char *)(base + i + j));
		emit("\n");
	}
}

static int __init probeg_init(void)
{
	return 0;
}

static void __exit probeg_exit(void)
{
	unsigned long target = addr;
	unsigned long ret;

	emit("probeG what=%s len=%u\n", what, len);

	if (sym && sym[0]) {
		target = kallsyms_lookup_name(sym);
		emit("sym %s -> %#lx\n", sym, target);
		if (!target) {
			emit("symbol not found\n");
			goto out;
		}
	} else if (csym && csym[0]) {
		unsigned long fn = kallsyms_lookup_name(csym);
		typedef unsigned long (*fn4_t)(unsigned long, unsigned long,
					       unsigned long, unsigned long);

		emit("csym %s -> %#lx args %#lx %#lx %#lx %#lx\n",
		     csym, fn, a0, a1, a2, a3);
		if (!fn) {
			emit("symbol not found\n");
			goto out;
		}
		ret = ((fn4_t)fn)(a0, a1, a2, a3);
		emit("ret = %#lx (%lu)\n", ret, ret);
		goto out;
	}

	if (!target) {
		emit("no target\n");
		goto out;
	}
	emit("dump %#lx .. %#lx\n", target, target + len);
	hexdump(target, len);

out:
	pbuf[plen] = '\0';
	put_file("/data/local/tmp/probeG.out", pbuf, plen);
}

module_init(probeg_init);
module_exit(probeg_exit);
MODULE_LICENSE("GPL");
