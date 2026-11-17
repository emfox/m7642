# UART

**结论：不需要写任何驱动。** 这是标准 8250，只是寄存器步距是 8 字节。
主线 `8250_of` 认 `ns16550a` 且支持 `reg-shift`/`reg-io-width`，加一个 DT 节点即可。

## 一、基址

三个独立来源互相印证：

| 来源 | 值 |
|---|---|
| `m7642arm/…/arch/arm/mach-m7642/chip_early_printk.c:84` | `/* UART 0 : base + 0x1f201300 */` |
| 同上 `#define UART_REG(addr)` | `*(volatile u32 *)(0xfd201300UL + ((addr) << 3))` |
| `arch/arm/mach-m7642/chip_arch.c:431-450` | `s.iobase = 0xFD201300; s.irq = E_IRQ_UART0; s.uartclk = 123000000;` |

物理 `0x1F201300`（`0xFD201300` 是同一地址在 32 位 IO 映射里的别名，见
`chip_early_printk.c` 的注释 `1F000000 => FD000000`）。

同一份源码还给了另外两路，暂时用不上：

```
UART 1 : base + 0x1f220c00   uartclk 108 MHz  E_IRQEXPL_UART1
UART 2 : base + 0x1f220d00   uartclk 123 MHz  E_IRQEXPH_UART2MCU
```

## 二、寄存器步距

厂商把 8250 的寄存器偏移整体翻倍，再在访问时左移两位：

```c
/* drivers/tty/serial/8250/8250.h */
#define MSTAR_UART_IER  (0x02)   /* 标准 8250 是 0x01 */
#define MSTAR_UART_LCR  (0x06)   /* 0x03 */
#define MSTAR_UART_LSR  (0x0A)   /* 0x05 */
#define MSTAR_UART_USR  (0x0E)   /* 0x07 位置，但物理上是 DW 的 USR 不是 SCR */

#define UART_REG(iobase, addr) *((volatile unsigned int *)(iobase + ((addr) << 2)))
```

`addr << 2` 作用在已经翻倍的偏移上，净值就是 **寄存器 N 位于字节偏移 N × 8**：

| 寄存器 | 字节偏移 | 8250 编号 |
|---|---|---|
| RBR / THR / DLL | 0x00 | 0 |
| IER / DLM | 0x08 | 1 |
| IIR / FCR | 0x10 | 2 |
| LCR | 0x18 | 3 |
| MCR | 0x20 | 4 |
| LSR | 0x28 | 5 |
| MSR | 0x30 | 6 |
| USR | 0x38 | 7 |

`chip_early_printk.c` 里 `UART_LSR` 定义为 5、`UART_USR` 定义为 7，访问一律 `<< 3`，
与上表完全一致 —— 这是最直接的一组证据。

所以主线只需要：

```dts
uart0: serial@1f201300 {
	compatible = "ns16550a";
	reg = <0x0 0x1f201300 0x0 0x100>;
	clock-frequency = <123000000>;
	reg-shift = <3>;	/* 2^3 = 8 */
	reg-io-width = <4>;
	interrupts = <GIC_SPI 0 IRQ_TYPE_LEVEL_HIGH>;
};
```

## 三、中断号

`arch/arm/mach-m7642/chip_int.h:217`：`E_IRQ_UART0 = E_IRQL_START + 0`，即第一路私有中断线。
活体 DT 的 `uart0` 节点也写 `<0 0x0 0x4>` —— GIC 三元组里 `0` 是 SPI，编号 0。
两处一致 ⟹ **SPI 0，Linux 中断号 32**。

## 四、活体验证（2026-11-17 16:50，比源码证据更硬）

### 1. 端口参数——`/proc/tty/driver/serial` 直接给出

```
serinfo:1.0 driver revision:
0: uart:16550 port:FFFFFF800A201300 irq:32 tx:288 rx:0 RTS|CTS|DTR
1: uart:16550 port:FFFFFF800A220C00 irq:71 tx:6 rx:42 CTS
2: uart:16550 port:FFFFFF800A220D00 irq:82 tx:0 rx:0 CTS
```

- `port:FFFFFF800A201300` → 物理 **0x1F201300**，与上表一致；
- `irq:32` → SPI 0，与 `E_IRQ_UART0` 和活体 DT 三方一致；
- `tx:288` → 控制台确实在往外写字（不是"配好了但没通"）；
- UART1/UART2 的地址 `0x1F220C00`/`0x1F220D00` 也与 `chip_early_printk.c` 的两行注释逐字对上
  ⟹ 那棵 32 位树对这颗芯片是可信的。

### 2. 寄存器步距——直接读现场值

读 `0x1F201320..0x1F20133F`（探针模块，32 位对齐读）：

```
+0x20: 0f 00 00 00  0f 00 00 00      MCR = 0x0f  (DTR|RTS|OUT1|OUT2)
+0x28: 60 00 00 00  60 00 00 00      LSR = 0x60  (THRE|TEMT)
+0x30: 10 00 00 00  10 00 00 00      MSR = 0x10  (CTS)
+0x38: 06 00 00 00  06 00 00 00      USR = 0x06  (TX FIFO 空)
```

三条独立自洽：LSR 的 `THRE|TEMT` 是空闲发送器的必然值；MSR 的 `CTS` 与上面
`/proc/tty/driver/serial` 报告的 `RTS|CTS|DTR` 对得上；MCR 的 `DTR|RTS` 也是同一组。

⟹ **寄存器 N 位于字节偏移 N×8，32 位可读**，即 `reg-shift = <3>` + `reg-io-width = <4>` 成立。
注意同一个值在 `+X` 和 `+X+4` 都出现（地址译码忽略 bit2），所以 32 位读不会读到拼接垃圾。

## 五、哪个口才是"调试口"：mboot 用 ttyS2

从 `mboot.bin` 内置 env 里读到的：

```
console=ttyS2,115200n8
baudrate=115200
```

而厂商 Android 内核的 cmdline 是 `console=ttyS0`。设备上三个口实际并存：

```
0: uart:16550 port:FFFFFF800A201300 irq:32    <- Android 内核打日志
1: uart:16550 port:FFFFFF800A220C00 irq:71
2: uart:16550 port:FFFFFF800A220D00 irq:82    <- mboot 打日志
```

⟹ **接串口调试时两个口都要开**：从上电到内核接管之间，只有 ttyS2 有输出；
内核起来之后才轮到 ttyS0。只接 ttyS0 会看到"mboot 阶段一片空白"，很容易误判成
"串口没通"或"板子没启动"。

在 DTS 上就是 `serial0`（`0x1F201300`）与 `serial2`（`0x1F220D00`）都 `status = "okay"`，
cmdline 写 `console=ttyS0,115200 earlycon console=ttyS2,115200` —— 两个都收，
哪个有输出都不会漏。

## 六、两个已知风险

1. **分频器写入需要等 USR 空闲。** 厂商在 `8250_port.c` 里重写了写除数的那一段：
   先置 MCR 环回，然后轮询 `USR` 的 busy/rx_busy 位最多 10 次，再写 LCR.DLAB 并回读确认。
   这是对有硅缺陷的 UART 的规避。主线直接写 DLL/DLM 有可能偶发失败。
   **先按无 quirk 试**，如果出现设置波特率后输出错乱，再补一个 `8250_mstar` 的
   `set_termios` 钩子 —— 那份厂商代码逻辑可以逐行照抄。
2. **`USR` 不是标准 8250 的 SCR。** 主线不会读写 SCR，所以正常路径无关；
   但 `no-loopback-test` 可能需要加上，因为标准环回自检依赖 SCR。

## 七、DTS 校验记录

`arch/arm64/boot/dts/mstar/` 下的两个 DTS 已用内核自带 `scripts/dtc` 编译通过：

```
cpp -nostdinc -I include -I arch/arm64/boot/dts -undef -D__DTS__ \
	-x assembler-with-cpp -o m.dts m7642-tcl-65s535d.dts
scripts/dtc/dtc -I dts -O dtb -o m.dtb m.dts      # 无 warning
```
