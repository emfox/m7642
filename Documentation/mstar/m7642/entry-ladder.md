# 入口阶梯：一次刷机读出「镜像有没有被进入」和「内核跑到哪」

## 这个实验回答什么

用户的核心问题：**新内核到底有没有执行过一条指令**。
在这之前它一直无法判定，因为屏幕上的东西分不清是 mboot 的 logo 还是我们涂的色。
这个实验把它拆成两个互相独立、各自能读出答案的问题：

1. **bootloader 有没有把控制权交给我们的镜像？**
2. **交过来之后，`primary_entry` 有没有跑起来？**

两个答案都不需要串口、不需要拆机、不依赖猜 GOP 寄存器。

## 先纠正三条此前把方向带偏的判断

| 旧判断 | 实际情况 | 依据 |
|---|---|---|
| 「屏幕看不见，钩子执行了但没显示」 | **屏幕通道是好的**。改 `code1` 指向 `+0x600000` 的那几次，整屏涂出了纯色 | entry2 / dual2 实测，五次一致 |
| 「洋红底 + 竖白条纹是我们的画面」 | 那是 **mboot 自己的 logo**。原厂内核加钩子卡在同一画面 | 2026-11-18 §10:45 |
| 「`0x2d100000` 是 mboot 里写死的显存地址」 | mboot 二进制里**没有**这个常量（4 处命中全是跨字边界假阳性，`mod4=2`）。地址是运行时算的 | `hitcheck.py` 逐处核对 |

由此收敛出的真实结论只有一条：**镜像被进入了，屏幕通道是好的**。
「死在 `primary_entry` 附近」这句**不能**从这些证据里得出来 —— 涂色的是跳板 blob，
`primary_entry` 里一条指令是否执行过，至今仍是零确认（见 `boot-test.md` §10:1x）。

## 镜像

`~/kbuild/m7642-out/m7642-ladder.img`（24,111,104 字节，md5 `635ff73ef8a0b2883a28ec17a8ec2e12`）

三级梯子，每级颜色不同，任何一级跑过都会在面板上留下痕迹：

| 偏移 | 颜色 | 意味着 |
|---|---|---|
| `code1` @ +4 = `b +0x600000`；`+0x600000` 涂 **蓝** `0x001f` | 蓝 | bootloader 按 `code1` 进入镜像 |
| `+0xFA0000` 改成 `b +0xF9FF00`；`+0xF9FF00` 涂 **黄** `0xffe0` | 黄 | bootloader 按 vendor 入口偏移进入镜像 |
| `+0x455038`（`primary_entry`）= `mov w12,#0xffff; bl beacon` | 白→红→绿 | 内核自己跑到哪 |

每个梯级末尾都 `b 0x455038`，所以蓝/黄只说明「进了镜像」，白/红/绿才说明「进了内核」。

### 颜色必须是 16 位 RGB565，且复制到 32 位字的两半

这块 fb 是 **8 MB、每像素一个 32 位字，有效颜色只在低 16 位**（§46 补，
`probe-mainline` 涂 4 MB 露出的半屏条纹是决定性证据）。所以一个颜色要写成
`c | c<<16`，与内核 `m7642_beacon` 的 `and/lsl/orr` 完全一致：

| 颜色 | RGB565 | 写进内存的 32 位字 |
|---|---|---|
| 蓝 | `0x001F` | `0x001F001F` |
| 黄 | `0xFFE0` | `0xFFE0FFE0` |
| 白 | `0xFFFF` | `0xFFFFFFFF` |
| 红 | `0xF800` | `0xF800F800` |
| 绿 | `0x07E0` | `0x07E007E0` |

⚠️ 早先的 `ladder.S` 按 32 位 ARGB 写颜色，实际读数是：**蓝级变成纯黑**
（`0x00FF0000` 的低半字是 `0x0000`）、**黄级变成纯白**（`0x0000FFFF` 的低半字是
`0xFFFF`）。黑会被读成「镜像没被进入」，白会被读成「`primary_entry` 跑到了」——
两个梯级的判读会同时反向。现在改成 `movz`/`movk` 各取 `#COLOUR`：
非 16 位常量直接超出 imm16、**编译期报错**，不会再静默错到屏幕上。

### 这次修掉的三个具体毛病

- **`x0` 被踩**。entry2 的 blob 拿 `x0/x1/x2` 当填充循环寄存器，而 `x0` 是 mboot 传下来的 DTB 指针。
  新 blob 只用 `x7..x19`，`x0..x5` 原样交给 `primary_entry`。
- **`kernel_size` 只有真实 Image 大小**。ramdisk 偏移 = `page + align_up(kernel_size, 4096)`，
  而 mboot 只拷 `kernel_size` 字节。现在 `image_size == kernel_size == 0xFA0100`，覆盖全部梯级。
- **颜色按 32 位 ARGB 写**（见上一节）。这不是配色问题，是**判读会整体反向**的问题。

## 步骤

### 0. 先确认 DDR 会不会保留（零刷机，1 分钟）

后面那条「内存标记」通道依赖它，面板那条不依赖。所以这一步只是为了知道标记可不可信：

```
ADB=~/Debian/tv/adb/platform-tools/adb TV=192.168.10.60:5555 \
  ~/Debian/m7642/tools/host/read-ladder.sh      # 先看没刷之前是空的
```

已知：`sysrq c` panic 后设备自行恢复，`/sys/fs/pstore/console-ramoops` 拿到 576 行完整日志
⟹ **warm reset 一定保留 DDR**。待机会话是否保留未测，标记缺失时按「不确定」处理，不当否定结论。

这一步同时给**标记通道做体检**：`probeRW` 会真去读 `0x43300000`。
读得到（哪怕是旧值/全零）⟹ 这个地址可访问，梯子写它不会出事；
读不到 ⟹ 标记那条通道直接作废，这次只看屏幕。

### 1. 装镜像（只写 recovery 槽，不碰 boot）

```
IMG=~/kbuild/m7642-out/m7642-ladder.img ~/Debian/m7642/tools/host/boottest.sh arm
~/Debian/m7642/tools/host/boottest.sh reboot
```

`boottest.sh` 写 `recovery` 槽 + 设 `BCB=boot-recovery`，**boot 分区不动**，
所以失败也不影响 Android；`disarm` 可还原原厂 recovery 头与 misc 扇区。

- `arm` / `disarm` 2026-11-17 19:2x 实机回归过，写入按镜像长度读回比 md5、
  回滚后整分区逐字节一致。
- **`reboot` 这一步本身从未实跑验证过** —— 「`adb reboot recovery` 会让 mboot 去加载
  recovery 槽」只是按 Android BCB 的常规推的。这是整个流程里唯一没被实测的环节。
  如果 `reboot` 之后又直接进了 Android，说明 BCB 没生效，不是梯子的问题。

按 §45 的结论（入口硬编码 `+0xFA0000`，`code1` 不被读），**这次预期读到的是黄**；
读到蓝反而说明 `code1` 那条路也活着。两者都算成功。

### 2. 看面板（关键读数，设备此时应当是挂住的）

设备不会自己回到 Android。**先看屏幕颜色，不要急着断电**：

| 屏幕 | 结论 |
|---|---|
| **整屏纯蓝** | 进了镜像，`primary_entry` 一条没跑 —— 问题在入口交接的最后一步 |
| **整屏纯黄** | 进了镜像（走的是 `+0xFA0000`），`primary_entry` 一条没跑 |
| 白 | `primary_entry` 跑到了，死在 `record_mmu_state` 前后 |
| 红 | `record_mmu_state` 过了，死在 `preserve_boot_args` 前后 |
| 绿 | `preserve_boot_args` 过了，死在 `create_init_idmap` / `__cpu_setup` 一段 |
| 黑 / mboot logo / 粉底碎条纹 | 镜像没被进入，回到「入口在哪」这个问题 |
| 蓝然后变白/红/绿 | 同对应行，且额外证明两级入口都通 |

⚠️ 两个梯级都是**整屏填充**（`0x7E9000` 字节），所以判据是「整屏纯色」。
半屏、条纹、纯色底上带碎块，都属于「没涂满」或「mboot 后写覆盖」，
按 §47 的竞争结论处理，不要当梯级读数。


### 3. 收尾

```
~/Debian/m7642/tools/host/boottest.sh disarm
```

（设备挂住时先断电，再上电；Android 起来后才能执行 disarm。）

### 4. 可选：读内存标记

Android 正常起来后：

```
~/Debian/m7642/tools/host/read-ladder.sh
```

`word0 = 0x4d373634`（"M764"）说明梯子跑过；`word1` = 1 表示经 `code1`、= 2 表示经 `+0xFA0000`；
`word2` 是 `word1` 的反码，用来排除陈旧值。

两条限制，别把它当主判据：

- 标记写在 `0x43300000`，位于 DT 里两个 memory 节点之间的空洞（`0x41800000..0x54400000`）。
- 设备一旦挂住就必须断电，DDR 随之全丢 ⟹ **只有设备自己回到 Android 时标记才读得到**。
  那时屏上颜色已经没有意义（被内核后面的 beacon 覆盖），标记正好补这一格。

> ⚠️ **2026-11-20 晚：这个地址的读数要小心，但"跨复位保留"本身没被否证。**
> 当晚用 `probeRW op=w` 写已知值 + **`adb reboot`** + 读回，五个 DDR 地址全部丢失，
> 一度误判为"启动覆盖整片 DDR"。**该推论已撤回**：`adb reboot` 进待机 = PM51 **切电** = 硬断电
> （`flash-and-recovery.md` §44 实测），DDR 当然全丢。
> 正确的分类是 **soft reset（WDT / panic）保留 DDR**、`adb reboot` 不保留（`confirmed-facts.md` §G）。
> ⟹ 标记通道**仍然可行**，但要用 WDT 复位去验，且**优先改用 ramoops 签名**
> （`0x42300000` + `sig=0x43474244`，pstore 自动导出成 `/sys/fs/pstore/console-ramoops`，
> 不用 `probeRW`）。见 `wdt-beacon.md` §十。
> 🔴 唯一保留的硬结论：`0x20100000` 是 **mboot 的活动代码区**（写进去的字节重启后变 ARM 指令），
> **绝对不要碰**。

## 构建

```
cd ~/Debian/m7642/probes/ladder
CC=~/kbuild/toolchain-gcc13/bin/aarch64-buildroot-linux-gnu-gcc
OC=~/kbuild/toolchain-gcc13/bin/aarch64-buildroot-linux-gnu-objcopy
$CC -c -DCOLOUR=0x001f -DSTEP=1 -o blue.o ladder.S   && $OC -O binary -j .text blue.o blue.bin
$CC -c -DCOLOUR=0xffe0 -DSTEP=2 -o yellow.o ladder.S && $OC -O binary -j .text yellow.o yellow.bin
cd ~/Debian/m7642 && python3 tools/host/mk-ladder.py
```

两个 blob 都应是 **168 字节**，`0x4c/0x50` 两字应是 `528003ef 72a003ef`（蓝）/
`529ffc0f 72bffc0f`（黄）。传 32 位颜色会直接编译失败，这是有意的。

`mk-ladder.py` 会自己断言：`code1`→`+0x600000`、`+0xFA0000`→`+0xF9FF00`、两个 blob 末尾都跳到
`primary_entry`、`image_size == kernel_size`、除三个梯级外没有别的字节被改。

## 静态复验（不刷机也能跑）

`tools/host/verify-ladder.py` 只读打包好的 `.img`，按 bootloader 看到的字节复核：

```
ladder  : 24111104 bytes  md5 635ff73ef8a0b2883a28ec17a8ec2e12
[outer header] page=0x800
  仅 +0x9..+0xb 三字节不同      ⟹ 只改了 kernel_size 0xfa0100（原 0x12d4a00）
[arm64 header] code0 0xfa405a4d  code1 0x1417ffff (b 0x600000)
  text_offset 0x0  image_size 0xfa0100
[rungs]
  blue   @ +0x600000  movz w15,#0x1f / movk w15,#0x1f,lsl16  末尾 -> +0x455038
  yellow @ +0xf9ff00  movz w15,#0xffe0 / movk w15,#0xffe0,lsl16  末尾 -> +0x455038
  +0xfa0000  b 0xf9ff00
[primary_entry @ +0x455038]  mov w12,#0xffff @ 0x455038 / #0xf800 @ 0x455044 / #0x07e0 @ 0x455050
[diff vs padded source Image]  29 段连续差异、共 319 字节、0 字节落在梯级之外
[ramdisk] 7721457 bytes  原厂 0x12d5800 -> 本镜像 0xfa1000  逐字节相同
```

319 比 317 多 2 字节，是因为新颜色恰好有两个字节与原始 Image 相同、不计入差异，
不是多改了东西 —— 「梯级之外 0 字节」那条断言才是判据。


## 静态核对过的地址常量

`tools/host/hitcheck.py` 判据：真实地址常量一定是 4 字节对齐；非对齐命中必然是跨字边界假阳性。

```
0x2d100000  4 处命中，全部 mod4=2  ⟹ 不是常量（都是 0x322d10 / 0x276b2d10 这类 16 位表项拼接）
0x2e100000  1 处命中，mod4=2      ⟹ 不是常量
0xFA0000    1 处命中，mod4=2      ⟹ 不是常量（入口偏移来自镜像，不是 mboot 写死）
0x1f240000 段  有 0x1f242a00 ×21 等常量 ⟹ GOP 基址确为 0x1f240000，组合地址靠 base+offset 运行时算
```

顺带确认 mboot 真实编进去的取证相关命令（usage 字符串实测在二进制里）：
`draw_rect x y w h color`、`osd_create w h`、`osd_flush`、`draw_pixel`、`draw_string`、`draw_progress`、
`fatwrite <if> <dev> <addr> <file> [bytes]`（内存→U 盘）、`spi2usb [off] [len] [file]`（SPI→U 盘）、`delay <ms>`。
