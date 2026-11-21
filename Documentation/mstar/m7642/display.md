# 在线读取 m7642 显示寄存器：方法与实测数据

日期 2026-11-17。目标：不刷机、不重启、不插 U 盘，从运行中的厂商内核里把显示子系统的真实数据读出来。

## 一、先说结论

做到了。现在有一个可用的「显示寄存器读取器」，能在真机上读出 GOP 的实时寄存器值，
而且读到的几何值精确对上当前分辨率：

| 位置 | 值 | 含义 |
|---|---|---|
| bank 1, off 5 | `0x0780` = **1920** | 画面宽度 |
| bank 1, off 8 | `0x0438` = **1080** | 画面高度 |
| bank 1, off 9 | `0x0780` = **1920** | 行跨距 / 另一路宽度 |
| bank 1, off 1 | `0x2000` = 8192 | 行缓冲或对齐后的 stride |
| bank 0, off 18/19 | `0x3fff` / `0x0fff` | 4095 层级掩码类值 |

64 个寄存器中 44 个非零，说明读到的是活的硬件，不是一块空内存。

## 二、过程中撞到的真正障碍：`module_init` 从不执行

这一条推翻了上一轮「L1 已打通」的结论，必须更正。

现象：任何模块 `insmod` 都返回 0、`/proc/modules` 里是 `Live`，
但模块里的 `printk` 从不进 dmesg，`filp_open` 也不创建文件——**代码根本没跑**。

一比特判定：让 `module_init` 直接 `return -EIO`，模块依然是 `Live`（这个 ROM 的加载器
忽略了 init 的返回值，所以返回值不能当信号）。真正的证据在 ELF 里：

| 项 | 我们的模块 | 厂商模块（devnode.ko） |
|---|---|---|
| `.gnu.linkonce.this_module` | 0x300 | 0x300 |
| `mod->init` 重定位偏移 | **0x158** | **0x160** |
| `mod->exit` 重定位偏移 | 0x2e8 | 0x2e8 |

`struct module` 的布局差了 8 字节。内核在 0x160 读到的是 NULL，于是 `do_init_module()`
直接跳过初始化，模块照样挂进链表显示为 Live。

我们实测自己这份头文件算出来的偏移是 `init=344 (0x158) exit=744 (0x2e8) size=768`，
总大小与厂商一致、`exit` 位置也一致，只有 `init` 前少 8 字节、`init` 后多 8 字节。
配置里 `CONFIG_MODULE_SIG` 与 `CONFIG_UNUSED_SYMBOLS` 两边都是关闭的，
说明差别来自 TCL 私有树对 `struct module` 的改动，不是我们能靠改 config 对齐的。

### 规避办法（已验证）

**把探针代码放进 `module_exit`，用 `rmmod` 触发。** `exit` 的偏移恰好是对的。

```sh
/vendor/bin/busybox insmod /data/local/tmp/probe.ko   # init 空转
/system/bin/rmmod probe                               # 真正执行探针
```

注意工具选择（上一轮踩过）：`busybox insmod` 正常、`toybox insmod` 会让内核自旋；
`rmmod` 正好相反，必须用 toybox 的 `/system/bin/rmmod`。

## 三、输出通道

`printk` 完全不可用：`console=ttyS0,115200` 而串口没有对端，且模块的 printk 连
dmesg 都没进。改用内核里直接写文件：

```c
f = filp_open(path, O_WRONLY | O_CREAT | O_TRUNC, 0644);
kernel_write(f, buf, len, pos);   /* 4.9 的第 4 个参数是 loff_t，不是指针 */
filp_close(f, NULL);
```

`filp_open` / `kernel_write` 都是导出符号，CRC 与设备一致。
生成的文件是 0600 root，取回前要 `chmod 644`。

## 四、符号解析的能力边界

`kallsyms_lookup_name` 是导出的（CRC `e007de41`），可以解析任意**函数**符号：

```
_stext                    = ffffff8008082000
MDrv_SYS_RegOP            = ffffff8008896550
MHal_GFLIP_ReadGopReg     = ffffff80088f0d60
MHal_GFLIP_WriteGopReg    = ffffff80088f0cfc
```

但 `iomem_resource`、`mstar_fb_fix`、`memstart_addr` 这些**数据**符号全部返回 0，
原因是 `# CONFIG_KALLSYMS_ALL is not set` —— kallsyms 里只收 text 段符号。
要拿数据符号的地址只能靠反汇编：把函数机器码读出来，解码其中的 `adrp` + `ldr`。

`/proc/iomem` 用全能力 root 读出来只有这些：

```
20200000-417fffff : System RAM
  20280000-2121ffff : Kernel code
  213a0000-217d0fff : Kernel data
41900000-419bffff : persistent_ram ×4
54400000-9d9fffff : System RAM
180000000-1bfffffff : System RAM
ffffff800a340000-ffffff800a343fff : mali.0
```

**MStar 的外设没有注册到 iomem**，全部是硬编码地址，所以这条路拿不到任何外设基址。

## 五、`mstar_pm_base` 与 RIU 窗口

反汇编 `MDrv_SYS_RegOP` 得到这个模式（arm64 分支）：

```
adrp x1, page
ldr  x1, [x1, #72]          ; mstar_pm_base
add  x1, x1, #0x800, lsl #12 ; + 0x800000
```

解码 `adrp` 得到变量地址 `0xffffff8009358048`，读出来的值是：

```
mstar_pm_base = 0xffffff800a000000
RIU 窗口      = 0xffffff800a800000
```

这个地址落在 `0xffffff800a340000`（mali.0 的 ioremap 区）附近，属于 vmalloc/ioremap 区，
不像线性映射，所以确实是设备映射。

**但直接按 m7322 的偏移去读是错的。** 以 `REG_GOP_BASE = 0x20200`（来自 `hal/m7322/gflip/mhal_gflip_reg.h`）
为起点读 64 个字，全部为 0；`ioremap(0x2D100000)` 也直接失败。这说明 m7642 的
GOP 偏移与 m7322 不同——公开树里没有 m7642 的寄存器表，正是这个原因。

## 六、正确做法：直接调用厂商自己的访问函数

既然内核里就有厂商编译好的访问器，就不要自己猜地址。从反汇编解出签名：

```
MHal_GFLIP_ReadGopReg(u8 idx, u16 bank, u16 offset, u16 *out)
```

参数依据：函数开头 `cmp w19, #2; b.hi <清零点>`（idx 上限 2）、
`uxth w20, w1` / `uxth w21, w2`（bank/offset 是 16 位）、
错误路径 `strh wzr, [x3]`（第 4 个参数是 u16 输出指针）。

调用后立刻拿到真实数据（idx 0，bank 0..3，offset 0..15）：

```
-- bank 0 --             -- bank 1 --             -- bank 3 --
00: 4018                00: 4051                00: c008
01: 0002                01: 2000                01: 4002
02: 0018                02: 2f9a                02: 0000
05: 0000                05: 0780  <- 1920        03: 3a07
08: 00ba                08: 0438  <- 1080        04: 9814
09: 0806                09: 0780  <- 1920        05: 80ff
12: 3fff                10: 80ff                08: 40be
13: 0fff                                       12: 3fff
15: 011c                                       15: 0116
```

bank 2 是 8 个值的两遍重复（`fc 88 f2 75 1b fe f7 49`），像色彩键或调色板。

安全边界：这一整轮只做了 MMIO **读**，设备全程存活（`/proc/uptime` 连续，闸门未受影响）。
读错地址在这个 SoC 上不会挂总线，只有写寄存器才危险。

## 七、可复现的流程

```sh
# 1. 构建（设备原始 .config + 合成的 Module.symvers）
CROSS=$HOME/kbuild/aarch64--glibc--stable-2018.11-1/bin/aarch64-linux-
make -s -C kernel_mstar-main O=$PWD/modtest2/out ARCH=arm64 CROSS_COMPILE=$CROSS \
     M=$PWD/probe8 modules

# 2. 推送并运行（init 空转，rmmod 触发 exit）
adb push probe8.ko /data/local/tmp/
adb shell 'echo "sh /data/local/tmp/runprobe.sh probe8" > /data/local/tmp/tvroot.cmd'
adb shell '/factory/su -p -c "cat /data/local/tmp/tvroot.out"'
adb pull /data/local/tmp/probe8.out

# 3. 反汇编（可选，用于解签名/找基址）
python3 tools/host/disasm_probe5.py
```

`runprobe.sh` 封装了「rmmod → insmod → rmmod → chmod」这套动作。

## 八、这套工具能干什么、不能干什么

能：

- 读任意内核函数的机器码并反汇编，从而反推出私有 HAL 的常量和调用协议；
- 调用厂商自己的访问函数，把任意子系统当成 oracle 查询（GOP 已验证）；
- 只读探查硬件状态，风险极低。

不能：

- 用 `module_init` 注册常驻驱动（布局不对，init 永远不被调用）；
- 靠 kallsyms 取数据符号地址（KALLSYMS_ALL 关闭）；
- 靠 `/proc/iomem` 拿外设基址（MStar 不注册）。

所以它适合**侦察**，不适合承载真正的驱动。要跑常驻驱动，仍然必须自己编内核。

## 九、后续（同日已推进）

1. **TCON / DIP 查完了：内核里几乎没有代码。**
   `grep -i tcon /proc/kallsyms` 没有任何 `MDrv_TCON`/`MHal_TCON` 符号，
   `MHal_DIP_*` 只剩一个取时钟的函数。⟹ **面板时序由 bootloader 配好，内核不参与**，
   与 cmdline 的 `tcon_type_extend=ST6451D02-5` 一致。对 simplefb 方案是利好——不用重做时序。
2. **GOP 寄存器全量快照已完成**：3 个索引 × 16 个 bank × 256 偏移，
   共 1241 个非零寄存器，含窗口矩形、色彩键、测试图案等。
   详见 [gop-registers.md](gop-registers.md)，原始数据 `artifacts/probe-out/probeD16.out`。
3. **帧缓冲地址不在 GOP 窗口寄存器里**（三种编码在 16 个 bank 全零命中），
   但这不影响 simplefb —— cmdline 已经给了 `recovery_fbaddr=0x2D100000`。
4. 下一步若要继续：把快照做成「黄金状态」，将来自己写 GOP 初始化时逐字段对照；
   或改用 `/dev/mik!disp` 的 ioctl（需要编一个 32 位用户态程序）。

---

## 八、★ 洋红 = 缺绿：这个颜色本身是诊断信号

2026-11-20 查证。**洋红不是"随便一个颜色"**，它在显示诊断里有固定含义。

### 1. 定义

```
洋红 / 品红 / magenta = R=255, G=0, B=255
RGB565 = 0xF81F   ARGB8888 = 0xFF00FF
```

**R 和 B 都满、G 归零。** 多个独立来源一致（【外部】）：

| 来源 | 原话 |
|---|---|
| screendefect.com | "Pink — or magenta — is what you get when **green drops out** and red and blue remain" |
| screentester.io | "A magenta (purple), green or yellow cast over everything often means **one channel is missing**" |
| screenissues.com | "Green sub-pixel stuck 'off' while red/blue are normal → the missing green makes the display appear pink/magenta" |
| monitormaven.com | VGA 的**绿色针脚**弯曲/氧化 ⟹ 画面变粉/洋红 |

⟹ **洋红 ⟹ 绿色通道缺失。** 这是业界标准的第一诊断结论。

### 2. 用它反推我们的两次读数

**关键：`0xFFFFFFFF`（全 1）在任何 bpp、任何位序、任何通道映射下都是白，不可能是洋红。**

| 轮次 | 涂的值 | 屏幕 | 洋红是谁 |
|---|---|---|---|
| `rung0` / `rung1` | `0x07FF07FF` | 洋红 + 碎竖纹 | **不是我们的，这一格此前判错了**。面板只读每个 32 位字的**低 16 位**（`boot-test.md` §四十六补，实测），`0x07FF07FF` 的低半字是 `0x07FF` = **青**。青色从未出现在屏上 ⟹ 我们的涂色没有留下痕迹 |
| `white-halt` | `0xFFFFFFFF` | 洋红 + 稀疏白点 | 低半字 `0xFFFF` = 白，方向对；但只有稀疏点，见 §九 |

⚠️ **2026-11-20 更正**：本表第一版曾写「`0x07FF07FF` 按 ARGB8888 拆是洋红，所以那是我们涂的」。
该推理与 `boot-test.md` §四十六补的实测矛盾——面板不走 32bpp，只取低 16 位。**那一格作废。**

⟹ **"洋红"这个读数没有唯一含义**：它既可能是 mboot 的 logo，也可能是「涂了一半、另一半留着 mboot 内容」。
这正是历史上"洋红时而被读成内核没进来、时而被读成跑到某级"的根源。

### 3. 白点这条反证很有价值

`white-halt` 里那些白点是**完整的白**（R=G=B 全满）⟹ **白点处的绿色通道是通的**。

⟹ 所以**不是物理链路单通道损坏**（那样白点也不会有 G）。
⟹ 而是"**大部分位置的数据缺绿、少数位置完整**"。

按 15×15=225 点算，完整数据只占 `225 / 2,073,600` 个像素 = **0.011%**。

⟹ **这么低的比例不可能是颜色/格式问题，只能是"地址 / 覆盖"问题。**
下一步不该再改颜色，该查"我们的写入到底落在哪、被谁扫"。

### 4. 业界同类现象（佐证"显存内容被当画面显示"很常见）

- **Armbian / Allwinner H3 粉屏**（【外部】）：U-Boot 把 framebuffer 放在内存末尾，内核不知道那块已被占用、往里写了别的数据，屏上就把内核数据当画面显示 ⟹ 变成粉屏/杂色。**成因是显存被别的东西占用或覆盖。**
- **U-Boot→内核切换时 LCD 杂色**（【外部】CSDN 多篇）：U-Boot 退出时未清 framebuffer、内核还没初始化 LCD，屏上显示的是 buffer 里的旧数据。常见解法是 U-Boot 关背光、内核再开。
- **LVDS 类固定偏色**（【外部】lcdchip / Sony 维修资料）：位深与映射不匹配、正负差分对反接、单/双通道 LVDS 不匹配、某路 B/G lane 失效，都会产生"固定偏色 / 半屏 / 重复图像"。

⟹ 我们看到的"洋红底 + 稀疏白点"属于这一类：**framebuffer 里的内容既不是我们想画的，也没被完整扫描出来。**

### 5. 结论

1. **屏幕上那片洋红不是我们的涂色**（涂的是全 1）。它是"缺绿"的底层状态。
2. **白点是我们的数据，但只到 0.011% 的像素** ⟹ 覆盖/地址问题，不是颜色问题。
3. **"改色值"这条路到此为止** —— 色值从来不是瓶颈，覆盖才是。

---

## 九、★★ 颜色通道早就被自己的文献判死了 —— 2026-11-20 翻检

用户问"为什么 7.3 能出整屏纯色、4.19 只出稀疏点"。翻文档发现：**这个问题项目里早有答案，
而且答案是"这两件事本来就不可比，也不该再用来判读"**。今天连续 4 次刷机全部用颜色判读，
属于倒退。

### 1. 三条被违背的既有结论

| 出处 | 原文 | 今天犯了什么 |
|---|---|---|
| `boot-test.md` §四十六补（11-18 11:05） | 「那块 buffer 是 8 MB，每个像素占一个 32 位字，但**有效颜色只在低 16 位**（RGB565）」 | 用 ARGB8888 拆 `0x07FF07FF` 推出"洋红是我们的" ⟹ 错。低半字 `0x07FF` 是**青** |
| 同上 | 现场对照：涂 `0x7E9000`（8 MB）+ `0x00ff00ff` → **整屏纯蓝**；涂 4 MB → **蓝粉相间竖条纹** ⟹ 「涂满就纯色，涂一半就有一半留着 mboot 的粉色，再被面板非线性扫描打散成交错的竖条」 | 把"洋红底 + 碎纹"当成新的未解现象，其实是**已知的"只涂了一半"** |
| `boot-test.md` §四十七（11-18 11:08） | 同一镜像连续上电 7 次，屏幕从"蓝粉相间竖条"变到"纯粉色底"，而设备始终卡死 ⟹ 「我们改 GOP 的动作与 mboot/GPU 的显示配置存在**竞争，谁最后写赢是随机的**」；**判据改为「设备会不会卡死」** | 又拿屏幕当主判据，并且把"每次不一样"当成机制线索 |

`entry-ladder.md` 也早写明两条：「**粉底碎条纹 = 镜像没被进入**」、判据必须是「整屏纯色」，
「半屏、条纹、纯色底上带碎块，都属于『没涂满』或『mboot 后写覆盖』」。

### 2. 于是今天的 4 次实验，有效读数只剩一条

| 镜像 | 今天的判读 | 按既有结论应判为 |
|---|---|---|
| `rung0` / `rung1` | 洋红底 = 第 1 级 | **无效**。青 `0x07FF` 从未出现；洋红是 mboot 内容 |
| `white-halt` | 白点 = 部分覆盖 | **无效**。§四十七 已定：屏幕内容与 mboot 竞争，随机 |
| `white-cc` | "白点变密 = cache 生效" | **无效**。同上，且"点数变化"没有可复现的因果 |

**唯一站得住的**：4 次都 `ping` 不通、`adb` 空、不自动重启 ⟹ **设备卡死**。
按 §四十七，卡死说明**内核确实执行了**（mboot 只在加载/跳转失败时 fallback）。
⟹ **"4.19 的 `code1` 路径通、镜像被进入并执行"这一条成立。** 仅此一条。

### 3. 为什么"7.3 整屏纯色"不等于"4.19 应该也整屏"

- 7.3 时代用的是 `m7642_beacon`（`arch/arm64/kernel/m7642-dtb.S`）：它**不碰控制字**，
  只 steer 八个窗口的 `STR_L/H/EX`，步进 `0x40`，然后涂满 `0x7E9000`。
- 4.19 的 `ladder.S` **先对 `0x1f240600` 做控制字的 read-modify-write**（强制 `bits[7:4]=1`、
  `bit0=1`），再 steer；另有 `disable every other window group` 循环。
- ⟹ 两者不是同一套涂色逻辑。**"7.3 能整屏"并不能推出"4.19 的 ladder 也行"**，
  反过来也一样。这条差异此前从未被当成变量看过。

`m7642-dtb.S` 自己的注释记着一个更硬的对照：**步进 `0x80` 会让"只有 window 0 被 steer，
显示为 bootloader 的 recovery 位图上刷了一小块颜色"**——正是我们看到的形态。

### 4. 结论与下一步

1. **停止用颜色判读等级。** 不是"颜色不准"，而是这条通道判据在 11-18 就被作废过，
   当时改成了"是否卡死"，后来又悄悄退回去了。
2. **要分级，必须换通道。** 现存的二值判据（卡死 / 不卡死）无法区分检查点。
   可行方向只有一个：**让设备自己重启**（这样 DDR 保留，`0x43300000` 标记可读）。
   WDT 未布防、PSCI 复位不实现（§H），所以需要**在 ladder 里直接布防 MStar WDT**——
   寄存器地址要先从厂值 4.9 的 WDT 驱动里挖，不能盲扫。
3. **若仍想用屏幕**，只有一个干净实验值得做：**只去掉 `ladder.S` 里的控制字 RMW**，
   其余一字不动（保留 steer、步进 `0x40`、涂满 `0x7E9000`、HALT）。
   判读只有两档：整屏纯色 ⟹ RMW 是元凶；仍旧碎 ⟹ 与 RMW 无关。
   ⚠️ 但这仍是"竞争"下的单次观察，**必须连续上电多次**才有一点点说服力。

## 十、★ recovery 槽里没有显示（2026-11-21 01:05 现场确认）

用户现场观察：**每一次正常进 Android 都只看见 logo**，从未见过 recovery 界面。
而 2026-11-21 00:53 那次，`/cache/recovery/last_log` 明确记录原厂 recovery
执行了 `-- Wiping data... / Formatting /data... / Data wipe complete.`，`/data/app`
的时间戳也随之变成 00:53 —— **它在跑，但屏幕上什么都没有**。

⟹ **recovery 路径下 GOP/背光没有初始化**，或者初始化了但不显示 UI。

**这条的后果很重**：

- 今晚四个探针（4.19 freeze、原厂内核 + ladder、44 B 单地址、64 B 双地址）的
  「屏幕上没有颜色」**全部不能作为判据**——那个阶段屏幕本来就不亮；
- 11-18 定下的「只认整屏纯色」在**recovery 槽**上从根上不成立。

**与 11-19 记录的冲突**：`confirmed-facts.md` §H 里「`adb reboot recovery` 不启动槽内内核 **否**，
依据是 `ladder9.img` → 亮绿 `0x07E0`」。如果 recovery 模式不显示，那次不该看见绿色。
两种可能，**目前无法区分**：

1. 11-19 那次是**从运行中的 Android 直接 warm reboot** 进 recovery，GOP 已被 Android 配好、
   mboot 沿用，所以有显示；而现在每次 `adb reboot recovery` 都会**先回待机**（PM51 切电），
   按键后是 cold boot，GOP 从零初始化 ⟹ 无显示。
2. 11-19 的记录本身有问题（绿色另有来源）。

**⟹ 下一步必须先解决"recovery 模式下能不能有显示"**，否则任何屏幕实验结果都不可读。
可行的方向：找到一种**不经过待机**进入 recovery 的办法（`boottest.sh reboot` 用的
`adb reboot recovery` 在这台机器上会进待机），或者在探针里自己打开背光/GOP。

## 十一、★ 改走 boot 槽：屏幕这条路只剩它（2026-11-21 09:35，静态准备）

§十 的结论是「recovery 路径没显示 ⟹ 那里的颜色实验读不出来」。于是换槽：

| 依据 | 强度 |
|---|---|
| **boot 路径屏幕一定亮**：用户观察每次开机都必出现 logo | 实测（人眼，多次） |
| **mboot 不校验内核内容**：`boot-test.md` §十九 的决定性实验，签名/哈希/AVB/CRC 全排除 | 实测 |
| boot 槽坏了要 U 盘救（boot 是正常启动路径，没有 BCB 兜底） | 推论 |

### 11.1 原厂 boot 镜像的两条实测

读 `~/kbuild/boot-stock-backup.bin`（32 MiB，`mmcblk0p8` 的备份）：

```
code0  91005a4d   add x13, x18, #0x16      <- 不是分支
code1  143e7fff   b 0xfa0000               <- 跳 MStar 的 vendor 入口
text_offset   0x80000
image_size    0x1551000
kernel_size   0x12d4a00
ramdisk_size  0   (boot 无 initramfs；recovery 有 0x75d1f1)
```

**`code1` 不是标准的 `b primary_entry`，而是 `b 0xfa0000`。** 这解释了 `build.sh`
里那条「不许越过 0xFA0000（vendor entry）」的上限——那是 TCL/MStar 的入口，
不是普通代码区。⟹ 探针跑完必须跳回 **0xfa0000**，跳 0 会落进 `text_offset` 数据。

另外：kernel 之后到分区末尾全是 `0x00`（不是 `0xFF`）。

### 11.2 产物

`tools/host/mk-boot-beacon.py` 把探针追加到原厂 kernel 尾部，改 `code1` 指向它，
再把探针最后一条 `b` 指回 `0xfa0000`：

```
kernel_size 0x12d4a00 -> 0x12d4bb8   (探针 440 B)
code1   144b527f -> 0x12d4a00        ✓
tail    17f32d13 -> 0xfa0000         ✓
```

镜像 `~/kbuild/m7642-out/m7642-boot-beacon.img`，33,554,432 B（= 分区大小），
md5 `caaccfa8f46b14d86944a35a7d475b30`。

探针本体是 `probes/ladder` 的 `blue-hold.bin`（`FREEZE=0 HOLD=8`）：
涂色 → 用 `CNTFRQ_EL0`/`CNTVCT_EL0` 等 8 秒 → 落到尾部 `b 0xfa0000`。

**为什么是延时不是死循环**：boot 路径的 mboot 命令里**没有 `wdt_enable`**，
死在那里就是 U 盘，不是 warm reset。延时只读系统寄存器，不访存，不会 fault。

### 11.3 刷入与判读

`tools/host/bootarm.sh arm`（走 `/system/bin/su`，rootd 自启后可用）。

| 现象 | 含义 |
|---|---|
| 整屏纯色约 8 秒 → Android 正常启动 | 注入成功 + 涂色可用 ⟹ **屏幕通道恢复** |
| 无颜色但 Android 正常启动 | 注入成功、涂色没生效（GOP 地址或控制字假设错） |
| 起不来 | 注入方式有问题 ⟹ U 盘 `rescue-fast.bin`（含 boot 段） |

三种结果都有信息量，第二种尤其：它把「注入」和「涂色」两个变量分开了。

### 11.4 ★★★★★ 首轮结果是脚本 bug，不是涂色失败（2026-11-21 09:39 实测 + 09:45 静态回查）

**屏幕现象（实测，用户口述）**：按电源键 → **全程黑屏**，没有 logo，十几秒后回待机。

**这不是 11.3 表里的任何一行**，回查镜像后找到原因：

```
probe 尾部（m7642-boot-beacon.img，at=0x12d4a00，len=440）
  @+0x1b0: 14000000   b .            <- 占位符，没被 patch
  @+0x1b4: 17f32d13   b 0xFA0000     <- 写到了 "M76E" 标记的位置
```

`mk-boot-beacon.py` 约定「探针最后一个 word 是占位分支」，但 `ladder.S` 在占位分支
后面又放了一个 `"M76E"` 结束标记。于是 patch 覆盖的是标记，占位符原样留着，
探针在 **HOLD 8 秒之后落进 `b .` 死循环**，永远不跳回 `0xFA0000`，
mboot 等不到内核起来就超时回待机。

⟹ **上一次的判读整条作废，改成**：

| 事实 | 强度 |
|---|---|
| 探针**确实被执行了** | 实测推论。code1 是我们改的；若没执行，厂镜像会照常出 logo 进 Android |
| 「起不来」是 `b .` 死循环 + mboot 超时，**不是**涂色失败、也不是核崩 | 静态读出，字节级确定 |
| 「没有 logo」原因未定 | 见下 |

**「没 logo」两个候选**：

1. `ladder.S` 关了 16 个 bank 的使能位（`0x1f240400` 起，步长 0x200，跳过 bank1），
   而 bank 数量与布局是**未验证的假设**——这条既可能写坏别的寄存器（MMIO 盲写，
   违反纪律 §3），也可能就是屏幕不亮的原因；
2. mboot 本来就不画 logo（与「每次开机都有 logo」的实测矛盾，基本排除）。

**已修**：`mk-boot-beacon.py` 加断言，blob 最后 4 字节必须是 `0x14000000`，
否则直接报错。`ladder` 的 blob 天生带这个 bug（`M76E` 在最后），
**以后走 boot 槽必须先去掉那个标记**。

### 11.5 下一发：纯延时探针（零寄存器写入）

`probes/delay/delay.S`，`DELAY=10`：

```
mrs x11, CNTFRQ_EL0 / mrs x12, CNTVCT_EL0 / madd deadline
循环读 CNTVCT 到点 -> b 0xFA0000
```

不碰 GOP、不写内存、不用栈，只读两个系统寄存器。产物
`~/kbuild/m7642-out/m7642-boot-delay10.img`（md5 `3a2ee924e22a0277de63389db084535f`）。

| 现象 | 含义 |
|---|---|
| 有 logo，整体慢约 10 秒，正常进 Android | 注入与返回都成立 ⟹ 从此可放心在 boot 槽做涂色，问题只剩涂色参数 |
| 没 logo / 回待机 | 连「延时 + 返回」都不行 ⟹ 查 `b 0xFA0000` 的返回上下文（x0/x2/x3/x4）或 mboot 超时 |
| 完全正常、不慢 | 探针没跑（与 11.4 矛盾，届时再查） |
