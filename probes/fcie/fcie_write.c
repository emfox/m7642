/*
 * fcie_write.c -- FCIE single-block write (CMD24) and the probe that finds out
 * how this controller is told "data goes host -> card".
 *
 * Status: OFFLINE.  The read path (fcie_read.c, CMD17) is verified on the
 * device; the write path has never been run.  Two things are unknown offline:
 *
 *   1. the direction encoding -- the vendor's CMD17 path uses
 *      SD_CTRL = 0x020E (ERR_DET_ON|DAT_EN|CMD_EN|RSP_EN) and nothing in the
 *      measured register map says "read vs write".  Either the controller
 *      infers it from the command index, or a bit we have not identified
 *      flips it.  fcie_write_probe() therefore enumerates candidates and lets
 *      the *read-back* decide, rather than guessing;
 *   2. whether the card accepts our 18-step sequence at all.
 *
 * Safety design, because a wrong LBA here writes real eMMC:
 *
 *   - fcie_write_probe() reads the target block first and refuses unless it is
 *     uniformly 0x00 or 0xFF (E_NOT_EMPTY).  A mis-computed LBA that lands on
 *     real data therefore cannot be clobbered.
 *   - it writes a known 512-byte pattern, reads the block back with the
 *     verified CMD17 path, and only reports success when they match (E_VERIFY
 *     otherwise).
 *   - the controller state is saved and restored exactly like the read path,
 *     so the handover to the factory kernel still sees what mboot left.
 *
 * The caller supplies the scratch block address; nothing here picks one.
 */
#include "fcie_regs.h"

/* Candidate SD_CTRL values, most-likely first.  0x020E is the exact value the
 * verified CMD17 path uses -- some controllers take the direction from the
 * command index, in which case that is already correct and costs nothing to
 * try first.  The rest set one extra bit at a time. */
static const u16 ctl_candidates[] = {
	0x020E,   /* same as read: direction implied by the command */
	0x020F,   /* + bit0  */
	0x021E,   /* + bit4  */
	0x022E,   /* + bit5  */
	0x028E,   /* + bit7  */
	0x040E,   /* + bit9  */
	0x060E,   /* + bit10 */
};

#define N_CAND  (sizeof(ctl_candidates) / sizeof(ctl_candidates[0]))

/* freestanding: no libc, so bring our own two (named to avoid a clash if a
 * libc ever gets linked in). */

static int m_cmp(const void *a, const void *b, u64 n)
{
	const u8 *x = (const u8 *)a, *y = (const u8 *)b;
	while (n--) { if (*x != *y) return (int)*x - (int)*y; x++; y++; }
	return 0;
}

/* ---------------------------------------------------------------------- */
/*
 * fcie_write_block(fcie_base, lba, src_pa, ctl, diag)
 *
 *   ctl  : the SD_CTRL value to arm (direction encoding, see above)
 *   diag : optional u64[4]; gets {r1, sd_status, event, miu_addr}
 *
 * Mirrors fcie_read_block() step for step; only the command index and the
 * armed control value differ.
 */
int fcie_write_block(u64 fcie_base, u32 lba, u64 src_pa, u16 ctl, u64 *diag)
{
	u64 miu;
	u16 mode, ev = 0, st = 0, w0, w1, w2;
	u16 save_ctl, save_mode, save_sdctrl, save_dl, save_dh, save_d47;
	u32 r1;
	int rc;

	if (diag) {
		diag[0] = 0; diag[1] = 0; diag[2] = 0; diag[3] = 0;
	}
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
	{
		u64 deadline = ticks() + tick_hz() * 10ULL;
		u64 spin = 0;
		while (frd(fcie_base, R_SD_STATUS) & ST_BUSY)
			if (ticks() > deadline || ++spin > SPIN_CAP) { rc = E_D0; goto out; }
	}

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

	/* 6. DAT0 high again, then arm and start. */
	{
		u64 deadline = ticks() + tick_hz() * 10ULL;
		u64 spin = 0;
		while (frd(fcie_base, R_SD_STATUS) & ST_BUSY)
			if (ticks() > deadline || ++spin > SPIN_CAP) { rc = E_D0; goto out; }
	}
	fwr(fcie_base, R_SD_CTRL, ctl);
	fwr(fcie_base, R_SD_CTRL, ctl | CTL_START);

	/* 7. CMD_END. */
	if (wait_mask(fcie_base, R_EVENT, EV_CMD_END | EV_ERR_STS, 1000000ULL)) {
		rc = E_CMD_TMO; goto out_timeout;
	}
	ev = frd(fcie_base, R_EVENT);
	if (ev & EV_ERR_STS) { rc = E_CMD_STS; goto out; }
	st = frd(fcie_base, R_SD_STATUS);
	if (st & ST_ERR_MASK) { rc = E_CMD_STS; goto out; }

	/* 8. R1. */
	w0 = frd(fcie_base, R_CMDFIFO(0));
	w1 = frd(fcie_base, R_CMDFIFO(1));
	w2 = frd(fcie_base, R_CMDFIFO(2));
	r1 = ((u32)(w0 >> 8) << 24) | ((u32)(w1 & 0xFF) << 16) |
	     ((u32)(w1 >> 8) << 8) | (u32)(w2 & 0xFF);
	if (diag) diag[0] = r1;

	/* CMD24 is issued in TRAN(4) too. */
	if ((r1 & R1_ERRORS) || ((r1 >> 9) & 0xF) < 4) { rc = E_R1; goto out; }

	/* 9. DMA_END. */
	if (wait_mask(fcie_base, R_EVENT, EV_DMA_END | EV_ERR_STS, 5000000ULL)) {
		rc = E_DMA_TMO; goto out_timeout;
	}
	ev = frd(fcie_base, R_EVENT);
	st = frd(fcie_base, R_SD_STATUS);
	if ((ev & EV_ERR_STS) || (st & ST_ERR_MASK)) { rc = E_DMA_STS; goto out; }

	rc = 0;
out:
	if (diag) { diag[1] = st; diag[2] = ev; diag[3] = miu; }
out_timeout:
	fwr(fcie_base, R_SD_CTRL, save_sdctrl);
	fwr(fcie_base, R_DMA_ADDR_L, save_dl);
	fwr(fcie_base, R_DMA_ADDR_H, save_dh);
	fwr(fcie_base, R_DMA_ADDR_47_32, save_d47);
	fwr(fcie_base, R_SD_MODE, save_mode);
	fwr(fcie_base, R_FUNC_CTL, save_ctl);
	return rc;
}

/* ---------------------------------------------------------------------- */
/*
 * fcie_write_probe(fcie_base, lba, buf_pa, diag)
 *
 * Decides whether a write is possible at all, and with which direction
 * encoding.  buf_pa is 512 bytes of scratch DDR in MIU0; it is used both as
 * the write source and as the read-back target, i.e. a *second* 512-byte
 * scratch page at buf_pa + 0x200 is needed.
 *
 * diag[0] = the ctl value that verified (0 if none)
 * diag[1] = rc of the last attempt
 * diag[2] = how many candidates were tried
 * diag[3] = the original block's first 4 bytes (so a non-uniform refusal is
 *           visible in the record)
 *
 * Refuses (E_NOT_EMPTY) unless the block is uniformly 0x00 or 0xFF.
 */
int fcie_write_probe(u64 fcie_base, u32 lba, u64 buf_pa, u64 *diag)
{
	u8 *wbuf = (u8 *)buf_pa;
	u8 *rbuf = (u8 *)(buf_pa + 0x200);
	u64 d[4];
	u32 i;
	int rc;

	if (diag) { diag[0] = 0; diag[1] = 0; diag[2] = 0; diag[3] = 0; }

	/* Safety interlock: read the target first, and only proceed if it is
	 * uniformly empty.  This is what makes a mis-computed LBA harmless. */
	rc = fcie_read_block(fcie_base, lba, buf_pa, d);
	if (rc)
		return rc;
	if (diag) diag[3] = ((u64)wbuf[0] << 24) | ((u64)wbuf[1] << 16) |
			    ((u64)wbuf[2] << 8) | wbuf[3];
	{
		u8 first = wbuf[0];
		int uniform = 1;
		if (first != 0x00 && first != 0xFF)
			uniform = 0;
		for (i = 1; uniform && i < 512; i++)
			if (wbuf[i] != first)
				uniform = 0;
		if (!uniform)
			return E_NOT_EMPTY;
	}

	/* Known pattern: byte i = 0xA5 ^ i, so a partial transfer is obvious. */
	for (i = 0; i < 512; i++)
		wbuf[i] = (u8)(0xA5u ^ (u8)i);

	for (i = 0; i < N_CAND; i++) {
		rc = fcie_write_block(fcie_base, lba, buf_pa, ctl_candidates[i], d);
		if (diag) diag[1] = (u64)rc;
		if (rc)
			continue;
		/* Verify with the path we trust. */
		rc = fcie_read_block(fcie_base, lba, buf_pa + 0x200, d);
		if (diag) diag[1] = (u64)rc;
		if (rc)
			continue;
		if (m_cmp(wbuf, rbuf, 512) == 0) {
			if (diag) { diag[0] = ctl_candidates[i]; diag[2] = i + 1; }
			return 0;
		}
		rc = E_VERIFY;
	}
	if (diag) diag[2] = N_CAND;
	return rc ? rc : E_VERIFY;
}
