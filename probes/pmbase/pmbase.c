// Print the MStar PM register-block pointer and its physical address.
//
// MDrv_SYS_ResetAeon (dumped at 0xffffff8008896180) does, after loading
// *(u64 *)0xffffff8009358000 + 72 into x1:
//     add x1, x1, #0x201000 ; strh 1, [x1, #0xFCC]
// so the reset trigger is a halfword 1 at PM_BASE + 0x201FCC.  To use it from a
// pre-kernel probe we need the physical address, which is what this prints.
#include <linux/module.h>
#include <linux/io.h>
#include <linux/mm.h>

#define PMGLOBAL 0xffffff8009358000UL

static int __init pmbase_init(void) { return 0; }

static void __exit pmbase_exit(void)
{
	u64 pm = *(u64 *)(PMGLOBAL + 72);

	pr_info("pmbase: pm=%#llx phys=%#llx reset_reg_phys=%#llx\n",
		pm, pm ? (u64)__pa(pm) : 0ULL,
		pm ? (u64)__pa(pm) + 0x201fccULL : 0ULL);
	if (pm) {
		/* read the two candidates back so a bogus pointer shows up */
		pr_info("pmbase: [pm+0x201fcc]=%#x [pm+0x201fca]=%#x\n",
			readw((void __iomem *)(pm + 0x201fcc)),
			readw((void __iomem *)(pm + 0x201fca)));
	}
}

module_init(pmbase_init);
module_exit(pmbase_exit);
MODULE_LICENSE("GPL");
MODULE_DESCRIPTION("print the MStar PM block address");
