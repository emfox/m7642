// probeS: parameterised GOP snapshot, for building and diffing a golden state.
// Params (all optional):
//   idxmax=<n>  bankmax=<n>  offmax=<n>   scan bounds (default 3 / 16 / 256)
//   out=<path>                            output file
// Output lines: "<idx> <bank> <off> <value-hex>" for every non-zero register.
#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/fs.h>
#include <linux/string.h>
#include <linux/kallsyms.h>
#include <linux/err.h>

#define BUFSZ 524288

static unsigned int idxmax = 3;
static unsigned int bankmax = 16;
static unsigned int offmax = 256;
static char *out = "/data/local/tmp/gop.snap";

module_param(idxmax, uint, 0644);
module_param(bankmax, uint, 0644);
module_param(offmax, uint, 0644);
module_param(out, charp, 0644);

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

static int __init probes_init(void)
{
	return 0;
}

static void __exit probes_exit(void)
{
	typedef void (*read_gop_t)(u8, u16, u16, u16 *);
	unsigned long fn = kallsyms_lookup_name("MHal_GFLIP_ReadGopReg");
	read_gop_t rd = (read_gop_t)fn;
	unsigned int idx, bank, off;
	int total = 0;

	if (!fn) {
		emit("# MHal_GFLIP_ReadGopReg not found\n");
		goto out;
	}
	emit("# gop snapshot idxmax=%u bankmax=%u offmax=%u accessor=%#lx\n",
	     idxmax, bankmax, offmax, fn);

	for (idx = 0; idx < idxmax; idx++) {
		for (bank = 0; bank < bankmax; bank++) {
			for (off = 0; off < offmax; off++) {
				u16 v = 0;

				rd((u8)idx, (u16)bank, (u16)off, &v);
				if (v) {
					emit("%u %u %u %04x\n", idx, bank, off, v);
					total++;
				}
			}
		}
	}
	emit("# total %d\n", total);

out:
	pbuf[plen] = '\0';
	put_file(out, pbuf, plen);
}

module_init(probes_init);
module_exit(probes_exit);
MODULE_LICENSE("GPL");
