// Snapshot the WDT register block around MDrv_WDT_Init + MDrv_WDT_SetTimer so the
// exact register sequence the vendor API uses becomes visible.  Same idea as
// wdtdump: work in module_exit, write a file, let the box reset afterwards.
#include <linux/module.h>
#include <linux/kallsyms.h>
#include <linux/fs.h>
#include <linux/io.h>
#include <linux/slab.h>

typedef int (*fn1)(int);
typedef int (*fn2)(int, int);

static int secs = 5;
module_param(secs, int, 0644);

#define FLAGPTR 0xffffff800232d5c0UL
#define BASEPTR 0xffffff800232d628UL

static int __init wdtarm4_init(void) { return 0; }

static void snap(u8 *dst, void __iomem *base)
{
	int i;
	for (i = 0; i < 64; i++)
		dst[i] = readb(base + 0x6000 + i);
}

static void __exit wdtarm4_exit(void)
{
	u64 vb = *(u64 *)BASEPTR;
	void __iomem *base = (void __iomem *)vb;
	u8 *buf;
	fn1 init = (fn1)kallsyms_lookup_name("MDrv_WDT_Init");
	fn2 set = (fn2)kallsyms_lookup_name("MDrv_WDT_SetTimer");

	buf = kzalloc(256, GFP_KERNEL);
	if (!buf)
		return;
	pr_info("wdtarm4: base=%#llx init=%px set=%px flag=%u\n", vb, init, set,
		*(volatile u8 *)(*(u64 *)FLAGPTR + 0x60));
	snap(buf + 0, base);
	if (init) {
		int r = init(0);
		pr_info("wdtarm4: init(0) rc=%d flag=%u\n", r,
			*(volatile u8 *)(*(u64 *)FLAGPTR + 0x60));
	}
	snap(buf + 64, base);
	if (set) {
		int r = init ? set(0, secs) : -1;
		pr_info("wdtarm4: set(0,%d) rc=%d\n", secs, r);
	}
	snap(buf + 128, base);
	{
		int k, j;
		char line[3 * 64 + 1];
		const char *tag[3] = { "A", "B", "C" };
		for (k = 0; k < 3; k++) {
			for (j = 0; j < 64; j++)
				snprintf(line + j * 3, 4, "%02x ",
					 buf[k * 64 + j]);
			line[191] = 0;
			pr_info("wdtarm4: %s %s\n", tag[k], line);
		}
	}
	kfree(buf);
	pr_info("wdtarm4: snapshot printed\n");
}

module_init(wdtarm4_init);
module_exit(wdtarm4_exit);
MODULE_LICENSE("GPL");
MODULE_DESCRIPTION("snapshot WDT registers around the vendor init/set API");
