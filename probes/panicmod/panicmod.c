// Deliberate panic with nothing else armed, to see whether the panic path is a
// warm reset (DRAM kept, box comes back by itself) or a standby.
#include <linux/module.h>

static int __init panicmod_init(void) { return 0; }

static void __exit panicmod_exit(void)
{
	pr_info("panicmod: deliberate panic now, no WDT armed\n");
	panic("m7642 panic test");
}

module_init(panicmod_init);
module_exit(panicmod_exit);
MODULE_LICENSE("GPL");
MODULE_DESCRIPTION("deliberate panic to classify the reset path");
