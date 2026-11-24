import os
p=os.path.expanduser("~/Debian/m7642/probes/fcie/fcie_regs.h")
s=open(p).read()
s=s.replace('#define R_SD_CTRL        0x0C   /* bit1 RSP_EN, bit2 CMD_EN, bit3 DAT_EN, bit6 START */',
 '#define R_SD_CTRL        0x0C   /* bit1 RSP_EN bit2 CMD_EN bit3 DAT_EN bit4 DAT_DIR_W(!) bit5 ADMA_EN bit6 START bit9 ERR_DET_ON */')
if "CTL_WR_CMD" not in s:
    s=s.replace('#define CTL_START    0x0040     /* BIT_JOB_START                                      */',
'''#define CTL_START    0x0040     /* BIT_JOB_START                                      */
/* CMD24 is a TWO-STAGE job (vendor: eMMC_hal_v5.c:3475 / :3572).  Writing one
 * 0x020E-style value with DAT_EN set is not something the vendor ever does. */
#define CTL_WR_CMD   0x0006     /* command stage: CMD_EN|RSP_EN                       */
#define CTL_WR_DAT   0x0218     /* data stage: DAT_EN|DAT_DIR_W|ERR_DET_ON            */''')
s=s.replace("int fcie_write_block(u64 fcie_base, u32 lba, u64 src_pa, u16 ctl, u64 *diag);",
            "int fcie_write_block(u64 fcie_base, u32 lba, u64 src_pa, u64 *diag);")
open(p,"w").write(s)
print("header ok:", "CTL_WR_CMD" in s, "u16 ctl" not in s)
