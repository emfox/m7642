// Arm the MStar watchdog through its registers, bypassing HAL_WDT_Start.
//
// Disassembly of the vendor HAL (utpa2k.ko) shows:
//   HAL_WDT_Start()            -> `mov w0,#1; ret`, i.e. an unimplemented stub
//                                 (that is why the mboot-style call returned 1)
//   HAL_WDT_SetTimer(secs)     -> ticks = secs * 12_000_000; then
//                                 strh (ticks >> 16) to [base + 0x600c]
//   second variant             -> strb 1 to [base + 0x6000]
//   base                       -> *(void **)WDT_BASE_PTR, set by the vendor init
//
// So: write the timeout halfword, then the enable byte, and never kick it.
#include <linux/module.h>
#include <linux/io.h>
#include <linux/delay.h>

#define WDT_BASE_PTR 0xffffff800232d628UL

static int secs = 10;
module_param(secs, int, 0644);
MODULE_PARM_DESC(secs, "watchdog timeout in seconds");

static int __init wdtarm2_init(void)
{
	return 0;
}

static void __exit wdtarm2_exit(void)
{
	void __iomem *base = *(void __iomem **)WDT_BASE_PTR;
	u32 ticks;

	pr_info("wdtarm2: base=%px\n", base);
	if (!base) {
		pr_err("wdtarm2: WDT base pointer is NULL (vendor init never ran)\n");
		return;
	}
	ticks = (u32)((u64)secs * 12000000ULL);
	pr_info("wdtarm2: secs=%d ticks=%u -> [%px+0x600c]\n", secs, ticks, base);
	writew((u16)(ticks >> 16), base + 0x600c);
	wmb();
	writeb(1, base + 0x6000);
	wmb();
	pr_info("wdtarm2: armed, not kicking\n");
}

module_init(wdtarm2_init);
module_exit(wdtarm2_exit);
MODULE_LICENSE("GPL");
MODULE_DESCRIPTION("arm the MStar watchdog via its registers");
