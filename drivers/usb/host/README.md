# drivers/usb/host/

将来放 `ehci-mstar.c`（m7642 glue）。现在还没有代码，下面是已经确定、写代码时要用的东西：

1. **寄存器是 16 位拼接的**：低半字在 `2*off`、高半字在 `2*off+4`，厂商改的就是 `ehci_readl` /
   `ehci_writel`（见 `Documentation/mstar/m7642/usb.md` 第三节）。主线没有这个钩子，
   要么给 `ehci.h` 加 `#ifdef CONFIG_USB_EHCI_MSTAR`，要么自带一份变体。
2. **四路基址**（相对 `mstar_pm_base + 0x200000`）：`0x4800 / 0x1A00 / 0x2600 / 0x4E2800`，
   MT7663 在第三路。
3. **中断**：硬编码 39 / 65 / 68 / 94（厂商用 `ENABLE_IRQ_REMAP`）；走 DT 时要写进节点。
4. **PHY 上电序列**：抄 `Titania3_series_start_ehc()`，但 UPLL 段按 m7642 改写
   （见 `Documentation/mstar/m7642/usb-phy.md` 第四节）。
