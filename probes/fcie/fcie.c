// fcie: read-only register dump of the MStar FCIE eMMC host controller (M7642).
//
// Why this module exists
// ----------------------
// The vendor eMMC driver is built into the stock 4.9 kernel, so we cannot
// ioremap() the FCIE block ourselves without racing the driver.  This module
// therefore only *reads* registers, with 16-bit loads at 4-byte stride -- the
// exact access width and order the vendor driver itself uses (REG_FCIE_U16).
// It issues no command, writes no MMIO, and never touches the eMMC.
//
// Base-address derivation (see confirmed-facts.md §32):
//   mstar_pm_base = [0xffffff8009358048]     = 0xffffff800a000000
//                 = ioremap(0x1F000000, 0xA00000)   (init/main.c:547)
//   FCIE0         = mstar_pm_base + 0x222600 = 0xffffff800a222600
//   EMMC_PLL      = mstar_pm_base + 0x247E00 = 0xffffff800a247e00
// Verified 2026-11-22 against 32-bit physical reads of 0x1F222640 / 0x1F22262C
// / 0x1F222634 / 0x1F247E68 through mioreg: all four matched.
//
// Build (hand-rolled module link, see ~/Debian/m7642-build/scripts/build-probe.sh):
//   ~/Debian/m7642-build/scripts/build-probe.sh fcie
// Run:
//   busybox rmmod fcie 2>/dev/null
//   busybox insmod /data/local/tmp/fcie.ko
//   rmmod fcie                      # work happens in module_exit on this ROM
//   cat /data/local/tmp/fcie.out
#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/fs.h>
#include <linux/string.h>
#include <linux/err.h>

#define FCIE_BASE   0xffffff800a222600UL
#define EMMC_PLL    0xffffff800a247e00UL

#define BUFSZ 16384

static char pbuf[BUFSZ];
static int  plen;

static void emit(const char *fmt, ...)
{
	va_list ap;
	int n;

	if (plen >= BUFSZ - 1)
		return;
	va_start(ap, fmt);
	n = vscnprintf(pbuf + plen, BUFSZ - plen - 1, fmt, ap);
	va_end(ap);
	plen += n;
}

static void put_file(const char *path, const char *data, int l)
{
	struct file *f;
	loff_t pos = 0;

	f = filp_open(path, O_WRONLY | O_CREAT | O_TRUNC, 0644);
	if (IS_ERR(f))
		return;
	kernel_write(f, data, (size_t)l, pos);
	filp_close(f, NULL);
}

/* One 16-bit register.  Index is the vendor's 16-bit register number:
 * byte address = base + (idx << 2).  Do NOT turn this into a byte loop and
 * do not read the hole indices 0x19..0x28 / 0x2A..0x33 / 0x3A..0x3E /
 * 0x40..0x62: those are unimplemented and an access is an external abort. */
static u16 frd(unsigned long base, unsigned idx)
{
	return *(volatile u16 *)(base + ((unsigned long)idx << 2));
}

struct regname { unsigned idx; const char *name; };

static const struct regname fcie_regs[] = {
	{ 0x00, "MIE_EVENT" },
	{ 0x01, "MIE_INT_EN" },
	{ 0x02, "MMA_PRI_REG" },
	{ 0x03, "MIU_DMA_ADDR_15_0" },
	{ 0x04, "MIU_DMA_ADDR_31_16" },
	{ 0x05, "MIU_DMA_LEN_15_0" },
	{ 0x06, "MIU_DMA_LEN_31_16" },
	{ 0x07, "MIE_FUNC_CTL" },
	{ 0x08, "JOB_BL_CNT" },
	{ 0x09, "BLK_SIZE" },
	{ 0x0A, "CMD_RSP_SIZE" },
	{ 0x0B, "SD_MODE" },
	{ 0x0C, "SD_CTRL" },
	{ 0x0D, "SD_STATUS" },
	{ 0x0E, "BOOT_CONFIG" },
	{ 0x0F, "DDR_MODE" },
	{ 0x10, "RESERVED_FOR_SW" },
	{ 0x11, "SDIO_MOD" },
	{ 0x12, "RSP_SHIFT_CNT" },
	{ 0x13, "RX_SHIFT_CNT" },
	{ 0x14, "ZDEC_CTL0" },
	{ 0x15, "TEST_MODE" },
	{ 0x16, "MMA_BANK_SIZE" },
	{ 0x17, "WR_SBIT_TIMER" },
	{ 0x18, "RD_SBIT_TIMER" },
	{ 0x29, "MIU_DMA_ADDR_47_32" },
	{ 0x34, "PWR_RD_MASK" },
	{ 0x35, "PWR_SAVE_CTL" },
	{ 0x36, "BIST" },
	{ 0x37, "BOOT" },
	{ 0x38, "EMMC_DEBUG_BUS0" },
	{ 0x39, "EMMC_DEBUG_BUS1" },
	{ 0x3F, "RST" },
	{ 0x63, "NC_FUN_CTL" },
};

static int __init fcie_init(void)
{
	return 0;
}

static void __exit fcie_exit(void)
{
	unsigned i;

	emit("fcie dump: FCIE0 VA %#lx (PA 0x1f222600), EMMC_PLL VA %#lx\n",
	     FCIE_BASE, EMMC_PLL);
	emit("idx  addr                name                 value\n");

	for (i = 0; i < ARRAY_SIZE(fcie_regs); i++) {
		u16 v = frd(FCIE_BASE, fcie_regs[i].idx);
		emit("%02x   %#018lx  %-18s %04x\n",
		     fcie_regs[i].idx,
		     FCIE_BASE + ((unsigned long)fcie_regs[i].idx << 2),
		     fcie_regs[i].name, v);
	}

	/* The two EMMC_PLL registers the driver touches in eMMC_PlatformInit. */
	emit("pll  0x1a  %#018lx  %-18s %04x\n",
	     EMMC_PLL + 0x1a * 4, "reg_emmc_test", frd(EMMC_PLL, 0x1a));
	emit("pll  0x45  %#018lx  %-18s %04x\n",
	     EMMC_PLL + 0x45 * 4, "reg_emmcpll_0x45", frd(EMMC_PLL, 0x45));
	emit("done\n");

	put_file("/data/local/tmp/fcie.out", pbuf, plen);
}

module_init(fcie_init);
module_exit(fcie_exit);
MODULE_LICENSE("GPL");
MODULE_DESCRIPTION("read-only FCIE register dump (no eMMC access)");
