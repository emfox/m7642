// Call the vendor's machine_restart from a module and see what it does:
// a warm reset (DRAM kept, the box reboots by itself) or a PM51 standby
// (power cut, needs a key press).  This decides whether "checkpoint + reset"
// can be done from an arbitrary context at all.
#include <linux/module.h>
#include <linux/kallsyms.h>

typedef void (*mr_fn)(const char *);

static int __init rstcall_init(void) { return 0; }

static void __exit rstcall_exit(void)
{
	mr_fn mr = (mr_fn)kallsyms_lookup_name("machine_restart");

	pr_info("rstcall: machine_restart=%px, calling with \"m7642test\"\n", mr);
	if (mr)
		mr("m7642test");
	pr_info("rstcall: machine_restart RETURNED -- no reset happened\n");
}

module_init(rstcall_init);
module_exit(rstcall_exit);
MODULE_LICENSE("GPL");
MODULE_DESCRIPTION("call machine_restart to classify the reset");
