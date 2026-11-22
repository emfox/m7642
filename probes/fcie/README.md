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
./build.sh bare    # → ~/kbuild/fcie-build/fcie_read.o (896 B) + fcie_probe.o (88 B)
./build.sh ko      # → ~/kbuild/fcie-build/fcie.ko（走 ~/kbuild/build-probe.sh）
./build-boot.sh    # → ~/kbuild/m7642-out/m7642-rec-73-emmc.img + fcie_boot.bin
```

`bare` 用的编译参数是 `-O2 -march=armv8-a -mgeneral-regs-only -ffreestanding
-fno-builtin -fno-stack-protector -fno-pic -fno-asynchronous-unwind-tables`。
产物 **0 data / 0 bss / 0 重定位 / 0 未定义符号**，可以整段拷到任意物理页执行。
`fcie_boot.elf` 链接后 1136 B，`_start`@0 / `fcie_probe_once`@0x90 / `fcie_read_block`@0xf0。

## 跑模块（安全，纯读）

```sh
adb push ~/kbuild/fcie-build/fcie.ko /data/local/tmp/
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
md5sum ~/kbuild/m7642-out/m7642-rec-73-emmc.img      # 12c117c1b0b642e7aec1bdfd97d75282
./run-cmd17.sh ~/kbuild/m7642-out/m7642-rec-73-emmc.img 12c117c1b0b642e7aec1bdfd97d75282
```

`run-cmd17.sh` 起 Android 后读三处，并和内核自己
`dd if=/dev/block/mmcblk0 bs=512 count=1` **逐字节对比** —— 一致才算 CMD17 读通道成立。

仍然只读：`LBA=0`，没有任何 CMD24/CMD25/CMD38。失败码在原来的 0xE1–0xE8 之外多了
**0xE9**（事件位 1 s 内没清掉）。所有等待都是**双上限**（`CNTPCT` 截止 + 2e9 次迭代
`SPIN_CAP`）：即使系统计数器停走，也只是返回错误码而不是静默死等。
**探测器挂住 = 一次物理断电**（boot 槽是厂值，断电后正常起 Android；卡只被读过，不会坏）。

### 2026-11-22 07:43 第一次上机：NO_RETURN

489 s 无 Android、设备挂死（需物理断电）。失败是盲的，所以先跑两张更小的诊断镜像：

| 镜像 | md5 | 做什么 |
|---|---|---|
| `m7642-rec-73-ctl.img` | `097140f576ef6e34b467b66ced09ab59` | code1 只写记录 + 交接，**完全不碰 eMMC**（对照：证明这套镜像布局的交接没问题） |
| `m7642-rec-73-regs.img` | `a2e76b787061b803c56bccc96686c973` | code1 **只读** 34 个 FCIE + 2 个 PLL 寄存器（不写、不发命令），存到 `0x23090000 + idx*4` / `0x23090400`，标记在 `0x23090800` |

```sh
cd ~/Debian/m7642/probes/fcie
./build-extra.sh                                   # 重建 ctl + regs
~/Debian/m7642/probes/handoff/run-rung.sh ~/kbuild/m7642-out/m7642-rec-73-ctl.img 097140f576ef6e34b467b66ced09ab59 0x4
./run-regs.sh ~/kbuild/m7642-out/m7642-rec-73-regs.img a2e76b787061b803c56bccc96686c973
```

判读：ctl 回来 ⟹ 交接没问题；regs 回来 ⟹ code1 能安全读 FCIE（并把 mboot 刚用完
eMMC 时的寄存器状态带回来）；两者都回来而全量 CMD17 仍挂 ⟹ 挂点在写寄存器 / 命令 /
DMA 这一段，再按 §32.3 的 18 步逐段切。

成功后的判据（三档）：

- 实测：心跳 `rc=0`、`R1` 的 CURRENT_STATE=4 且 READY_FOR_DATA=1、512 B 与内核 `dd` 的
  LBA0 完全一致 ⟹ CMD17 读通道成立；
- 对照：`rc=0` 但内容不一致 ⟹ DMA 落点/MIU 地址有问题（§32.4）；
- 失败：看 `rc` + 心跳里的 `R1`/`SD_STATUS` 定位（0xE2 = FCIE 归 NAND、0xE3 = DAT0 超时…）。

## 不要做的事

- 不要写 `RST`(0x3F)、`EMMC_PLL`、`PAD_CHIPTOP`、`CLKGEN` —— 全芯片级，改了会影响
  正在跑的 Android。
- 不要连读整个 0x00–0x7F 窗口（有空洞）。
- 不要用字节读/`kernel_write` 搬 8 字节去读 16 位寄存器；要用 `ldrh`（模块里就是
  `*(volatile u16 *)`）。
- **没有任何写 eMMC 的代码**，也不许加。写路径（CMD24/CMD25）继续冻结。
