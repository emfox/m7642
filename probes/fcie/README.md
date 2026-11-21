# probes/fcie — MStar FCIE eMMC 控制器：只读探针

逆向结论、寄存器全表、CMD17 逐条序列都在
[`confirmed-facts.md` §32](../../Documentation/mstar/m7642/confirmed-facts.md)，
这里只放代码和「怎么用」。

## 文件

| 文件 | 是什么 | 跑过吗 |
|---|---|---|
| `fcie.c` | **内核模块**：只读 FCIE0 + EMMC_PLL 的 34 个寄存器，写 `/data/local/tmp/fcie.out` | ✅ 2026-11-22 在设备上跑过，安全 |
| `fcie_read.c` | **freestanding C**：一次 CMD17 读 512 B，无 libc / 无全局 / 无重定位 | ❌ 没有在设备上执行过 |
| `fcie_probe.c` | 裸机入口：`fcie_probe_once(lba)` → 数据到物理 `0x23080000`，心跳到 `0x23080FE0` | ❌ 同上 |
| `build.sh` | `bare` / `ko` / `all` | ✅ |
| `dumps/` | 厂商函数机器码快照 + 运行时地址表 | — |

## 关键地址（实测，见 §32.1）

```
mstar_pm_base = 0xffffff800a000000        = ioremap(0x1F000000, 0xA00000)
FCIE0         = mstar_pm_base + 0x222600  → PA 0x1F222600 / VA 0xffffff800a222600
EMMC_PLL      = mstar_pm_base + 0x247E00  → PA 0x1F247E00 / VA 0xffffff800a247e00
命令 FIFO     = FCIE0 + 0x80 (9 × 16 bit)
```

寄存器是 **16 位宽、4 字节步进**：`addr = base + (idx << 2)`。
**空洞**：idx `0x19–0x28`、`0x2A–0x33`、`0x3A–0x3E`、`0x40–0x62` —— 读到就是 external abort。

## 构建

```sh
cd ~/Debian/m7642/probes/fcie
./build.sh bare    # → ~/kbuild/fcie-build/fcie_read.o (848 B) + fcie_probe.o (88 B)
./build.sh ko      # → ~/kbuild/fcie-build/fcie.ko（走 ~/kbuild/build-probe.sh）
```

`bare` 用的编译参数是 `-O2 -march=armv8-a -mgeneral-regs-only -ffreestanding
-fno-builtin -fno-stack-protector -fno-pic -fno-asynchronous-unwind-tables`。
产物 **0 data / 0 bss / 0 重定位 / 0 未定义符号**，可以整段拷到任意物理页执行。

## 跑模块（安全，纯读）

```sh
adb push ~/kbuild/fcie-build/fcie.ko /data/local/tmp/
adb shell su -c '/vendor/bin/busybox insmod /data/local/tmp/fcie.ko; rmmod fcie; cat /data/local/tmp/fcie.out'
```

这台 ROM 上 `module_init` 不会执行，所有动作在 `module_exit`（`rmmod` 触发）。
`insmod` 必须用 `/vendor/bin/busybox` 的。

## 跑 CMD17（**现在不要跑**）

`fcie_read_block()` 从 mboot 初始化完的状态出发，只做：

```
FUNC_CTL |= 0x1002 → SD_MODE |= 1 → 等 DAT0 高 → 清事件/错误
→ JOB_BL_CNT=1, BLK_SIZE=512, DMA_LEN=512, DMA_ADDR=目标−0x20000000, MIU0
→ CMD_RSP_SIZE |= 5 → SD_MODE=mode → CMDFIFO[0..2]=CMD17/LBA
→ 等 DAT0 高 → SD_CTRL=0x020E|0x40 → 等 CMD_END → 读 R1 → 等 DMA_END
→ 查 SD_STATUS → 清事件、关时钟
```

**但它在 Android 运行中等于绕过 mmc 块层直接动控制器。一次读大概率没事，
我们没有证据，所以没跑。** 要跑请先满足：

1. 目标控制器不是正在被读写（`/data` 停掉，或者在 recovery / 探针上下文里）；
2. 只读 `lba=0`（user 区第一个扇区，读不改任何东西）；
3. 先看 R1 里的 CURRENT_STATE（应该 ≥ 4 = TRAN/DATA），不对就当场停。

裸机接线（`abort-postmmu.S` 那套：MMU/Cache 关、物理寻址）：

```
x0 = 0x1F222600     ; FCIE0 物理基址
x1 = <LBA>
x2 = 0x23080000     ; 目标物理地址（MIU 地址 0x03080000）
x3 = 0 或 u64 diag[4] 的地址
blr fcie_probe_once
; 回来之后：0x23080000 起 512 B 是块数据
;           0x23080FE0 = "FCIE1", +8 返回码, +0x10 R1, +0x18 SD_STATUS
```

返回码：`0` 成功；`0xE1` 目标不在 MIU0；`0xE2` FCIE 归 NAND；`0xE3` DAT0 超时；
`0xE4` CMD_END 超时；`0xE5` 命令后状态错；`0xE6` DMA_END 超时；`0xE7` DMA 后状态错；
`0xE8` R1 报错。超时全部用 `CNTPCT_EL0`（12 MHz），不是空转常数。

## 不要做的事

- 不要写 `RST`(0x3F)、`EMMC_PLL`、`PAD_CHIPTOP`、`CLKGEN` —— 全芯片级，改了会影响
  正在跑的 Android。
- 不要连读整个 0x00–0x7F 窗口（有空洞）。
- 不要用字节读/`kernel_write` 搬 8 字节去读 16 位寄存器；要用 `ldrh`（模块里就是
  `*(volatile u16 *)`）。
- **没有任何写 eMMC 的代码**，也不许加。
