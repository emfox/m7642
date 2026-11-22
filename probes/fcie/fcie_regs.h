/*
 * fcie_regs.h -- FCIE (MStar eMMC host) register map and the wait helpers.
 *
 * Shared by fcie_read.c (CMD17, verified on the device) and fcie_write.c
 * (CMD24, offline until it gets a run).  Everything here is measured or taken
 * from the vendor disassembly; see probes/fcie/regs-reference.txt.
 *
 * Freestanding: no libc, no kernel headers.  The callers compile with
 * -mgeneral-regs-only -ffreestanding and run at code1 with the MMU off.
 */
#ifndef FCIE_REGS_H
#define FCIE_REGS_H

typedef unsigned char      u8;
typedef unsigned short     u16;
typedef unsigned int       u32;
typedef unsigned long long u64;

/* ---- registers (16-bit, at base + (idx << 2)) ------------------------- */
#define R_EVENT          0x00   /* MIE_EVENT,      W1C, bit0 DMA_END, bit1 CMD_END, bit2 ERR_STS */
#define R_INT_EN         0x01   /* MIE_INT_EN; probe leaves interrupts masked        */
#define R_MMA_PRI        0x02   /* MMA_PRI_REG; bits[3:2] = MIU select, 0 = MIU0     */
#define R_DMA_ADDR_L     0x03   /* MIU_DMA_ADDR_15_0                                 */
#define R_DMA_ADDR_H     0x04   /* MIU_DMA_ADDR_31_16                                */
#define R_DMA_LEN_L      0x05   /* MIU_DMA_LEN_15_0                                  */
#define R_DMA_LEN_H      0x06   /* MIU_DMA_LEN_31_16                                 */
#define R_FUNC_CTL       0x07   /* MIE_FUNC_CTL; bit1 SD_EN, bit12 EMMC_ACTIVE       */
#define R_JOB_BL_CNT     0x08   /* number of blocks per job                          */
#define R_BLK_SIZE       0x09   /* block size in bytes (512)                         */
#define R_CMD_RSP_SIZE   0x0A   /* bits[5:0] response bytes, bits[13:8] command bytes*/
#define R_SD_MODE        0x0B   /* bit0 CLK_EN, bits[2:1] width, bit4 CIFD/R2N      */
#define R_SD_CTRL        0x0C   /* bit1 RSP_EN bit2 CMD_EN bit3 DAT_EN bit4 DAT_DIR_W(!) bit5 ADMA_EN bit6 START bit9 ERR_DET_ON */
#define R_SD_STATUS      0x0D   /* bits[5:0] error flags (W1C), bit6 card busy       */
#define R_DMA_ADDR_47_32 0x29   /* MIU_DMA_ADDR_47_32                                */
#define R_RST            0x3F   /* bit0 SOFT_RST_n (active low); never touched here  */
#define R_NC_FUN_CTL     0x63   /* bit0 nc_en: FCIE owned by NAND path if set        */
#define R_CMDFIFO(n)     (0x20 + (n))  /* 9 x 16-bit command/response FIFO            */

/* ---- event / status bits ---------------------------------------------- */
#define EV_DMA_END   0x0001
#define EV_CMD_END   0x0002
#define EV_ERR_STS   0x0004
#define EV_ALL_CARD  0x003F     /* DMA_END|CMD_END|ERR_STS|SDIO|BUSY_END|R2N */

#define ST_ERR_MASK  0x003F     /* BIT_SD_FCIE_ERR_FLAGS = BIT6-1, excludes bit6 busy */
#define ST_BUSY      0x0040     /* BIT_SD_CARD_BUSY (DAT0 low)                        */

#define CTL_READ     0x020E     /* ERR_DET_ON|DAT_EN|CMD_EN|RSP_EN                    */
#define CTL_START    0x0040     /* BIT_JOB_START                                      */
/* CMD24 is a TWO-STAGE job (vendor: eMMC_hal_v5.c:3475 / :3572).  Writing one
 * 0x020E-style value with DAT_EN set is not something the vendor ever does. */
#define CTL_WR_CMD   0x0006     /* command stage: CMD_EN|RSP_EN                       */
#define CTL_WR_DAT   0x0218     /* data stage: DAT_EN|DAT_DIR_W|ERR_DET_ON            */

#define FUNC_EMMC_ACTIVE 0x1000
#define FUNC_SD_EN       0x0002

#define CMD17        17
#define CMD24        24

/* ---- return codes ----------------------------------------------------- */
#define E_DEST       0xE1       /* dst_pa not in the MIU0 window                      */
#define E_NC         0xE2       /* FCIE owned by NAND (NC_FUN_CTL.bit0)               */
#define E_D0         0xE3       /* DAT0 never went high                               */
#define E_CMD_TMO    0xE4       /* no CMD_END                                         */
#define E_CMD_STS    0xE5       /* status error after CMD_END                         */
#define E_DMA_TMO    0xE6       /* no DMA_END                                         */
#define E_DMA_STS    0xE7       /* status error after DMA_END                         */
#define E_R1         0xE8       /* card status reports an error / wrong state         */
#define E_EV_CLR     0xE9       /* latched events did not clear within 1 s            */
#define E_NOT_EMPTY  0xEA       /* target block is not uniformly 0x00/0xFF (write probe) */
#define E_VERIFY     0xEB       /* read-back did not match what we wrote              */

/* Every wait is bounded twice: by CNTPCT and by an iteration cap, so a
 * stopped counter cannot turn a wait into a silent hang. */
#define SPIN_CAP     2000000000ULL

/* R1 card-status error bits: 31..19 (out-of-range, misalign, len, erase,
 * WP, locked, lock/unlock, com crc, illegal cmd, ecc, cc, error), 16
 * (csd overwrite), 15 (wp erase skip), 7 (switch error).  Bits 12:9 are
 * CURRENT_STATE and bit 8 is READY_FOR_DATA -- not errors. */
#define R1_ERRORS    0xFFF98080u

/* ---- MMIO ------------------------------------------------------------- */
static inline u16 frd(u64 base, unsigned idx)
{
	return *(volatile u16 *)(base + ((u64)idx << 2));
}

static inline void fwr(u64 base, unsigned idx, u16 v)
{
	*(volatile u16 *)(base + ((u64)idx << 2)) = v;
}

/* ---- time base (bounded, see SPIN_CAP) -------------------------------- */
static inline u64 ticks(void)
{
	u64 v;
	__asm__ volatile("mrs %0, cntpct_el0" : "=r"(v));
	return v;
}

static inline u64 tick_hz(void)
{
	u64 v;
	__asm__ volatile("mrs %0, cntfrq_el0" : "=r"(v));
	return v ? v : 12000000ULL;   /* measured 12 MHz on this SoC */
}

static inline int wait_mask(u64 base, unsigned idx, u16 mask, u64 us)
{
	u64 deadline = ticks() + (tick_hz() / 1000000ULL) * us;
	u64 spin = 0;

	while (!(frd(base, idx) & mask)) {
		if (ticks() > deadline || ++spin > SPIN_CAP)
			return E_D0;    /* caller maps to its own code */
	}
	return 0;
}

/* ---- entry points ----------------------------------------------------- */
int fcie_read_block(u64 fcie_base, u32 lba, u64 dst_pa, u64 *diag);
int fcie_write_block(u64 fcie_base, u32 lba, u64 src_pa, u64 *diag);
int fcie_write_probe(u64 fcie_base, u32 lba, u64 buf_pa, u64 *diag);

#endif /* FCIE_REGS_H */
