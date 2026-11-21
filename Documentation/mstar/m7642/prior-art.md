# 同类案例与官方契约：无串口、输出不可靠时怎么往前走

2026-11-20。问题来源：不拆机、不接 UART、屏幕颜色判读不可靠，怎么把 ARM 板移植到更高版本内核；
以及这类 ARM 板到底怎么接显示屏、接口有什么讲究、Linux 怎么驱动。

体例同其它篇：**结论 → 证据 → 对主线的意义 → 待办**。证据分三档标注：
【实测】= 我们在这台机器或这棵树里验证过；【外部】= 别人的案例/上游文档，未在本机验证；
【推测】= 没有证据，只是合理猜测。

---

## 一、先说结论（只有三条，都直接影响下一步动作）

### 1. 网上最流行的那条"用 PSCI 复位当信标"，我们早就试过，**它在这颗 ATF 上不工作**

`smc #0` 带 `x0 = 0x84000009`（SYSTEM_RESET）返回了，`brk #0` 也没有触发重启
（`boot-test.md` §三十 1(b)，【实测】）。

⟹ 这条不是新方法，是**已否证的假设**。看到它在别处被推荐，不要重走。
（`confirmed-facts.md` §H 已收录。）

### 2. 第二条最流行的"用看门狗超时复位当信标"，我们也查过了，**同样不通**

- 正常 boot 路径上**没有布防的狗**：5 秒狗唯一布防点在 CMD25 写 eMMC（`0x60e88`），
  即只覆盖刷机动作，不覆盖启动（【实测】，`boot-test.md` §五十七）。
- `HAL_WDT_Start` 在这个 BSP 里是**空实现**（`return 1`），`0x3004` 是复位标志不是使能位（【实测】）。
- mboot 出厂 env 里 `WDT_ENABLE 0`，而 `WDT_ENABLE` 只管"进 U-Boot 命令行时的 10 秒狗"，
  与 boot 无关（【实测】，§五十七 §3）。

⟹ 想让内核执行到某点后"不喂狗 → 等它自己重启"，没有可用的狗。

### 3. 剩下的唯一信标就是屏幕，而屏幕这条路的**官方契约**恰好支持我们现在的做法

`simple-framebuffer` 的官方描述（本树 `Documentation/devicetree/bindings/display/simple-framebuffer.yaml`，【实测】原文）：

> A simple frame-buffer describes a frame-buffer setup by firmware or the bootloader,
> **with the assumption that the display hardware has already been set up to scan out
> from the memory pointed to by the reg property.**

这正是 `recovery_fbaddr=0x2D100000` + `tcon_type_extend=ST6451D02-5` 的官方说法：
**bootloader 配好 TCON/面板，内核只接管一块已经在扫描输出的内存**。

但读源码发现我们 DTS 的写法与契约有偏差，且 **4.19 与 7.3 创建 platform device 的路径不同** ——
见 §三.4，这是立刻可以改的两处。

---

## 二、无串口 + 输出不可靠：别人用什么信标

### 2.1 信标成本/有效性矩阵（含我们的实测结论）

| 信标 | 别人怎么用 | 在我们这台机器上 | 依据 |
|---|---|---|---|
| **GPIO 点灯** | 关键路径翻转 GPIO，示波器/万用表看波形 | **不可用**：需要物理接触焊点，拆不了机 | 用户约束【实测】 |
| **JTAG / SWD + OpenOCD** | 断点、单步、读 PC | **不可用**：同上，且 SoC 侧 JTAG 引脚未引出 | 【推测】（没拆过机，无法确认是否引出） |
| **PSCI SYSTEM_RESET** | `smc #0`, `x0=0x84000009`，看设备是否重启 | **已试，无效**（`smc` 返回，不重启） | 【实测】§三十 |
| **看门狗超时** | 执行到某点后停止喂狗 | **不可用**：boot 路径无布防的狗 | 【实测】§五十七 |
| **屏幕像素** | 把 framebuffer 填成纯色 | **唯一可用**，且已在对照组里证明有效 | 【实测】§三十 1(a) |
| **ramoops / pstore** | 崩溃时把 dmesg 存到保留内存 | **可用，但抓不到"没进内核"** | 【实测】`ramoops.md` |
| **哨兵内存字** | 往固定物理地址写魔数，重启后读 | 可用（已用 `"M764"` / `0x4D373645`） | 【实测】`confirmed-facts.md` §E |

结论：**我们不是"还没想到用别的方法"，而是四条常规替代通道里有三条被硬件/固件条件物理堵死，
第四条（pstore）的覆盖面到不了 `setup_arch` 之前。** 所以颜色是硬约束，不是偷懒。

### 2.2 为什么"颜色"不可靠 —— 根因不在 RGB565

外部讨论里把"屏显颜色不可靠"通常归到编码歧义（r5g6b5 的位序）。我们的实际情况不是这个：

| 观察到的现象 | 真实原因 | 依据 |
|---|---|---|
| 四版**逐字节相同**的着色镜像，一次整屏绿、三次花屏/条纹 | 不是编码问题，是**判读纪律**问题：条纹不算数、色序不算数、土黄是自家 stub 的填充色 | 【实测】`discipline.md` §1 |
| "屏幕上还是 logo" = 内核没执行 | **错**。实际一直有洋红，是把洋红误记成 logo | 【实测】§三十二（结论已作废重写） |
| 涂色成功但设备不重启 | 涂色与复位是两条独立通道，后者坏了不影响前者 | 【实测】§三十 |

⟹ 这条经验对外部同类项目也成立：**无串口时最大的风险不是"看不见"，而是"看见了但记错了"**。
所以判读规则必须写死成表，且每次只能断言"整屏纯色"这一个二值量。

### 2.3 外部确实存在的第三种做法：把观测点前移到"内核外"

我们没有采用，记在这里备用：

- **mboot 侧打点**：`boot-test.md` 里已经用过 —— 把探针插在 mboot 自己的执行路径上
  （`+0xFA0000` slot），绕开内核。这是"对照组"成立的原因（【实测】§三十 2）。
- **ATF 侧**：不可行，ATF 是加密 MULTIBIN（【实测】§二十五 4）。
- **PM51 / 待机 MCU**：会接管电源键与待机，但**没有可编程通道**（【实测】`pm51-standby.md`）。

⟹ 打点能力的天花板在 mboot → 内核入口这一段，再早就是黑盒。

---

## 三、ARM 板怎么接显示屏：接口族与 Linux 侧的对应

### 3.1 物理接口族（电视整机与开发板不同）

| 接口 | 典型场景 | 数据格式 | 时钟/通道 | Linux 侧 |
|---|---|---|---|---|
| **并行 RGB（DPI）** | 小屏、开发板直连 | 16/18/24 bit 并口 | 像素时钟 + HS/VS/DE | `panel-simple` + `lcdc` |
| **LVDS** | 中尺寸面板、笔记本 | 4/8 lane 差分 | 通常 1 对时钟 | `panel-lvds`、`lvds-codec` |
| **MIPI DSI** | 手机、平板、越来越多电视副屏 | D-PHY 差分包 | 1–4 lane + 时钟 lane | `dw-mipi-dsi`、`dsi panel` |
| **eDP** | 笔记本 | 差分 + AUX | 1–4 lane | `panel-edp` |
| **HDMI** | 外接 | TMDS / FRL | 4 lane | `dw-hdmi` 等 |
| **V-by-One HS** | **大尺寸电视整机主流** | 差分串行 | 1–8 lane | 上游**没有通用驱动**，多在国内方案商私有代码里 |

我们这台是最后一种的上游变体：**SoC 内置 TCON，直出面板**（`tcon_type_extend=ST6451D02-5`）。
证据是内核里完全没有 TCON 代码 —— `grep -i tcon /proc/kallsyms` 零命中（【实测】`display.md` §九）。

### 3.2 电视整机的特殊之处：中间多一级 TCON

开发板的链路是 `SoC → 面板`；电视整机是 `SoC → TCON → 面板`，
TIMING（HS/VS/DE/像素时钟）由 TCON 产生，SoC 只负责"喂像素"。

对我们有两个后果：

1. **面板时序永远不用内核管** ⟹ 不需要写 panel 驱动，不需要 `panel-simple`，不需要 OF graph。
2. **但 TCON 的初始化必须由 bootloader 完成**，否则内核接管时没有扫描输出 —— 这正是
   `simple-framebuffer` 契约成立的前提，也是为什么这条路线在我们这里"恰好合适"
   （不是我们挑了简单路线，是硬件分工本来就长这样）。

### 3.3 两条 Linux 路线：fbdev 的 `simplefb` 与 DRM 的 `simpledrm`

**【实测】本树源码核对结果（7.3）：**

| 项 | `simplefb`（fbdev） | `simpledrm`（DRM） |
|---|---|---|
| 路径 | `drivers/video/fbdev/simplefb.c` | `drivers/gpu/drm/sysfb/simpledrm.c`（★ 已从 `tiny/` 搬走） |
| 配置 | `CONFIG_FB_SIMPLE` | `CONFIG_DRM_SIMPLEDRM` |
| 互斥 | `depends on !DRM_SIMPLEDRM` | — |
| DT 匹配 | `compatible = "simple-framebuffer"` | **同一个** `compatible` |
| 依赖 | `FB` | `DRM && MMU` |
| 同目录兄弟 | — | `ofdrm`（**PPC 专用**，arm64 用不上）、`efidrm`、`vesadrm`、`corebootdrm` |

**⟹ DTS 写法完全一样，只是接管者不同。** 7.3 里 `FB_SIMPLE` 与 `DRM_SIMPLEDRM` 二选一，
选了 DRM 这条路以后 `fbdev` 那套是兼容层。

**4.19 的差别（【实测】源码核对）：**

```c
/* drivers/video/fbdev/simplefb.c (4.19) */
static int __init simplefb_init(void)
{
        ret = platform_driver_register(&simplefb_driver);
        if (IS_ENABLED(CONFIG_OF_ADDRESS) && of_chosen) {
                for_each_child_of_node(of_chosen, np)      /* ← 驱动自己遍历 /chosen */
                        if (of_device_is_compatible(np, "simple-framebuffer"))
                                of_platform_device_create(np, NULL, NULL);
        }
}
fs_initcall(simplefb_init);
```

```c
/* drivers/of/platform.c (7.3, of_platform_default_populate_init) */
node = of_get_compatible_child(of_chosen, "simple-framebuffer");
if (node) { sysfb_disable(NULL); of_platform_device_create(node, NULL, NULL); }
/* Populate everything else. */
of_platform_default_populate(NULL, NULL, NULL);
```

两条路径都认 `/chosen` 下的节点，但 4.19 是**驱动自己**在 `fs_initcall` 里补，7.3 是
**of core** 在 `of_platform_default_populate_init` 里做并顺手 `sysfb_disable`。

### 3.4 官方绑定的硬条款（【实测】读本树 yaml 原文）

| 条款 | 原文要求 | 我们的现状 | 是否合规 |
|---|---|---|---|
| 位置 | "must be sub-nodes of the **chosen** node" | **2026-11-20 已从根节点移入 `/chosen`**（并补 `#address-cells/#size-cells = <2>`） | ✅ |
| 命名 | "must be named `framebuffer@<address>`" | `framebuffer@2d100000` | ✅ |
| `reg` | framebuffer 内存位置与大小 | `<0 0x2d100000 0 0x7e9000>` = 1920×1080×4 | ✅ |
| `format` | 11 种枚举之一，**不是只有两种** | `"a8r8g8b8"` | ✅ |
| `stdout-path` | 要当 LCD 控制台"就应该"指向它 | 指向 `serial0:115200n8`，**故意不动**（见下） | ✅ 合规但非 fbcon 入口 |
| `width/height/stride` | 可选，但无 panel 节点时用于估算物理尺寸 | `1920/1080/7680` | ✅ |

**关于 `stdout-path` —— 一条我先写错、核完源码后收回的建议。**

原来记的是"未设"，实际 DTS 里一直是 `stdout-path = "serial0:115200n8"`（【实测】）。
它不能改成指向 framebuffer，原因是 **`earlycon` 靠它推断用哪个串口**：bootargs 里写的是裸
`earlycon`（不带参数），去掉 `stdout-path` 指向就丢掉 earlycon 的自动选择。

而 fbcon 并不依赖 `stdout-path` —— bootargs 里已经有显式的 `console=tty0`，
`FRAMEBUFFER_CONSOLE` 会把控制台绑到第一个注册的 framebuffer 上。
⟹ **保持 `stdout-path` 指向串口是对的，不需要改。** 这一条从"待办"降级为"已合规"。

`format` 完整枚举（纠正一条旧记忆 —— 不是"只允许 `r5g6b5` / `a8b8g8r8`"）：

```
a1r5g5b5  a2r10g10b10  a8b8g8r8  a8r8g8b8  r5g6b5  r5g5b5a1
r8g8b8    x1r5g5b5     x2r10g10b10  x8r8g8b8  x8b8g8r8
```

`a8r8g8b8` = `d[31:24]=a, d[23:16]=r, d[15:8]=g, d[7:0]=b` —— 与我们涂色时用的
`movz/movk w15,#COLOUR` 一致（【实测】`confirmed-facts.md` §E 刷屏 blob 契约第 4 条）。

**为什么位置要合规而不仅是"能跑"**：根下的节点走 `of_platform_default_populate` 常规路径，
在 arm64 DT 系统上通常也能创建出 platform device，但**不会 `sysfb_disable()`**，
且违反绑定 ⟹ 将来上游化会被 review 打回。

⚠️ 要说清楚这次改动的性质：**它是消除潜在歧义 + 对齐上游，不是修 bug。**
节点在根下时大概率也能 probe（从没上机验证到那一步，所以只能说"大概率"）；
改到 `/chosen` 后走的是 `of core` 专门为它写的那条路径。改动已验证：dtb 重编无警告，
反编译确认节点在 `chosen` 下、`reserved-memory` 里的同名内存节点未受影响。

### 3.5 真要做显示驱动时的对象链（现在不需要，记着）

`Framebuffer → Plane → CRTC → Encoder → Connector → 屏`

- `panel-simple` / `panel-lvds`：面板上下电与时序表的状态机（`prepare/enable/disable/unprepare`）。
- `drm_bridge`：SoC 输出与面板之间的转换器（DSI→LVDS、DP→HDMI 等）。
- OF graph：`port` / `endpoint` / `remote-endpoint` 描述拓扑，**缺一环 pipeline 就组装不起来**。
  典型失败是"驱动都 probe 了但没有 `/dev/dri/card0`"，原因往往是 graph 少一条链。

对我们是纯知识，**不做**：TCON 由 bootloader 管，我们没有需要描述的硬件拓扑。

---

## 四、别的项目怎么把"无厂方支持"的 ARM SoC 搬上主线

### 4.1 linux-chenxing（MStar / SigmaStar 血统）★ 最相关的对照

- 项目性质：社区自发主线化，**没有厂方支持，NDA 不可签**（【外部】）。
- 覆盖平台：MSC313E（Breadbee 摄像头板系列）等，**不是** M7642 电视 SoC。
- 方法论是**分轮**：

| 轮次 | 内容 |
|---|---|
| Round 1 | 架构支持 + UART console 打通 |
| Round 2 | DTS 基础（SRAM / PMU / reset） |
| Round 3 | INTC 中断控制器 |
| Round 4 | GPIO |
| Round 5 | 时钟 |

**对我们的意义（三条，按价值排序）：**

1. **方法可借，代码不可借** —— 型号相邻 ≠ 可复用。我们已经在 USB / GOP / SMP 上反复验证过
   这条（`usb-phy.md`、`gop-registers.md`、`smp.md` 全是"m7322 的偏移在 m7642 上不成立"）。
2. **他们的 Round 1 是 UART console，我们做不到** ⟹ 我们的 Round 1 必须换成"屏幕纯色 + 哨兵字"，
   这解释了为什么我们的梯级比他们多、每一级的信息量比他们少。
3. **他们也得从固件里挖常量**（没有 datasheet）。挖法与我们 `display.md` §六的做法同源：
   不猜地址，调用厂商自己的访问函数当 oracle。

### 4.2 SDM845 mainlining wiki：从固件二进制里取 framebuffer 地址

别人的做法（【外部】）：`strings <xbl 镜像> | grep "Display Reserved"` 拿到 UEFI 阶段
预留给 framebuffer 的地址，再在 DTS 里写 `reserved-memory` + `simple-framebuffer`。

**对照我们**：地址不是从固件挖的，是从 cmdline 直接读的（`recovery_fbaddr=0x2D100000`，
【实测】）。更省事，但**同一件事**：framebuffer 的物理地址从来不在内核里，必须由 bootloader 交付。

⟹ 这解释了一个反复出现的困惑：**`0x2D100000` 在 `grep -i tcon /proc/kallsyms` 里查不到任何东西，
不是我们找错了地方，而是它本来就不该在符号表里。**

### 4.3 共同套路总结

主流项目的无厂方支持移植，几乎都走同一条路：

1. **先把"能看见字"当第一优先级**，为此可以临时牺牲别的（我们换成了"能看见颜色"）；
2. **从活体/固件里挖常量**，不猜寄存器（`display.md` §六 的 oracle 法）；
3. **分轮提交**，每轮只加一个子系统，每轮都要能启动到用户空间（我们的 ladder 同构）；
4. **用对照组成立因果**（原厂内核 + 只改一处，对比我们的镜像 —— `boot-test.md` §三十 2 就是照这个做的）。

第 4 条是我们自己走对的：`原厂内核 + 同一个 slot2 探针 = 变红` vs `我们的镜像 + 同一个 slot2 = 卡住`，
这是整条线上信息量最大的一次观测。

---

## 五、对我们主线的直接意义（可执行，按优先级）

### 5.1 三件候选改动的核查结果（一条做了，两条撤回）

| # | 候选动作 | 核查结论 | 状态 |
|---|---|---|---|
| 1 | DTS 里把 `framebuffer@2d100000` 从根节点**移到 `/chosen` 下** | 成立。7.3 走 `of_get_compatible_child(of_chosen, …)` 并 `sysfb_disable` | ✅ **已改**（dtb 重编无警告，反编译已确认） |
| 2 | 加 `/chosen/stdout-path` 指向 framebuffer | **撤回**。DTS 里本来就有 `stdout-path = "serial0:115200n8"`，且 `earlycon` 靠它推断串口；fbcon 靠的是 bootargs 里的 `console=tty0`，不依赖它 | ❌ 不改 |
| 3 | 4.19 开 `CONFIG_FB_SIMPLE=y` | **撤回**。见下，4.19 只吃外部 DTB，开了也匹配不上 | ❌ 不做 |

**第 3 条为什么撤回 —— 这是本轮最重要的一次自查。**

表面上"4.19 没有 `FB_SIMPLE` ⟹ 没文字通道"是对的（`# CONFIG_FB_SIMPLE is not set`，【实测】），
但**打开它并不能解决问题**：

1. **4.19 只用 mboot/ATF 交过来的 DTB**。`arch/arm64/kernel/setup.c` 里是
   `setup_machine_fdt(__fdt_pointer)`，而 `__fdt_pointer` 由 `head.S:480`
   （`str_l x21, __fdt_pointer`）从入口寄存器保存 —— 厂商改造版**没有 appended-DTB 分支**
   （`CONFIG_ARM64_APPENDED_DTB` 在 `.config` 里也不存在）。
2. **那个 DTB 是厂值的**，里面**没有** `simple-framebuffer` 节点（Android 用真显示驱动）。
   `simplefb` 的 `of_match` 只认 `compatible = "simple-framebuffer"` ⟹ 没有节点可匹配。
3. 真要让 4.19 有字，得**同时**改厂值 DTB（塞 `simple-framebuffer` 节点）。
   而 4.19 上机是**一次赌注**——把"验颜色"和"改 DTB"绑在一起，等于把一个变量变成两个，
   一旦失败就分不清是内核问题还是 DTB 问题。

⟹ **正确顺序：先按原计划只验颜色，确认 4.19 能起；文字通道留到确认之后再说。**
届时如果要，走"厂值 DTB + simple-framebuffer 节点"或 `CONFIG_ARM64_APPENDED_DTB`
（后者需要把 7.3 的 DTS 移植进 4.19 树，工作量不小）。

**顺带记一条 4.19 的 `fs_initcall` 边界**：`simplefb_init` 在 `fs_initcall`，
比 `setup_arch` 晚得多，**覆盖不到 `create_init_idmap`** ⟹ 即使将来打通文字通道，
**颜色对 7.3 那个失败点仍然不可替代**。

### 5.2 不要做

| # | 别做 | 原因 |
|---|---|---|
| 1 | 再试 PSCI SYSTEM_RESET 当信标 | 已实测无效（§三十 1b） |
| 2 | 试看门狗超时信标 | boot 路径无活狗（§五十七） |
| 3 | 照抄 linux-chenxing 的 MSC313E 代码 | 型号不同，寄存器布局不同 |
| 4 | 上 `ofdrm` | `depends on PPC`（【实测】本树 Kconfig） |
| 5 | 现在就去写 DRM/KMS 驱动 | TCON 由 bootloader 管，没有拓扑可描述，写了也没东西可管 |

### 5.3 待确认

| # | 问题 | 怎么确认 |
|---|---|---|
| 1 | 7.3 的 `framebuffer@2d100000` 到底有没有 probe 成功 | 上机后 `ls /dev/fb0` / `cat /proc/fb` / `dmesg \| grep -i simpledrm` |
| 2 | 移到 `/chosen` 后是否真的建出了 platform device（与改之前的行为差异） | 同一组命令；对比 `dmesg \| grep -i "simple-framebuffer"` 有无 device 名 |
| 3 | 4.19 上机时厂值 DTB 里到底有没有可用的显示节点 | `dtc -I dtb -O dts` 反编译 `vendor-dtb.bin`，`grep -i "framebuffer\|display"` |
| 4 | SoC 的 JTAG 引脚是否引到板上 | 需要拆机，**不做** |
| 5 | `simpledrm` 在 7.3 里是否被 `DRM_CLIENT_SELECTION` 等新依赖卡住编译 | 已编过（`CONFIG_DRM_SIMPLEDRM=y` 在 `.config` 里，源码完整） |

---

## 六、来源

| 类型 | 来源 |
|---|---|
| 【实测】本机 | `boot-test.md` §三十 / §三十二 / §五十七；`display.md` §六 §九；`smp.md`；`pm51-standby.md`；`confirmed-facts.md` §E §H |
| 【实测】本树源码 | 7.3：`drivers/video/fbdev/simplefb.c`、`drivers/gpu/drm/sysfb/{simpledrm,ofdrm}.c`、`drivers/gpu/drm/sysfb/Kconfig`、`drivers/of/platform.c`、`Documentation/devicetree/bindings/display/simple-framebuffer.yaml`；4.19：`drivers/video/fbdev/simplefb.c`、`Documentation/devicetree/bindings/display/simple-framebuffer.txt` |
| 【外部】 | linux-chenxing 项目（MStar/SigmaStar 主线化，分轮方法论）；SDM845 mainlining wiki（从 xbl 提 framebuffer 地址）；Igalia / Guilherme G. Piccoli 的 PSCI SYSTEM_RESET 调试信标讲法；barebox 文档（`register_simplefb` 与 `stdout-path`）；DRM/KMS 对象链与 `panel-simple` / `drm_bridge` / OF graph 通用文档 |

**外部材料的共同局限**：它们假设"你至少能改 bootloader"或"你至少有一个能用的串口"。
这两条我们都不成立，所以本文里外部方法**多数只作参照**，能直接用的只有 §三.3 §三.4 的绑定契约部分。
