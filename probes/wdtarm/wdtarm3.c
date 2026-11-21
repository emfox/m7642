// Arm the MStar watchdog through the vendor's own high-level API.
//
// The register pokes alone did not reset the box: MDrv_WDT_SetTimer() bails out
// unless a global "initialised" flag (*(u64*)0xffffff800232d5c0 + 0x60) is set,
// and that flag is what MDrv_WDT_Init() is supposed to raise.  So call Init
// first, then SetTimer, using kallsyms_lookup_name so no addresses are baked in.
#include <linux/module.h>
#include <linux/kallsyms.h>

static int ch = 0;
module_param(ch, int, 0644);
MODULE_PARM_DESC(ch, "watchdog channel / index");
static int secs = 10;
module_param(secs, int, 0644);
MODULE_PARM_DESC(secs, "timeout seconds");

typedef int (*fn1)(int);
typedef int (*fn2)(int, int);

static int __init wdtarm3_init(void)
{
	return 0;
}

static void __exit wdtarm3_exit(void)
{
	fn1 init = (fn1)kallsyms_lookup_name("MDrv_WDT_Init");
	fn2 set = (fn2)kallsyms_lookup_name("MDrv_WDT_SetTimer");
	volatile u8 *flag;
	u64 base = *(u64 *)0xffffff800232d5c0UL;
	int r1 = -1, r2 = -1;

	pr_info("wdtarm3: init=%px set=%px flagbase=%#llx\n", init, set, base);
	if (base)
		pr_info("wdtarm3: flag[+0x60]=%u\n", *(volatile u8 *)(base + 0x60));
	if (init)
		r1 = init(ch);
	flag = base ? (volatile u8 *)(base + 0x60) : NULL;
	if (flag)
		pr_info("wdtarm3: after init flag=%u\n", *flag);
	if (set)
		r2 = set(ch, secs);
	pr_info("wdtarm3: ch=%d secs=%d init rc=%d set rc=%d\n", ch, secs, r1, r2);
}

module_init(wdtarm3_init);
module_exit(wdtarm3_exit);
MODULE_LICENSE("GPL");
MODULE_DESCRIPTION("arm the MStar watchdog via MDrv_WDT_Init + SetTimer");
