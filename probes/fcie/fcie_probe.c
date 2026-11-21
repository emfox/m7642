/*
 * fcie_probe.c -- the "one call" entry point for the bare-metal probe.
 *
 * Everything above it (checkpoint stub, MMU/cache shutdown, copy to a fixed
 * physical page) already exists in probes/handoff/abort-postmmu.S; this is the
 * only eMMC-specific part.
 *
 * Reads LBA 0 of the user area into physical 0x23080000 and leaves a 32-byte
 * heartbeat at the end of the same page, so a later boot can tell success from
 * failure without a serial port:
 *
 *   0x23080FF0  "FCIE1" (0x4643494531)
 *   0x23080FF8  return code (0 = ok)
 *   0x23081000? no -- all four words stay inside the page:
 *   +0x0  +0x8  +0x10  +0x18 at 0x23080FE0
 */
typedef unsigned long long u64;

int fcie_read_block(u64 fcie_base, unsigned int lba, u64 dst_pa, u64 *diag);

#define FCIE0_PA   0x1F222600UL     /* FCIE0 register block, physical        */
#define STASH_PA   0x23080000UL     /* project stash page                    */
#define HB_PA      0x23080FE0UL     /* heartbeat, past the 512-byte payload  */

unsigned long fcie_probe_once(unsigned int lba)
{
	volatile u64 *hb = (volatile u64 *)HB_PA;
	u64 diag[4];
	int rc;

	rc = fcie_read_block(FCIE0_PA, lba, STASH_PA, diag);

	hb[0] = 0x4643494531ULL;        /* "FCIE1" */
	hb[1] = (u64)(long)rc;
	hb[2] = diag[0];                /* R1 card status   */
	hb[3] = diag[1];                /* SD_STATUS        */

	return (unsigned long)(long)rc;
}
