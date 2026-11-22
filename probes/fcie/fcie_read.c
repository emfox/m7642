/*
 * fcie_read.c -- read one 512-byte block from eMMC through the MStar FCIE
 *                controller.  READ ONLY: no CMD24/CMD25/CMD38, no register
 *                write outside the per-command setup below.
 *
 * Target: M7642 (MT9652 family), vendor kernel 4.9.118+ / mboot handoff state.
 * Freestanding: no libc, no globals, no string literals, no stack protector.
 * Every address is a parameter, so the object can be copied to any physical
 * page and executed with MMU and caches off (which is how the checkpoint
 * stubs run).  One block costs 512 bytes of DMA into dst_pa.
 *
 * Register model (all offsets are the vendor's 16-bit register index, byte
 * address = base + (idx << 2); see confirmed-facts.md section 32):
 *
 *   FCIE0 base = 0x1F222600 physical = 0xffffff800a222600 in the vendor kernel
 *     = mstar_pm_base + 0x222600, mstar_pm_base = ioremap(0x1F000000, 0xA00000)
 *
 * Build:
 *   aarch64-buildroot-linux-gnu-gcc -c -O2 -march=armv8-a -mgeneral-regs-only \
 *       -ffreestanding -fno-builtin -fno-stack-protector -fno-pic \
 *       -fno-asynchronous-unwind-tables -o fcie_read.o fcie_read.c
 *
 * Call:
 *   int fcie_read_block(0x1F222600UL, lba, 0x23080000UL, diag);
 *   -> data at physical 0x23080000 (MIU address 0x03080000)
 *
 * The sequence below is a transcription of the *running* vendor binary, not of
 * the source tree: eMMC_CMD17_MIU @ 0xffffff8008c993fc,
 * eMMC_FCIE_SendCmd @ 0xffffff8008c95c00, eMMC_translate_DMA_address_Ex @
 * 0xffffff8008ca2254, verified instruction by instruction on 2026-11-22.
 */

typedef unsigned char      u8;
typedef unsigned short     u16;
typedef unsigned int       u32;
typedef unsigned long long u64;

/* ---- FCIE0 register indices ------------------------------------------- */
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
#define R_SD_CTRL        0x0C   /* bit1 RSP_EN, bit2 CMD_EN, bit3 DAT_EN, bit6 START */
#define R_SD_STATUS      0x0D   /* bits[5:0] error flags (W1C), bit6 card busy       */
#define R_DMA_ADDR_47_32 0x29   /* MIU_DMA_ADDR_47_32                                */
#define R_RST            0x3F   /* bit0 SOFT_RST_n (active low); never touched here  */
#define R_NC_FUN_CTL     0x63   /* bit0 nc_en: FCIE owned by NAND path if set        */
#define R_CMDFIFO(n)     (0x20 + (n))  /* 9 x 16-bit command/response FIFO            */

/* Diagnostic stage: 0 = full CMD17, 1 = register setup only (no command at
 * all -- no SD_MODE/FIFO write, no SD_CTRL, no DMA job).  Stage 1 tells a
 * hanging register write apart from a hanging command/DMA. */
#ifndef FCIE_STAGE
#define FCIE_STAGE 0
#endif

/* ---- bits ------------------------------------------------------------- */
#define EV_DMA_END   0x0001
#define EV_CMD_END   0x0002
#define EV_ERR_STS   0x0004
#define EV_ALL_CARD  0x003F     /* DMA_END|CMD_END|ERR_STS|SDIO|BUSY_END|R2N */

#define ST_ERR_MASK  0x003F     /* BIT_SD_FCIE_ERR_FLAGS = BIT6-1, excludes bit6 busy */
#define ST_BUSY      0x0040     /* BIT_SD_CARD_BUSY (DAT0 low)                        */

#define CTL_READ     0x020E     /* ERR_DET_ON|DAT_EN|CMD_EN|RSP_EN                    */
#define CTL_START    0x0040     /* BIT_JOB_START                                      */

#define FUNC_EMMC_ACTIVE 0x1000
#define FUNC_SD_EN       0x0002

#define CMD17        17

/* error codes: small positive values, 0 = success */
#define E_DEST       0xE1       /* dst_pa not in the MIU0 window                     */
#define E_NC         0xE2       /* FCIE owned by NAND (NC_FUN_CTL.bit0)              */
#define E_D0         0xE3       /* DAT0 never went high                              */
#define E_CMD_TMO    0xE4       /* no CMD_END                                        */
#define E_CMD_STS    0xE5       /* status error after CMD_END                        */
#define E_DMA_TMO    0xE6       /* no DMA_END                                        */
#define E_DMA_STS    0xE7       /* status error after DMA_END                        */
#define E_R1         0xE8       /* card status reports an error / wrong state        */
#define E_EV_CLR     0xE9       /* latched events did not clear within 1 s */

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

/* ---- time ------------------------------------------------------------- */
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
	return v ? v : 12000000ULL;     /* M7642 timer is 12 MHz if CNTFRQ is 0 */
}

/* wait until (r16(idx) & mask) != 0, or timeout.  returns 0 on success. */
static int wait_mask(u64 base, unsigned idx, u16 mask, u64 us)
{
	u64 deadline = ticks() + (tick_hz() / 1000000ULL) * us;
	u64 spin = 0;

	while (!(frd(base, idx) & mask)) {
		if (ticks() > deadline || ++spin > SPIN_CAP)
			return E_D0;    /* caller maps to its own code */
	}
	return 0;
}

/* ---- the block read --------------------------------------------------- */
/*
 * fcie_read_block(fcie_base, lba, dst_pa, diag)
 *
 *   fcie_base : 0x1F222600 when running with MMU off
 *   lba       : 512-byte block address (card is in sector mode: the vendor
 *               driver's g_eMMCDrv.u8_IfSectorMode was 1 when measured, so the
 *               argument is shifted by 0, not by 9)
 *   dst_pa    : physical destination, must be in MIU0 (>= 0x20000000 and
 *               < 0x1_0000_0000)
 *   diag      : optional u64[4]; gets {r1, sd_status, event, miu_addr}
 *
 * returns 0 on success, or one of E_* above.
 */
int fcie_read_block(u64 fcie_base, u32 lba, u64 dst_pa, u64 *diag)
{
	u64 miu;
	u16 mode, ev = 0, st = 0, w0, w1, w2;
	u32 r1;
	int rc;

	if (diag) {
		diag[0] = 0; diag[1] = 0; diag[2] = 0; diag[3] = 0;
	}
	if (dst_pa < 0x20000000ULL || dst_pa >= 0x100000000ULL)
		return E_DEST;
	miu = dst_pa - 0x20000000ULL;          /* MSTAR_MIU0_BUS_BASE */

	/* Never touch the controller if the NAND path owns it (mboot leaves 0). */
	if (frd(fcie_base, R_NC_FUN_CTL) & 1)
		return E_NC;

	/* Take the block out of the driver's "idle" state: the driver clears
	 * SD_MODE.bit0 (clock output) at the end of every command. */
	fwr(fcie_base, R_FUNC_CTL, frd(fcie_base, R_FUNC_CTL) |
				   FUNC_EMMC_ACTIVE | FUNC_SD_EN);
	mode = frd(fcie_base, R_SD_MODE) | 0x0001;   /* inherit width/DDR state */
	fwr(fcie_base, R_SD_MODE, mode);

	/* 1. DAT0 must be high before a command (driver: eMMC_FCIE_WaitD0High). */
	{
		u64 deadline = ticks() + tick_hz() * 10ULL;
		u64 spin = 0;
		while (frd(fcie_base, R_SD_STATUS) & ST_BUSY)
			if (ticks() > deadline || ++spin > SPIN_CAP) return E_D0;
	}

	/* 2. clear latched events and error flags (driver: ClearEvents).
	 *    Bounded: a stuck bit must not turn this into a silent hang. */
	{
		u64 deadline = ticks() + tick_hz();
		u64 spin = 0;
		for (;;) {
			fwr(fcie_base, R_EVENT, EV_ALL_CARD);
			if (!(frd(fcie_base, R_EVENT) & EV_ALL_CARD))
				break;
			if (ticks() > deadline || ++spin > SPIN_CAP)
				return E_EV_CLR;
		}
	}
	fwr(fcie_base, R_EVENT, 0x0000);
	fwr(fcie_base, R_SD_STATUS, ST_ERR_MASK);    /* W1C */

	/* 3. one block, 512 bytes, MIU0. */
	fwr(fcie_base, R_JOB_BL_CNT, 1);
	fwr(fcie_base, R_BLK_SIZE, 512);
	fwr(fcie_base, R_DMA_LEN_L, 512);
	fwr(fcie_base, R_DMA_LEN_H, 0);
	fwr(fcie_base, R_MMA_PRI, frd(fcie_base, R_MMA_PRI) & ~0x000C); /* MIU0 */
	fwr(fcie_base, R_DMA_ADDR_L, (u16)(miu & 0xFFFF));
	fwr(fcie_base, R_DMA_ADDR_H, (u16)((miu >> 16) & 0xFFFF));
	fwr(fcie_base, R_DMA_ADDR_47_32, (u16)(miu >> 32));

	/* 4. R1 response, 5 bytes; command size field stays 5 from mboot. */
	fwr(fcie_base, R_CMD_RSP_SIZE,
	    (frd(fcie_base, R_CMD_RSP_SIZE) & ~0x003F) | 5);

#if FCIE_STAGE == 1
	rc = 0;
	goto out;		/* diagnostic: setup done, nothing armed */
#endif

	/* 5. command bytes: {0x40|cmd, arg[31:24], arg[23:16], arg[15:8], arg[7:0]}
	 *    packed as the vendor does:
	 *      FIFO0 = (arg>>24)<<8 | (0x40|idx)
	 *      FIFO1 = (arg & 0xFF00) | ((arg>>16)&0xFF)
	 *      FIFO2 =  arg & 0xFF                                        */
	fwr(fcie_base, R_SD_MODE, mode);
	fwr(fcie_base, R_CMDFIFO(0), (u16)(((lba >> 24) << 8) | (0x40 | CMD17)));
	fwr(fcie_base, R_CMDFIFO(1), (u16)((lba & 0xFF00) | ((lba >> 16) & 0xFF)));
	fwr(fcie_base, R_CMDFIFO(2), (u16)(lba & 0xFF));

	/* 6. DAT0 high again, then start the job.  The driver writes
	 *    SD_CTRL = ctrl and then sets BIT_JOB_START as a second write. */
	{
		u64 deadline = ticks() + tick_hz() * 10ULL;
		u64 spin = 0;
		while (frd(fcie_base, R_SD_STATUS) & ST_BUSY)
			if (ticks() > deadline || ++spin > SPIN_CAP) return E_D0;
	}
	fwr(fcie_base, R_SD_CTRL, CTL_READ);
	fwr(fcie_base, R_SD_CTRL, CTL_READ | CTL_START);

	/* 7. CMD_END (driver: WaitEvents(CMD_END, 1 s) inside SendCmd). */
	if (wait_mask(fcie_base, R_EVENT, EV_CMD_END | EV_ERR_STS, 1000000ULL)) {
		rc = E_CMD_TMO;
		goto out_timeout;
	}
	ev = frd(fcie_base, R_EVENT);
	if (ev & EV_ERR_STS) {
		st = frd(fcie_base, R_SD_STATUS);
		rc = E_CMD_STS;
		goto out;
	}
	st = frd(fcie_base, R_SD_STATUS);
	if (st & ST_ERR_MASK) {
		rc = E_CMD_STS;
		goto out;
	}

	/* 8. R1: FIFO bytes 0..5, R1 = bytes 1..4 (byte 0 is 0x40|cmd). */
	w0 = frd(fcie_base, R_CMDFIFO(0));
	w1 = frd(fcie_base, R_CMDFIFO(1));
	w2 = frd(fcie_base, R_CMDFIFO(2));
	r1 = ((u32)(w0 >> 8) << 24) | ((u32)(w1 & 0xFF) << 16) |
	     ((u32)(w1 >> 8) << 8) | (u32)(w2 & 0xFF);
	if (diag) diag[0] = r1;

	/* CMD17 is issued in TRAN(4); the response is the state before the
	 * transfer, so anything below 4 means the card was never identified. */
	if ((r1 & R1_ERRORS) || ((r1 >> 9) & 0xF) < 4) {
		rc = E_R1;
		goto out;
	}

	/* 9. DMA_END (driver: WaitEvents(DMA_END|ERR_STS, 5 s)). */
	if (wait_mask(fcie_base, R_EVENT, EV_DMA_END | EV_ERR_STS, 5000000ULL)) {
		rc = E_DMA_TMO;
		goto out_timeout;
	}
	ev = frd(fcie_base, R_EVENT);
	st = frd(fcie_base, R_SD_STATUS);
	if ((ev & EV_ERR_STS) || (st & ST_ERR_MASK)) {
		rc = E_DMA_STS;
		goto out;
	}

	rc = 0;
out:
	if (diag) {
		diag[1] = st;
		diag[2] = ev;
		diag[3] = miu;
	}
	/* Leave the controller as we found it: drop any armed job (a timed-out
	 * command or DMA must not stay pending across the handover), clear the
	 * events and turn the clock off. */
	fwr(fcie_base, R_SD_CTRL, 0);
	fwr(fcie_base, R_EVENT, EV_ALL_CARD);
	fwr(fcie_base, R_SD_MODE, frd(fcie_base, R_SD_MODE) & ~0x0001);
	return rc;

out_timeout:
	st = frd(fcie_base, R_SD_STATUS);
	goto out;
}
