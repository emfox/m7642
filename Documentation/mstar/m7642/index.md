# m7642 文档索引

按子系统一篇。每篇的体例固定：**结论 → 证据 → 对主线的意义 → 待办**。
拿不到证据的一律写"待确认"，不写推测当结论。

| 文档 | 内容 |
|---|---|
| [hardware.md](hardware.md) | 这台机器上有什么硬件、主线认不认（14 项清单） |
| [upstreaming.md](upstreaming.md) | 每一块最后落到主线哪个目录（按子系统，不按设备） |
| [portability.md](portability.md) | 各驱动的离线编译移植成本评分（v7.3 + GCC 13.3） |
| [roadmap.md](roadmap.md) | 阶段划分与估工 |
| [display.md](display.md) | 面板怎么亮：GOP 寄存器探测 + simplefb 路线 |
| [uart.md](uart.md) | 串口：基址、8 字节寄存器步距、中断号（零驱动工作） |
| [gop-registers.md](gop-registers.md) | GOP 全量寄存器图、黄金基线、易变寄存器 |
| [usb.md](usb.md) | USB 寄存器地图（四路基址、16 位拼接访问器） |
| [usb-phy.md](usb-phy.md) | UTMI 上电序列：活体 vs m7322 源码对照 |
| [hdmi.md](hdmi.md) | HDMI RX/TX 盘点（两条链路都零源码） |
| [smp.md](smp.md) | 多核启动协议（非标准 spin-table） |
| [remote-testing.md](remote-testing.md) | 不插 U 盘、不按键的远程验证路径 |
| [boot-test.md](boot-test.md) | 启动路径：实测 boot image 参数、分区、可观察性 |
| [ir-and-recovery.md](ir-and-recovery.md) | 红外救不了砖（解码在内核里）、mboot 的启动模式与远程恢复边界 |
| [mboot-bootmode.md](mboot-bootmode.md) | mboot 镜像结构、内置 env、`update_mode` 命令，以及为什么没有纯软件救砖路径 |
| [recovery-stick.md](recovery-stick.md) | 自建 U 盘升级 BIN：格式实测、`mmc write.p`、救援盘与测试盘的脚本路线 |
| [online-test-ladder.md](online-test-ladder.md) | 在线验证的阶梯：从空模块到真探针 |

## 可背下来的几条

1. **刷机限制在脚本区 CRC**：`.bin` 尾部 24 字节 = `16×0xFF + "12345678" + crc32(前 0x4000)`；
   分区镜像本身无签名（`verifiedbootstate=orange`）。工具 `fw/fix_footer_crc.py`。
2. **显示不用重做时序**：cmdline 有 `recovery_fbaddr=0x2D100000`，面板与 tcon 都是 bootloader 做完了；
   `grep -i tcon /proc/kallsyms` 零命中就是证据。
3. **USB 块是 16 位寄存器**，32 位 EHCI 寄存器由两个半字拼成（低半字 `2*off`、高半字 `2*off+4`）。
   主线 `ehci-platform` 不能直接替换，要补访问器。MT7663 那一路 = `pm+0x2600`。
4. **SMP 不是标准 spin-table**：release 寄存器在 `pm + 2*cpu-release-addr`，是 3 字邮箱 + ack。
   P0 单核即可。
5. **HDMI 零源码**：GPL 包里 `drv/hdmitx4vx1/` 只剩一个 Kconfig；HDCP 是硬件引擎 + OTP 密钥。
6. **串口不用写驱动**：`0x1F201300`，寄存器步距 8 字节（`reg-shift = <3>`），SPI 0，123 MHz。
   厂商把 8250 偏移翻倍再 `<<2`，净值就是标准 8250 —— 见 `uart.md`。

## 在线实验纪律（代价换来的）

- **禁止 MMIO 盲扫。** 厂商块里有未实现空洞，读到就 external abort，arm64 直接 panic。
  曾经在 `0xFD200000+0..0x40000` 按 0x100 步长扫 USB 块，电视当场重启。
- **碰新块先用对齐的字宽读**（`readl`），别用逐字节 hexdump。曾经按字节读 HDMI RX 块
  （`pm+0x2E7000`），电视再次重启。
- **地址算术错一位不会报错**，只会读到"平静的一整片 0"。凡是读到全零，
  先复核算术（`pm+0x22600` 是 `0xffffff800a022600`，不是 `…0a226000`），再怀疑硬件。
- **读之前记 uptime**。崩了第一时间抓 `/sys/fs/pstore/console-ramoops`——
  Android 的 init 会在启动时清 pstore，晚几分钟就只剩新启动的日志。
- `insmod` 用 `/vendor/bin/busybox`（toybox 的走 `finit_module(2)`，在这台机器上会自旋）。
- 内核符号地址只能用 `kallsyms_lookup_name` 在模块内取（`/proc/kallsyms` 全是 0，
  `kptr_restrict=2` 对 root 也生效）。
- 提权走 `/data/local/tmp/tvroot.cmd`：写命令 → 等 12–15 秒 → 读 `tvroot.out`。
- `adb` 的 server 会随上一个 shell 结束而死，**connect 与动作要写在同一个调用里**。
