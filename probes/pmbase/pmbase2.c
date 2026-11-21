// Walk the kernel page tables to turn the ioremap'd PM block VA into a physical
// address, so a pre-kernel probe can touch the reset register directly.
//
// MDrv_SYS_ResetAeon does: strh 1, [PM_BASE + 0x201FCC]
// (PM_BASE = *(u64 *)0xffffff8009358000 + 72), and the same block holds the WDT
// registers at +0x6000, so one physical base explains both.
#include <linux/module.h>
#include <linux/mm.h>
#include <asm/pgtable.h>
#include <linux/kallsyms.h>

#define PMGLOBAL 0xffffff8009358000UL

static phys_addr_t va2pa(unsigned long va)
{
	struct mm_struct *imm = (struct mm_struct *)kallsyms_lookup_name("init_mm");
	pgd_t *pgd;

	if (!imm)
		return 0;
	pgd = pgd_offset(imm, va);
	pud_t *pud;
	pmd_t *pmd;

	if (pgd_none(*pgd) || pgd_bad(*pgd))
		return 0;
	pud = pud_offset(pgd, va);
	if (pud_none(*pud) || pud_bad(*pud))
		return 0;
	pmd = pmd_offset(pud, va);
	if (pmd_none(*pmd))
		return 0;
	if (pmd_sect(*pmd))
		return (phys_addr_t)__pfn_to_phys(pmd_pfn(*pmd)) + (va & ~PMD_MASK);
	if (pmd_bad(*pmd))
		return 0;
	{
		pte_t *pte = pte_offset_kernel(pmd, va);
		if (pte_none(*pte) || !pte_present(*pte))
			return 0;
		return (phys_addr_t)__pfn_to_phys(pte_pfn(*pte)) + (va & ~PAGE_MASK);
	}
}

static int __init pmbase2_init(void) { return 0; }

static void __exit pmbase2_exit(void)
{
	u64 pm = *(u64 *)(PMGLOBAL + 72);
	phys_addr_t pa = pm ? va2pa(pm) : 0;

	pr_info("pmbase2: pm=%#llx pa=%#llx reset_phys=%#llx wdt_phys=%#llx\n",
		pm, (u64)pa, (u64)pa + 0x201fccULL, (u64)pa + 0x6000ULL);
}

module_init(pmbase2_init);
module_exit(pmbase2_exit);
MODULE_LICENSE("GPL");
MODULE_DESCRIPTION("page-table walk for the MStar PM block base");
