// Arm the MStar watchdog through the vendor HAL so the SoC warm-resets on a
// schedule we control.
//
// Why: /dev/watchdog does not exist on this box, and `adb reboot` is a PM51
// standby (power cut) which destroys DRAM.  Without a warm reset, "read the
// record after the reset" cannot be tested at all.  mboot's own wdt_enable
// command arms the same HAL (channel 3) but only fires 2 times out of 4, and
// fires too early to be useful as a read window.
//
// The work is done in module_exit, like probeRW: insmod does nothing, rmmod
// performs the call, so a stale module cannot arm the watchdog by accident.
#include <linux/module.h>
#include <linux/kallsyms.h>

static int secs = 10;
module_param(secs, int, 0644);
MODULE_PARM_DESC(secs, "watchdog timeout in seconds");

typedef int (*hal_start_fn)(int ch, unsigned int timeout);
typedef int (*sys_enable_fn)(unsigned int timeout);

static int __init wdtarm_init(void)
{
	return 0;
}

static void __exit wdtarm_exit(void)
{
	hal_start_fn start = (hal_start_fn)kallsyms_lookup_name("HAL_WDT_Start");
	int rc;

	if (!start) {
		pr_err("wdtarm: HAL_WDT_Start not found\n");
		return;
	}
	pr_info("wdtarm: HAL_WDT_Start(3, %d)\n", secs);
	rc = start(3, (unsigned int)secs);
	pr_info("wdtarm: HAL_WDT_Start rc=%d\n", rc);
	if (!rc)
		return;

	{
		sys_enable_fn en = (sys_enable_fn)kallsyms_lookup_name("MDrv_SYS_WDTEnable");
		if (!en) {
			pr_err("wdtarm: MDrv_SYS_WDTEnable not found\n");
			return;
		}
		pr_info("wdtarm: fallback MDrv_SYS_WDTEnable(%d)\n", secs);
		rc = en((unsigned int)secs);
		pr_info("wdtarm: MDrv_SYS_WDTEnable rc=%d\n", rc);
	}
}

module_init(wdtarm_init);
module_exit(wdtarm_exit);
MODULE_LICENSE("GPL");
MODULE_DESCRIPTION("arm the MStar watchdog via the vendor HAL");
