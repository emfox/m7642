// Dump the machine code of a kernel symbol to /data/local/tmp/wdtdump.bin.
//
// The vendor's WDT HAL (utpa2k.ko) is stripped, so the only way to learn what
// MDrv_SYS_WDTEnable / HAL_WDT_Start actually touch is to look at the bytes the
// running kernel executes.  kallsyms_lookup_name finds them even though they are
// not plain exported symbols.
//
// insmod wdtdump.ko sym=MDrv_SYS_WDTEnable len=512
// rmmod wdtdump            # module_exit does the work, like probeRW
#include <linux/module.h>
#include <linux/kallsyms.h>
#include <linux/fs.h>
#include <linux/uaccess.h>

static char *sym = "MDrv_SYS_WDTEnable";
module_param(sym, charp, 0644);
MODULE_PARM_DESC(sym, "symbol name to dump");
static int len = 512;
module_param(len, int, 0644);
MODULE_PARM_DESC(len, "bytes to dump");

static int __init wdtdump_init(void)
{
	return 0;
}

static void __exit wdtdump_exit(void)
{
	unsigned long addr = kallsyms_lookup_name(sym);
	struct file *f;
	loff_t pos = 0;
	int n;

	pr_info("wdtdump: %s at %#lx len %d\n", sym, addr, len);
	if (!addr)
		return;
	if (len <= 0 || len > 8192)
		len = 512;

	f = filp_open("/data/local/tmp/wdtdump.bin",
		      O_WRONLY | O_CREAT | O_TRUNC, 0644);
	if (IS_ERR(f)) {
		pr_err("wdtdump: open failed %ld\n", PTR_ERR(f));
		return;
	}
	n = kernel_write(f, (const void *)addr, len, pos);
	pr_info("wdtdump: wrote %d bytes at %#lx\n", n, addr);
	filp_close(f, NULL);
}

module_init(wdtdump_init);
module_exit(wdtdump_exit);
MODULE_LICENSE("GPL");
MODULE_DESCRIPTION("dump a kernel symbol's machine code");
