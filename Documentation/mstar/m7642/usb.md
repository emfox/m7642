# USB 子系统：寄存器地图与移植缺口

2026-11-17 实测定稿。目标：搞清 MT7663（WiFi+BT，`0e8d:7663`）在主线内核下需要什么。

## 一、结论先说

1. **控制器逻辑上是标准 EHCI**：四路的 `hc_capbase` 解出来都是 `CAPLENGTH=0x10 / HCIVERSION=0x0100`，
   `hcs_params=1`（单端口，与 sysfs `maxchild=1` 一致），`hcc_params=6`（64 位寻址）。
2. **但寄存器不是直连的**：MStar 的 USB 块是 **16 位寄存器**，一个 32 位 EHCI 寄存器由
   两个相邻 16 位半字拼成（低半字在 `2*off`，高半字在 `2*off+4`）。厂商为此改了 `ehci.h` 的
   `ehci_readl/ehci_writel`（见第三节）。**主线 `ehci-platform` 直接拿去用会读错寄存器**，这是移植的主要缺口。
3. **四路基址已全部实测确认**，包括 MT7663 所在的第三路。此前"第三路读全零"的结论作废（两处错误，见第七节）。

## 二、基址表（m7642 实测）

`mstar_pm_base = 0xffffff800a000000`（物理 `0xFD000000`），USB 块 = `PM + 0x200000`：

| 项 | 物理 | 内核虚拟 |
|---|---|---|
| USB 块 | `0xFD200000` | `0xffffff800a200000` |
| 访问方式 | 驱动里 `hcd->regs = (void *)hcd->rsrc_start`，**不做 ioremap**，直接用算好的虚拟地址 | |

四路端口（偏移相对 USB 块；`ehc` 即 EHCI 寄存器组）：

| 端口 | 平台设备 | 总线 | irq | ehc | utmi | usbc | bc |
|---|---|---|---|---|---|---|---|
| 1 | `Mstar-ehci-1` | usb2 | 39 | `0x04800` | `0x07500` | `0x00E00` | `0x46C00` |
| 2 | `Mstar-ehci-2` | usb1 | 65 | `0x01A00` | `0x07400` | `0x00F00` | `0x46C40` |
| **3** | `Mstar-ehci-3` | **usb3（MT7663）** | 68 | **`0x02600`** | `0x02900` | `0x02400` | `0x02000` |
| 4 | `Mstar-ehci-4` | usb4 | 94 | `0x4E2800` | `0x4E2400` | `0x4E2200` | `0x4E2640` |

绝对地址（端口 3，MT7663 那一路）：

```
ehc   0xFD202600   VA 0xffffff800a022600   ← EHCI 寄存器组
utmi  0xFD202900   VA 0xffffff800a022900   ← PHY，内核初始化
usbc  0xFD202400   VA 0xffffff800a022400
bc    0xFD202000   VA 0xffffff800a022000
```

注意 **端口 3/4 与 m7322 的 HAL 头完全不同**：m7322 写的是 `UHC2=0x27200`、`UHC3=0x44C00`，
m7642 实际是 `0x02600` 和 `0x4E2800`。前两路（`0x4800`/`0x1A00`）两代一致。
⟹ **不能照抄 `kernel_mstar` 树里的 m7322 头文件**，这张表才是 m7642 的真值。

## 三、关键：16 位拼接访问器

`drivers/usb/host/ehci.h`（`MP_USB_MSTAR==1`）：

```c
static inline unsigned int ehci_readl(struct ehci_hcd *ehci, __u32 __iomem *regs)
{
	regs = (u32 *)( ((uintptr_t)regs & ~(0xffUL)) + (((uintptr_t)regs & 0xffUL)<<1));
	result = (readl((void*)regs) & 0xffffU)
	       | ((readl((void*)((uintptr_t)regs+4)) << 16) & (0xffffU<<16));
	return result;
}
```

含义：低字节（寄存器内偏移）翻倍定址，低 16 位在 `2*off`、高 16 位在 `2*off+4`。
写方向同理（`ehci_writel` 分两次 `writel`）。`UTMI` 那些字节寄存器干脆在宏里手写 `*2`：

```c
writeb(readb(UTMI_base + 0x0*2)  | (BIT7|BIT6|BIT1), UTMI_base + 0x0*2);
writeb(readb(UTMI_base + 0x52*2) | (BIT5|...|BIT0), UTMI_base + 0x52*2);
```

⟹ 主线要挪这颗 SoC 的 USB，必须给 `ehci.h` 加同样的一层访问器钩子（约 40 行，
`#ifdef CONFIG_USB_EHCI_MSTAR` 即可），或者干脆自带一份 ehci 变体驱动。
好消息是**逻辑仍是标准 EHCI**，不用重写 hub/urb/调度那部分。

## 四、寄存器图实测（自证）

在四路 `ehc` 各读 64 字节（`artifacts/probe-out/usbmap-2026-11-17.txt`），按上面的拼接规则解码：

| 逻辑偏移 | 寄存器 | 端口 1/2/4 | 端口 3 |
|---|---|---|---|
| 0x00 | `hc_capbase` | `0x01000010` → CAPLEN 0x10, HCIVER 0x0100 | 同左 |
| 0x04 | `hcs_params` | `1`（N_PORTS=1） | 同左 |
| 0x08 | `hcc_params` | `6`（64-bit） | 同左 |
| 0x10 | `USBCMD` | `0x00010b01` | **`0x00010b31`**（多 PSE\|ASE） |
| 0x14 | `USBSTS` | `0` | **`0xC000`（PSS\|ASS 在跑）** |
| 0x1c | `FRINDEX` | `0` | **`0x3317`（帧计数在走）** |

端口 3 的三处差异正好是"这个控制器此刻在传数据"的证据 —— 与 `/proc/interrupts` 里
irq 68 是唯一有计数的那一路、且 MT7663 挂在 bus3 完全吻合。

UTMI 侧四路也读到了同构的值（`c3 4c / 84 2c / 60 30 / 40 30 …`），端口 3 只有两处不同
（`0x0000` vs `0x4cc3`、`0x8040` vs `0x4040`），可作 PHY 初始化后的对照基线。

## 五、中断与驱动绑定

```
/proc/interrupts:
 39: GICv2  ehci_hcd:usb2     65: GICv2  ehci_hcd:usb1
 68: GICv2  ehci_hcd:usb3   ← 唯一有活动（30583 / 26774）
 94: GICv2  ehci_hcd:usb4
```

中断号**写死在驱动里**（`ENABLE_IRQ_REMAP` 打开，`MSTAR_EHCx_IRQ` 宏），DT 节点
`Mstar-ehci-1..4` **只有 `compatible`，没有 `reg`、没有 `interrupts`**：

```
Mstar-ehci-3 { compatible = "Mstar-ehci-3"; };
```

⟹ 内核里 `irq_of_parse_and_map()` 拿不到东西，全靠 `strncmp(dev->name, "Mstar-ehci-3")`
分支赋基址和 irq。主线要改成 DT 驱动，就得在 DTS 里补 `reg` + `interrupts`，这反而是好事。

## 六、PHY 初始化在核内（源码可抄，已实测同构）

```c
ehci_mstar_hw_init(hcd)                      // ehci-mstar.c:667
  └─ Titania3_series_start_ehc(hcd, utmi_base, usbc_base, ehc_base, flag)   // :282
```

与显示形成对照：**TCON 是 bootloader 干的（核内零符号），USB PHY 是内核干的（代码完整）**。

已把设备上的 `Titania3_series_start_ehc` 机器码 dump 出来逐条对照（`usb-phy.md`）：
序列与 m7322 源码同构，`0x2084` / `0x8051` 两个特征值逐字命中；
**唯一实质差异是 UPLL 段**（m7642 没有 `0x10e0` 那次写入，改成对 `UTMI+0x44` 置 bit0）。

## 七、这张表是怎么定出来的（方法论）

`/proc/kallsyms` 在这台机器上**全是 0**（`kptr_restrict=2`，root 也一样），所以走内核内解析：

1. `probeG.ko sym=ehci_hcd_mstar_drv_probe len=3072` → 用 `kallsyms_lookup_name()` 拿到活体地址、
   把机器码 dump 到文件（`artifacts/disasm/ehci_probe.bin`）；
2. 本地 `aarch64-linux-objdump -D -b binary -m aarch64` 反汇编（`artifacts/disasm/ehci_probe.asm`）；
3. 在 probe 里找 `str x?,[x21,#560/568/576/584]` 四连写 → 结构体字段 = utmi/ehc/usbc/bc，
   常量就是四路基址；`movz w23,#0x27/#0x41/#0x44/#0x5e` 顺带证实硬编码 irq 39/65/68/94；
4. 回读硬件验证（只看已确认的小窗口，不扫）。

### 此前两处错误（都已纠正）

- **错在地址算术**：把 `pm+0x22600` 写成 `0xffffff800a226000`（多打一位），
  于是读到一片空洞、误判"该控制器读全零"。正确地址是 `0xffffff800a022600`。
  同一错误也污染了更早那次"UHC2 = 0x27200 读全零"的记录。
- **错在照抄 m7322 头文件**：`0x27200` / `0x44C00` 是 m7322 的值，m7642 本身就不是这个布局。

⟹ 教训：MMIO 地址算错时，读到的往往不是异常而是**平静的 0**；
凡是"读到全零"，先复核地址算术，再怀疑硬件。

## 八、对主线的意义

要跑起 MT7663，需要：

1. DTS 里补 4 个 EHCI 节点（`reg` + GIC 中断号，本页都有）；
2. 给 ehci 加 16 位拼接访问器（约 40 行），基址换成上表；
3. 把 `Titania3_series_start_ehc()` 的 UTMI 序列搬成 glue（源码可读、已确认同构，只需改 UPLL 段）；
4. 提供 MT7663 固件（`linux-firmware` 有 mt7663 的 WiFi/BT 固件）。

工作量估计：**1–2 周**。USB 侧已无未知量，剩下都是写代码：基址表、中断号、访问器、序列，
四样都在本目录两份文档里。

## 九、事故教训（保留）

试过在 `0xFD200000 + 0..0x40000` 按 `0x100` 步长扫 EHCI 签名找第三路 —— **设备当场重启**。
USB 块里有未实现空洞，读到会 external abort，arm64 直接 panic。

⟹ **不要在 MMIO 空间盲扫。** 只读已确认的小窗口，一次一个。
这条代价是电视重启一次（闸门自动恢复、`count=0`，无其它损失）。
