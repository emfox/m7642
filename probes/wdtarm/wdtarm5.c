// Arm the MStar watchdog through the vendor API, with no diagnostics that can
// fault: MDrv_WDT_Init(ch) then MDrv_WDT_SetTimer(ch, secs).  If the box resets
// and pstore shows no panic, the watchdog itself did it.
#include <linux/module.h>
#include <linux/kallsyms.h>

typedef int (*fn1)(int);
typedef int (*fn2)(int, int);

static int ch = 0;
module_param(ch, int, 0644);
static int secs = 10;
module_param(secs, int, 0644);

static int __init wdtarm5_init(void) { return 0; }

static void __exit wdtarm5_exit(void)
{
	fn1 init = (fn1)kallsyms_lookup_name("MDrv_WDT_Init");
	fn2 set = (fn2)kallsyms_lookup_name("MDrv_WDT_SetTimer");
	int r1 = -1, r2 = -1;

	if (init)
		r1 = init(ch);
	if (set)
		r2 = set(ch, secs);
	pr_info("wdtarm5: ch=%d secs=%d init=%d set=%d (no diag derefs)\n",
		ch, secs, r1, r2);
}

module_init(wdtarm5_init);
module_exit(wdtarm5_exit);
MODULE_LICENSE("GPL");
MODULE_DESCRIPTION("arm the MStar watchdog via MDrv_WDT_Init + SetTimer");
