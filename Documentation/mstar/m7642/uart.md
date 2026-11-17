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

## 四、两个已知风险

1. **分频器写入需要等 USR 空闲。** 厂商在 `8250_port.c` 里重写了写除数的那一段：
   先置 MCR 环回，然后轮询 `USR` 的 busy/rx_busy 位最多 10 次，再写 LCR.DLAB 并回读确认。
   这是对有硅缺陷的 UART 的规避。主线直接写 DLL/DLM 有可能偶发失败。
   **先按无 quirk 试**，如果出现设置波特率后输出错乱，再补一个 `8250_mstar` 的
   `set_termios` 钩子 —— 那份厂商代码逻辑可以逐行照抄。
2. **`USR` 不是标准 8250 的 SCR。** 主线不会读写 SCR，所以正常路径无关；
   但 `no-loopback-test` 可能需要加上，因为标准环回自检依赖 SCR。

## 五、验证记录

`arch/arm64/boot/dts/mstar/` 下的两个 DTS 已用内核自带 `scripts/dtc` 编译通过：

```
cpp -nostdinc -I include -I arch/arm64/boot/dts -undef -D__DTS__ \
	-x assembler-with-cpp -o m.dts m7642-tcl-65s535d.dts
scripts/dtc/dtc -I dts -O dtb -o m.dtb m.dts      # 无 warning
```
