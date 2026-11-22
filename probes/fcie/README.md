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
| `emmc_read.S` | **boot-path 入口**：钉在 `code1`，设栈 → `fcie_probe_once(0)` → 记录 → 交接厂内核 | ❌ 已构建，未上机 |
| `build.sh` | `bare` / `ko` / `all` | ✅ |
| `build-boot.sh` | 把 `emmc_read.S` + 两个 bare 目标链接成一个 blob，并包成 recovery 槽镜像 | ✅ 离线构建通过 |
| `run-cmd17.sh` | 上机跑 CMD17 镜像，读回 512 B / 心跳 / 记录，并和内核 `dd` 的 LBA0 对比 | ❌ 未上机 |
| `regs-reference.txt` | 2026-11-22 00:30 的 34+2 个寄存器参考值（含「易变」标注） | — |
| `check-dump.sh` | 把 `fcie.out` 与参考值对比：易变项只报 INFO，稳定项必须逐位相同 | ✅ 离线测过 |
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
./build.sh bare    # → ~/Debian/m7642-build/build/fcie-build/fcie_read.o (896 B) + fcie_probe.o (88 B)
./build.sh ko      # → ~/Debian/m7642-build/build/fcie-build/fcie.ko（走 ~/Debian/m7642-build/scripts/build-probe.sh）
./build-boot.sh    # → ~/Debian/m7642-build/out/m7642-rec-73-emmc.img + fcie_boot.bin
```

`bare` 用的编译参数是 `-O2 -march=armv8-a -mgeneral-regs-only -ffreestanding
-fno-builtin -fno-stack-protector -fno-pic -fno-asynchronous-unwind-tables`。
产物 **0 data / 0 bss / 0 重定位 / 0 未定义符号**，可以整段拷到任意物理页执行。
`fcie_boot.elf` 链接后 1136 B，`_start`@0 / `fcie_probe_once`@0x90 / `fcie_read_block`@0xf0。

## 跑模块（安全，纯读）

```sh
adb push ~/Debian/m7642-build/build/fcie-build/fcie.ko /data/local/tmp/
adb shell su -c 'busybox rmmod fcie 2>/dev/null; /vendor/bin/busybox insmod /data/local/tmp/fcie.ko; rmmod fcie; cat /data/local/tmp/fcie.out'
```

这台 ROM 上 `module_init` 不会执行，所有动作在 `module_exit`（`rmmod` 触发）。
`insmod` 必须用 `/vendor/bin/busybox` 的。

复核读数：

```sh
adb exec-out su -c "cat /data/local/tmp/fcie.out" > /tmp/fcie.out
./check-dump.sh /tmp/fcie.out      # 期望 checked 36, diff 0, missing 0
```

## 跑 CMD17（**boot-path 版已就绪，未上机**）

上机入口不再从 Android 里跑（那等于绕过块层直接动一个正在被使用的控制器），
而是钉在 **`code1`**：mboot 刚用 `mmc read.p` 读完 dtb / recovery / stage，
控制器空闲、卡在 TRAN，7.3 还没碰过它 —— 这是最安静的时机。`emmc_read.S` 做的事：

```
设 sp=0x230b0000 → x0=0 (LBA 0) → bl fcie_probe_once
→ 数据落在 PA 0x23080000（512 B）
→ 心跳 0x23080FE0: +0x00 0x4643494531（"FCIE1" 的 LE u64）, +0x08 返回码,
                    +0x10 R1, +0x18 SD_STATUS
→ 记录 0x23090000: "M764"/"EMMC" + 返回码
→ 拷贝预读厂内核（0x30000800→0x20280000）、清 x3/x4、跳 0x21220000（Android 起来）
```

```sh
cd ~/Debian/m7642/probes/fcie
./build-boot.sh
md5sum ~/Debian/m7642-build/out/m7642-rec-73-emmc.img      # a4479e336f3b4b4ac7fa5ca1aad46887
./run-cmd17.sh ~/Debian/m7642-build/out/m7642-rec-73-emmc.img a4479e336f3b4b4ac7fa5ca1aad46887
```

`run-cmd17.sh` 起 Android 后读三处，并和内核自己
`dd if=/dev/block/mmcblk0 bs=512 count=1` **逐字节对比** —— 一致才算 CMD17 读通道成立。

仍然只读：`LBA=0`，没有任何 CMD24/CMD25/CMD38。失败码在原来的 0xE1–0xE8 之外多了
**0xE9**（事件位 1 s 内没清掉）。所有等待都是**双上限**（`CNTPCT` 截止 + 2e9 次迭代
`SPIN_CAP`）：即使系统计数器停走，也只是返回错误码而不是静默死等。
**探测器挂住 = 一次物理断电**（boot 槽是厂值，断电后正常起 Android；卡只被读过，不会坏）。

### 2026-11-22 10:00 结果：CMD17 读通道成立

四级诊断全部跑过（每发都用 misc 末尾 `0xA5` 标记确认真的进了 recovery）：

| 级别 | 镜像 md5 | 结果 |
|---|---|---|
| ctl（不碰 eMMC，记录+交接） | `097140f5…` | REACHED |
| regs（只读 34+2 个寄存器） | `a2e76b78…` | RETURNED，code1 寄存器全表见 confirmed-facts §32.8 |
| 单写 wr1 / wt1 / wt2 / wt3 / wt4 / wt5 | 见 git 历史 | 全部 RETURNED（JOB_BL_CNT、FUNC_CTL、SD_MODE、SD_STATUS 读、清事件/清错误、DMA 寄存器组） |
| clk（定时器） | `466d5d61…` | RETURNED：CNTFRQ=12 MHz、CNTPCT 在跑、EL2、cache 关 |
| cpa / cpb（C 路径的栈 / 心跳地址） | 见 git 历史 | RETURNED |
| **cpath**（C 路径、零 MMIO） | `484e1a01…` | 修复后 RETURNED |
| **setup**（只写寄存器，不起命令） | `2c1d230a…` | 修复后 RETURNED |
| **全量 CMD17** | `9f071ae8…` | **RETURNED，rc=0，数据与内核 `dd` 逐字节相同** |

**之前连续挂死的根因**：C 代码按 ABI 冲掉了 `x0..x5`，而厂内核入口会把 **`w2`** 存进它的
`boot_args[2]`。纯汇编桩从不碰它们，所以「凡是 C 路径就挂、凡是汇编就过」。修法：
`emmc_read.S` 入口保存 `x0..x5`，交接前恢复（`x3/x4` 清 0、`sp` 回 0）。

成功读数：`rc=0`、`R1=0x900`（CURRENT_STATE=4/READY_FOR_DATA=1）、`SD_STATUS=0xff00`、
512 B 与内核 `dd if=/dev/block/mmcblk0 bs=512 count=1` 完全一致（md5 `ce6a9730…`）。

```sh
cd ~/Debian/m7642/probes/fcie
./build-boot.sh
./run-cmd17.sh ~/Debian/m7642-build/out/m7642-rec-73-emmc.img 9f071ae8ff512a1843396e8849633531
```

写路径（CMD24/CMD25）仍未做，继续冻结。

## 不要做的事

- 不要写 `RST`(0x3F)、`EMMC_PLL`、`PAD_CHIPTOP`、`CLKGEN` —— 全芯片级，改了会影响
  正在跑的 Android。
- 不要连读整个 0x00–0x7F 窗口（有空洞）。
- 不要用字节读/`kernel_write` 搬 8 字节去读 16 位寄存器；要用 `ldrh`（模块里就是
  `*(volatile u16 *)`）。
- **没有任何写 eMMC 的代码**，也不许加。写路径（CMD24/CMD25）继续冻结。
