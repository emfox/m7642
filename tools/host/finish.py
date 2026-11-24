import os
D=os.path.expanduser("~/Debian/m7642/probes/fcie")
p=os.path.join(D,"fcie_regs.h"); s=open(p).read()
if "fcie_write_probe" not in s:
    s=s.replace("#endif /* FCIE_REGS_H */","""/* ---- entry points ----------------------------------------------------- */
int fcie_read_block(u64 fcie_base, u32 lba, u64 dst_pa, u64 *diag);
int fcie_write_block(u64 fcie_base, u32 lba, u64 src_pa, u16 ctl, u64 *diag);
int fcie_write_probe(u64 fcie_base, u32 lba, u64 buf_pa, u64 *diag);

#endif /* FCIE_REGS_H */""")
    open(p,"w").write(s); print("原型已加进头文件")
