/*
 * fcie_write.c -- FCIE single-block write (CMD24) through the MStar eMMC host.
 *
 * Status: OFFLINE, never run on the device.  The read path (fcie_read.c, CMD17)
 * is the correctness reference and is verified on hardware.
 *
 * The sequence below is transcribed from the vendor source, not guessed:
 *
 *   drv/mmc/inc/config/eMMC_reg_v5.h:285-296
 *     BIT1 RSP_EN, BIT2 CMD_EN, BIT3 DTRX_EN/DAT_EN, BIT4 DAT_DIR_W,
 *     BIT5 ADMA_EN, BIT6 JOB_START, BIT9 ERR_DET_ON
 *   drv/mmc/src/common/eMMC_hal_v5.c:2507  CMD17  -> CMD_EN|RSP_EN|DAT_EN|ERR_DET_ON = 0x020E
 *   drv/mmc/src/common/eMMC_hal_v5.c:3475  CMD24  -> CMD_EN|RSP_EN                 = 0x0006  (command stage)
 *   drv/mmc/src/common/eMMC_hal_v5.c:3572  CMD24  -> DAT_EN|DIR_W|ERR_DET_ON        = 0x0218  (data stage)
 *   drv/mmc/mstar_mci_v5.c:1138            write  -> DAT_EN|DIR_W|ERR_DET_ON        = 0x0218
 *
 * So a write is a TWO-STAGE job: arm the command, check R1, wait for DAT0, then
 * arm the data stage.  The read path is a single-stage job; copying its shape
 * and just flipping a bit does not work, and the vendor tree never combines
 * CMD_EN|RSP_EN with DAT_EN (25 SD_CTRL writes, none of them).
 *
 * Safety (a wrong LBA here writes real eMMC):
 *   - the caller's target block is read first and refused unless uniformly
 *     0x00/0xFF, so a mis-computed LBA cannot clobber real data;
 *   - the block is written, read back with the verified CMD17 path, and only
 *     reported as success when the 512 bytes match;
 *   - controller state is saved and restored exactly like the read path.
 */
#include "fcie_regs.h"

static int m_cmp(const void *a, const void *b, u64 n);

/* wait until the card releases DAT0 (i.e. is not busy). */
static int wait_d0(u64 base)
{
	u64 deadline = ticks() + tick_hz() * 10ULL;
	u64 spin = 0;

	while (frd(base, R_SD_STATUS) & ST_BUSY)
		if (ticks() > deadline || ++spin > SPIN_CAP)
			return E_D0;
	return 0;
}

/* arm SD_CTRL and start the job: the vendor writes the value, then sets
 * BIT_JOB_START as a second write. */
static void arm(u64 base, u16 ctl)
{
	fwr(base, R_SD_CTRL, ctl);
	fwr(base, R_SD_CTRL, ctl | CTL_START);
}

/* ---------------------------------------------------------------------- */
int fcie_write_block(u64 fcie_base, u32 lba, u64 src_pa, u64 *diag)
{
	u64 miu;
	u16 mode, ev = 0, st = 0, w0, w1, w2;
	u16 save_ctl, save_mode, save_sdctrl, save_dl, save_dh, save_d47;
	u32 r1 = 0;
	int rc;

	if (diag) { diag[0] = 0; diag[1] = 0; diag[2] = 0; diag[3] = 0; }
	if (src_pa < 0x20000000ULL || src_pa >= 0x100000000ULL)
		return E_DEST;
	miu = src_pa - 0x20000000ULL;          /* MSTAR_MIU0_BUS_BASE */

	if (frd(fcie_base, R_NC_FUN_CTL) & 1)
		return E_NC;

	save_ctl    = frd(fcie_base, R_FUNC_CTL);
	save_mode   = frd(fcie_base, R_SD_MODE);
	save_sdctrl = frd(fcie_base, R_SD_CTRL);
	save_dl     = frd(fcie_base, R_DMA_ADDR_L);
	save_dh     = frd(fcie_base, R_DMA_ADDR_H);
	save_d47    = frd(fcie_base, R_DMA_ADDR_47_32);

	fwr(fcie_base, R_FUNC_CTL, frd(fcie_base, R_FUNC_CTL) |
				   FUNC_EMMC_ACTIVE | FUNC_SD_EN);
	mode = frd(fcie_base, R_SD_MODE) | 0x0001;   /* clock on, keep width/DDR */
	fwr(fcie_base, R_SD_MODE, mode);

	/* 1. DAT0 high before a command. */
	if (wait_d0(fcie_base)) { rc = E_D0; goto out; }

	/* 2. clear latched events and error flags, bounded. */
	{
		u64 deadline = ticks() + tick_hz();
		u64 spin = 0;
		for (;;) {
			fwr(fcie_base, R_EVENT, EV_ALL_CARD);
			if (!(frd(fcie_base, R_EVENT) & EV_ALL_CARD))
				break;
			if (ticks() > deadline || ++spin > SPIN_CAP) { rc = E_EV_CLR; goto out; }
		}
	}
	fwr(fcie_base, R_EVENT, 0x0000);
	fwr(fcie_base, R_SD_STATUS, ST_ERR_MASK);    /* W1C */

	/* 3. one block, 512 bytes, MIU0. */
	fwr(fcie_base, R_JOB_BL_CNT, 1);
	fwr(fcie_base, R_BLK_SIZE, 512);
	fwr(fcie_base, R_DMA_LEN_L, 512);
	fwr(fcie_base, R_DMA_LEN_H, 0);
	fwr(fcie_base, R_MMA_PRI, frd(fcie_base, R_MMA_PRI) & ~0x000C);
	fwr(fcie_base, R_DMA_ADDR_L, (u16)(miu & 0xFFFF));
	fwr(fcie_base, R_DMA_ADDR_H, (u16)((miu >> 16) & 0xFFFF));
	fwr(fcie_base, R_DMA_ADDR_47_32, (u16)(miu >> 32));

	/* 4. R1 response, 5 bytes. */
	fwr(fcie_base, R_CMD_RSP_SIZE,
	    (frd(fcie_base, R_CMD_RSP_SIZE) & ~0x003F) | 5);

	/* 5. command bytes, same packing as the vendor: CMD24 with the LBA. */
	fwr(fcie_base, R_SD_MODE, mode);
	fwr(fcie_base, R_CMDFIFO(0), (u16)(((lba >> 24) << 8) | (0x40 | CMD24)));
	fwr(fcie_base, R_CMDFIFO(1), (u16)((lba & 0xFF00) | ((lba >> 16) & 0xFF)));
	fwr(fcie_base, R_CMDFIFO(2), (u16)(lba & 0xFF));

	/* 6. command stage: CMD24 is armed *without* DAT_EN. */
	if (wait_d0(fcie_base)) { rc = E_D0; goto out; }
	arm(fcie_base, CTL_WR_CMD);

	/* 7. CMD_END. */
	if (wait_mask(fcie_base, R_EVENT, EV_CMD_END | EV_ERR_STS, 1000000ULL)) {
		rc = E_CMD_TMO; goto out;
	}
	st = frd(fcie_base, R_SD_STATUS);
	ev = frd(fcie_base, R_EVENT);
	if ((ev & EV_ERR_STS) || (st & ST_ERR_MASK)) { rc = E_CMD_STS; goto out; }

	/* 8. R1. */
	w0 = frd(fcie_base, R_CMDFIFO(0));
	w1 = frd(fcie_base, R_CMDFIFO(1));
	w2 = frd(fcie_base, R_CMDFIFO(2));
	r1 = ((u32)(w0 >> 8) << 24) | ((u32)(w1 & 0xFF) << 16) |
	     ((u32)(w1 >> 8) << 8) | (u32)(w2 & 0xFF);
	if (diag) diag[0] = r1;
	/* Must be in TRAN(4) or later; PRG(7) is legitimate for a cached write. */
	if ((r1 & R1_ERRORS) || ((r1 >> 9) & 0xF) < 4) { rc = E_R1; goto out; }

	/* 9. data stage: DAT_EN | DIR_W | ERR_DET_ON.  Make sure the source
	 * block has reached memory before the controller starts reading it. */
	__asm__ volatile("dsb sy" ::: "memory");
	if (wait_d0(fcie_base)) { rc = E_D0; goto out; }
	arm(fcie_base, CTL_WR_DAT);

	/* 10. DMA_END. */
	if (wait_mask(fcie_base, R_EVENT, EV_DMA_END | EV_ERR_STS, 5000000ULL)) {
		rc = E_DMA_TMO; goto out;
	}
	st = frd(fcie_base, R_SD_STATUS);
	ev = frd(fcie_base, R_EVENT);
	if ((ev & EV_ERR_STS) || (st & ST_ERR_MASK)) { rc = E_DMA_STS; goto out; }

	rc = 0;
out:
	if (diag) { diag[1] = st; diag[2] = ev; diag[3] = miu; }
	/* Same restore order as the verified read path, including the event
	 * clear: an armed job left pending would confuse the handover. */
	fwr(fcie_base, R_SD_CTRL, save_sdctrl);
	fwr(fcie_base, R_DMA_ADDR_L, save_dl);
	fwr(fcie_base, R_DMA_ADDR_H, save_dh);
	fwr(fcie_base, R_DMA_ADDR_47_32, save_d47);
	fwr(fcie_base, R_EVENT, EV_ALL_CARD);
	fwr(fcie_base, R_FUNC_CTL, save_ctl);
	fwr(fcie_base, R_SD_MODE, save_mode);
	return rc;
}

/* ---------------------------------------------------------------------- */
/*
 * fcie_write_probe(fcie_base, lba, buf_pa, diag)
 *
 * buf_pa: 1 KiB of scratch DDR in MIU0; [0,512) is the write source,
 * [512,1024) receives the read-back.
 *
 * diag[0] = R1 of the write command (0 if it never got there)
 * diag[1] = SD_STATUS at the last failure
 * diag[2] = EVENT at the last failure
 * diag[3] = MIU address
 *
 * On entry diag[3] is reused to carry the target block's first 4 bytes, so a
 * refusal (E_NOT_EMPTY) shows what was actually there.
 */
int fcie_write_probe(u64 fcie_base, u32 lba, u64 buf_pa, u64 *diag)
{
	volatile u8 *wbuf = (volatile u8 *)buf_pa;
	volatile u8 *rbuf = (volatile u8 *)(buf_pa + 0x200);
	u64 d[4];
	u32 i, head;
	u8 first;
	int uniform, rc;

	if (diag) { diag[0] = 0; diag[1] = 0; diag[2] = 0; diag[3] = 0; }

	/* Safety interlock: read the target first, proceed only if uniformly
	 * empty.  This is what makes a mis-computed LBA harmless. */
	rc = fcie_read_block(fcie_base, lba, buf_pa, d);
	if (rc) {
		if (diag) { diag[0] = d[0]; diag[1] = d[1]; diag[2] = d[2]; }
		return rc;
	}
	head = ((u32)wbuf[0] << 24) | ((u32)wbuf[1] << 16) |
	       ((u32)wbuf[2] << 8) | (u32)wbuf[3];
	if (diag) diag[3] = head;

	first = wbuf[0];
	uniform = (first == 0x00 || first == 0xFF);
	for (i = 1; uniform && i < 512; i++)
		if (wbuf[i] != first)
			uniform = 0;
	if (!uniform)
		return E_NOT_EMPTY;

	/* Known pattern: byte i = 0xA5 ^ i, so a partial transfer is obvious. */
	for (i = 0; i < 512; i++)
		((u8 *)buf_pa)[i] = (u8)(0xA5u ^ (u8)i);

	rc = fcie_write_block(fcie_base, lba, buf_pa, d);
	if (diag) { diag[0] = d[0]; diag[1] = d[1]; diag[2] = d[2]; }
	if (rc)
		return rc;

	/* Verify with the path we trust. */
	rc = fcie_read_block(fcie_base, lba, buf_pa + 0x200, d);
	if (diag && rc) { diag[0] = d[0]; diag[1] = d[1]; diag[2] = d[2]; }
	if (rc)
		return rc;
	if (m_cmp((const void *)wbuf, (const void *)rbuf, 512) != 0)
		return E_VERIFY;
	return 0;
}

static int m_cmp(const void *a, const void *b, u64 n)
{
	const u8 *x = (const u8 *)a, *y = (const u8 *)b;
	while (n--) { if (*x != *y) return (int)*x - (int)*y; x++; y++; }
	return 0;
}
