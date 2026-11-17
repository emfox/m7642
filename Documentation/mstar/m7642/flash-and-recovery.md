# 实机刷机与恢复：五张 U 盘盘符，一条命令

> 结论先行：这台机器**不需要串口也能做到**「刷到内核 → 看结果 → 三十秒退回 Android」。
> 关键是把 U 盘升级 BIN 做成**只写 `misc`**（20 KB）和**只写 `misc`+`recovery`**（5.8 MB）两种，
> 而不是每次都刷 3.3 GB 的全量包。全量包会 `mmc erase.p userdata`，代价是用户数据全丢。

## 一、唯一可靠的物理入口

前两次救援失败都不是文件问题，是**没进升级模式**。正确顺序：

1. 拔电源插头，等 10 秒；
2. 手指**按住机身上的实体电源键**不放（不是遥控器）；
3. 插回电源，继续按住 10～15 秒，屏幕出现进度条后松手。

依据：mboot 里 `get_boot_mode_from_keypad`。机身键日常功能与红外电源键相同，但只在
「上电时按住」这一种情况下被当成强制升级键。

另有一条**已被证伪**的路：电视自带「设置 → 系统升级 → 本地升级」对同版本包报
「无可升级版本」。对应 mboot 的 `CurrentVersion is newer than UpdateVersion` 比较，
按键强制升级会绕过它。

## 二、BIN 容器格式（官方版式，逐字节核对过）

```
+0x0000  16 KiB  纯文本 MBOOT 脚本，最后一行 '% <- this is end of script symbol'，余填 0xFF
+0x4000  payload  按脚本出现顺序拼接
EOF-32   footer
```

footer 32 字节：

```
"12345678"          8    magic
u32 crc32(header)   4    覆盖前 16 KiB（注意是 header，不是 payload）
u32 0xb74aabba      4    本机型常量；两个 system 不同的官方包取值相同，因此不是 payload 校验
header[0:16]        16   "#-------------US"
```

⚠️ 社区工具 `mstar-bin-tool` 打的是**另一种 40 字节**尾部（两个 u64 CRC + header16）。
`recovery-stick.md` 里那段描述的是那种版式。两者都能"看起来像"，但本仓库现在一律按
**官方 32 字节版式**生成 —— 官方包在这台机器上刷成功过两次，社区版式没有在真机验证。
生成器：`tools/host/rescue/mkbin.py`。

脚本里 `filepartload` 的偏移是**文件绝对偏移**，所以第一块载荷固定在 `0x4000`。

### 为什么 v3/v4 会被拒（推翻了"脚本区不能改"的结论）

`2026-11-15` 改脚本的两版（v3 改 bootargs + 删 userdata 段，v4 只改 bootargs 一行）都被拒，
当时的结论是"脚本区一个字节都不能改"。今天把三个包的尾部位段比了一遍：

| 包 | 脚本 | `crc32(header)` | footer 里存的 | 结果 |
|---|---|---|---|---|
| 原厂 | 原样 | `0xedd2f756` | `0xedd2f756` | 能刷 |
| v3 | 改过 | `0x48ccd168` | `0xedd2f756` | 被拒 |
| v4 | 改过 | `0x41f1ec06` | `0xedd2f756` | 被拒 |
| v5 | 原样 | `0xedd2f756` | `0xedd2f756` | 能刷 |

⟹ **真正的闸门是 footer 里的 `crc32(header)`，不是"脚本不能改"**。v3/v4 改了脚本却忘了
重算这个字段（`tools/host/rescue/mkbin.py` 与 `fw/fix_footer_crc.py` 都会算）。
推论：改 bootargs、删掉 `userdata` 段（保住 `/data`）在原理上是可行的，只要 CRC 跟着更新。
`0xb74aabba` 在新脚本下是否也要变，仍未验证 —— 见 §八。

## 三、五张盘（都是 `mkbin.py` 生成，`md5` 见生成目录 `MANIFEST.bins`）

| BIN | 大小 | 脚本做什么 | 用途 | 风险 |
|---|---|---|---|---|
| `m7642-misc-stock.bin` | 20 KB | 写回原厂 `misc` | **解卡**：BCB 清掉，下次正常进 Android | 极低 |
| `m7642-misc-recovery.bin` | 20 KB | 写 `misc`，BCB=`boot-recovery` | 让下次启动进 recovery 槽 | 低（需 recovery 槽里有可用镜像） |
| `m7642-recovery-ours.bin` | 5.8 MB | 写回我们的镜像 + 原厂 `misc` | 换成我们的内核，但先正常进 Android | 低 |
| `m7642-recovery-ours-boot.bin` | 5.8 MB | 我们的镜像 + BCB=`boot-recovery` | **一次上电直接试我们的内核** | 低（解卡盘在手） |
| `m7642-recovery-stock.bin` | 32 MB | 恢复原厂 `recovery` + 原厂 `misc` | 彻底还原本地改动 | 低 |

它们都**不碰** `boot` / `dtb` / `userdata` / `system`，所以不会丢数据、不会变砖。
产物位置：`/home/emfox/kbuild/rescue/partial/`。

## 四、mboot 到底怎么启动内核（从官方脚本里读出来的）

官方全量包在写 `boot` / `recovery` 之后各存了一条 env：

```
setenv bootcmd     mmc read.p 0x23000000 dtb 0x00100000; mmc read.p 0x25000000 boot     0x02000000; bootm 0x25000000
setenv recoverycmd mmc read.p 0x23000000 dtb 0x00100000; mmc read.p 0x25000000 recovery 0x02000000; bootm 0x25000000
```

三条硬事实：

1. **用 `bootm`，不是 `booti`** —— 我们之前扫出「`booti` 不存在」是对的，mboot 只有 U-Boot 的
   `bootm`（`do_bootm_linux` 被改造成认 `ANDROID!` 头）。
2. **DTB 总是从 `dtb` 分区读到 `0x23000000`**，与内核镜像分开。这就是 `0004-local-builtin-dtb.patch`
   存在的理由：不动 `dtb` 分区，也能用我们自己的设备树。
3. 官方脚本里还有 `setenv verify n` —— **校验是关的**，所以理论上不要求签名。

## 五、上次为什么停在雷鸟 logo

`20:05` 那次：镜像确实写进了 `recovery` 槽（读回 md5 与镜像一致），BCB 也是 `boot-recovery`，
但屏幕一直停在 mboot 画的 logo，网络和 adb 都没有。

两种解释至今无法区分：

| 解释 | 现象 |
|---|---|
| mboot 没跳进我们的镜像 | 屏幕就是 mboot 自己的 logo，一动不动 |
| 内核跑了但很早就死 | 没有 fbcon、没有网卡驱动，屏幕同样是 logo |

**因为没有串口，这个分叉只能靠"让内核自己上色"来判定** —— 见下一节。

## 六、框架缓冲信标：把 logo 变成四种颜色

`arch/arm64/kernel/head.S` 在我们代码的第一条指令处就把扫描缓冲区涂成**品红**；
`setup_arch()` 解析完设备树涂**绿**；跑完 `setup_arch()` 涂**蓝**。填色函数在
`m7642-dtb.S`，只用寄存器、不碰栈，MMU 没开也能跑（`0x2d100000`，1920×1080×4 = `0x7e9000`）。

| 屏幕 | 含义 | 下一步 |
|---|---|---|
| 一直是 logo | mboot 没跳到我们的镜像 | 查 boot image 头（`ANDROID!`、`kernel_size`、页对齐）、`mmc write.p` 的 flag |
| 品红 → 不动 | 跳进来了，死在设备树/分页之前 | 查 DT 结构与加载地址 |
| 品红 → 绿 → 不动 | 设备树解析过，死在 `setup_arch()` 里 | 查 memory 节点、timer、GIC |
| 品红 → 绿 → 蓝 → 不动 | 内核主体在跑，卡在驱动/initcall | 那时 fbcon 应该已经能出字，看是否 `console=tty0` 生效 |
| 品红 → 绿 → 蓝 → 文字 | 完全启动 | 收工，开始写驱动 |

这套信标本身也是**零风险**的：它只在我们的内核里，跑不到就什么都不发生。

## 七、操作手册

### A. 先验证 BIN 版式（零风险，一次按键）

盘里只放 `m7642-misc-stock.bin`，改名 `MstarUpgrade.bin` → 按键强制升级。
它写回的 `misc` 与当前内容等价，成功后设备照常进 Android。

- 成功：说明我们自制的 BIN 被 mboot 接受，后面所有盘都可用；
- 失败（直接正常开机）：版式或脚本被拒，退回去试 40 字节社区版式 / 去掉 `mmc erase.p`。

### B. 试内核（一次上电）

盘里放 `m7642-recovery-ours-boot.bin`，改名 `MstarUpgrade.bin`，按键强制升级。
刷完它会带着 `BCB=boot-recovery` 重启，于是**下一次上电就进我们的内核**，看颜色。

### C. 退回来（三十秒）

换 `m7642-misc-stock.bin` 再按键升级一次；或者如果 Android 还能起来，直接 `adb` 跑
`tools/host/boottest.sh disarm`。

## 八、待验证清单

### 第一次实测（2026-11-17 21:33）：只写 `misc` 的 20 KB 盘**被拒**

按键强制升级、盘里是 `m7642-misc-stock.bin`（20 512 字节），屏幕**没有任何进度界面**，
直接正常开机。这与 v3/v4 的症状一致 ⟹ mboot 在执行脚本之前就拒了这个包。

可能的原因（按可疑度排序）：

| # | 猜测 | 反证/验证方法 |
|---|---|---|
| 1 | mboot 在升级期间自己管 `misc`（写 BCB），脚本里出现写 `misc` 就拒 | 换成只写 `recovery` 的盘（`m7642-recovery-only.bin`） |
| 2 | 脚本区必须有与 `0xb74aabba` 匹配的签名，换个脚本就对不上 | 同上：只要"只写 recovery"也被拒，且 CRC 已正确，就基本坐实 |
| 3 | 包太小 / 没有 `mboot`、`tvconfig` 这些"必备分区" | 同上（32 MB 的盘会排除大小因素） |

下一步实验：`m7642-recovery-only.bin`（33 570 848 字节，只写 `recovery`，内容 = 原厂备份，
命令形状与官方脚本完全一致）。它同时能排除「包太小」和「多分区」两个因素，
结果只剩两种解释：脚本可改（那 `misc` 就是禁区），或脚本不可改（自制包路线终结）。

其余待验证：

1. 官方包 `mmc write.p ... 1` 末尾那个 `1` 是什么（保留原样写的，未验证含义）；
2. `setenv MstarUpgrade_complete 1` 是否必须（我们的部分升级盘没有写它，未验证影响）；
3. 品红/绿/蓝三级信标实际能否落到屏幕上（取决于 `simple-framebuffer` 之前 DRAM 是否可写）；
4. 若信标一直是 logo，下一步是把镜像写进 `boot` 槽对比（风险同样可控，解卡盘在手）；
5. 若脚本可改，做一版**保留 `/data` 的全量包**（删 `userdata` 段 + 重算 CRC）。

## 九、物料

| 东西 | 状态 |
|---|---|
| FAT32 U 盘 | 有（28.6 GB，卷标 TVFLASH） |
| 机身实体电源键 | 有 |
| 红外遥控 | 有（只用于开机，不能当输入） |
| USB-TTL 串口线 | **没有**；有它就能直接读 mboot/内核日志，本文档一半的推断可以变成读数 |
