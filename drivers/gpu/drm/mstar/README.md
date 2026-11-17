# drivers/gpu/drm/mstar/

将来放显示驱动（gflip / gop / 面板）。**P0 不用它**——第一版走 `simplefb`，
只需要 DTS 里把 `recovery_fbaddr=0x2D100000` 那段内存标成 `simple-framebuffer`。

要用到的事实（详见 `Documentation/mstar/m7642/display.md`、`gop-registers.md`）：

- 面板时序、tcon、mspi 初始化都在 bootloader 里做完了，内核侧零符号（`grep tcon /proc/kallsyms` 空）。
- GOP 寄存器只能通过厂商访问器读：`MHal_GFLIP_ReadGopReg(idx, bank, off, *out)`，
  按 bank/offset 索引，不是线性 MMIO。
- 有三份不同时刻的快照，排除 38 个易变寄存器后**1205 个静态寄存器完全一致**，
  可作黄金基线（`artifacts/snapshots/baseline-2026-11-17.txt`）。
- 帧缓冲地址在 GOP 里查不到（由 RAM 描述符维护，flip 时才写），所以别指望从寄存器反推。
