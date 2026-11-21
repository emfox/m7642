// Hang the kernel without panicking, to test whether the ~5 s reset seen after
// a panic is a liveness deadman rather than a panic-only path.
#include <linux/module.h>
#include <linux/kernel.h>

static int __init hangmod_init(void) { return 0; }

static void __exit hangmod_exit(void)
{
	pr_info("hangmod: spinning forever, no panic\n");
	for (;;)
		barrier();
}

module_init(hangmod_init);
module_exit(hangmod_exit);
MODULE_LICENSE("GPL");
MODULE_DESCRIPTION("hang the kernel without panicking");
