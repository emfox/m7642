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
直接正常开机。

### 第二次实测（2026-11-17 22:01）：只写 `recovery` 的 32 MB 盘**也被拒**

`m7642-recovery-only.bin`（33 570 848 字节，写原厂 recovery，命令形状与官方逐字同形）。
这一次按住机身键到第 5 秒时**指示灯闪了几下**（按键被识别、mboot 动了），第十几秒正常开机，
仍然没有进度界面。

### 于是从 mboot 里找闸门：校验有两个，不是一个

`strings mboot.bin` 里有这些符号与格式串：

```
check_script_crc                 Calculate HeaderCRC = 0x%x    Binary HeaderCRC = 0x%x
check_full_usb_crc               Calculate AllBinCRC = 0x%x    Binary AllBinCRC = 0x%x
                                 Bad header crc   !bad CRC   BIN_CRC = 0x%x, crc = 0x%x
```

⟹ footer 里那两个 32 位字段不是「header CRC + 常量」，而是 **header CRC + AllBinCRC（整包
payload 的 CRC）**。

### 但 AllBinCRC 并没有被强制（被真机证据否掉）

| 包 | 脚本 | header CRC | AllBinCRC 字段 | 真机 |
|---|---|---|---|---|
| 官方 | 原样 | 对 | 对 | 能刷 |
| v5 | **原样** | 对 | **错**（payload 改过，字段还是原厂的） | **能刷** |
| v3 / v4 | 改过 | **错**（没重算） | 对 | 被拒 |
| 自制 20 KB / 32 MB | 全新 | 对 | 错 | 被拒 |

v5 是决定性反例：payload 改过、AllBinCRC 早就对不上，照样刷进去两次。⟹ 这个校验要么被
`verify` env 关着，要么只在特定路径上跑。

**也排除「版本要比机器新」**：救砖时刷的就是同版本（V147 刷 V147）的官方包，成功了。
（这条路一度看起来最像，因为电视自带「本地升级」会报"无可升级版本"，但那是 UI 自己的判断。）

**「缺板级分区」这个假设已被证伪**（2026-11-17 22:10）。逐包统计 `# File Partition:`：

```
官方      20 段: tvconfig,mboot,recovery,boot,optee,armfw,RT_PM,dtb,frc,cm4,mbootbak,...
v3        19 段: 同上，只少了 userdata（板级分区 tvconfig/mboot/mbootbak 全在）
v4        20 段: 与官方逐段相同
v5        20 段: 与官方逐段相同
```

v3 有全部板级分区、v4 结构与官方完全一致，两者都被拒 ⟹ 板级分区不是闸门。

**真正的第二条闸门：脚本命令条数。** mboot 内建符号表里有连续一串函数
（`check_script_crc` → `check_script_cmd_count` → `read_dynamic_script_size` →
`LoadScript2DramByUsb` → `_check_upgrade_script_cmd_count` → `get_script_next_line` →
`loadscript` → `runscript_linebyline`），配套日志串 `Empty Script`、
`Size is not enough, Cmd Too Many !!!!!!!!!!!!!!!!!`。实测脚本命令条数：

| 包 | 命令数 | 脚本 | header CRC | 结果 |
|---|---|---|---|---|
| 官方 / v5 | 150 | 原样 | 对 | 能刷 |
| v3 | 147 | 删 userdata 段 | 错（没重算） | 被拒 |
| v4 | 150 | 改一行 bootargs | 错（没重算） | 被拒 |
| 自制 20 KB / 32 MB | **3** | 全新 | 对 | 被拒 |

⟹ 两个假设各管一半、互不矛盾：**v3/v4 死于 header CRC 没重算；自制的两张盘死于命令数
只有 3 条**（被当成 `Empty Script`）。这也解释了为什么重算 CRC 之后仍被拒 —— CRC 不是我那
两张盘的死因。具体阈值未知（只知道有这个检查），但 147 与 3 之间差了两个数量级。

旁证：mboot 里还有 `setenv MstarUpgrade_complete 0`（升级开始时置 0）与官方脚本末尾的
`setenv MstarUpgrade_complete 1`（升级完成后置 1）。这是"升级未完成则下次上电续刷"的标记
机制，也是"升级中途绝不能断电"的成因。

`0xb74aabba` 的算法也还没对上：官方包试了 8 种 CRC-32 变体（反射/非反射 × init 0/0xFFFFFFFF
× xorout 0/0xFFFFFFFF）与 3 种覆盖范围（`[0x4000,EOF-32)`、`[0,EOF-32)`、`[0x4000,EOF)`），
最接近的是标准 CRC-32 的 `0x164cb165`，全不匹配。mboot 里另有 `hw_crc32_04C11DB7`，
可能是硬件 CRC 单元的分块口径。

### 第三次实测（2026-11-17 22:30）：减法包也被拒 —— 结论收敛了

用 `patch-header.py` 在 U 盘上就地把 v5 包删掉 `userdata` 段并重算 CRC，实测按下机身键
第 5 秒指示灯闪动、十几秒后**直接正常开机，没有任何进度界面** ⟹ 第三次被拒。

这张盘是**最接近官方的一版**，差别只有一节：

| 项 | 官方 v5 | 减法包 |
|---|---|---|
| 文件大小 | 3 335 655 456 | 3 335 655 456 |
| payload md5 | `10f530ce…` | `10f530ce…`（逐字节相同） |
| 分区段数 | 20 | **19**（少 `userdata`） |
| 命令条数 | 150 | 147 |
| footer `crc32(header)` | `0xedd2f756` = 重算值 | `0xb8b6a99d` = 重算值 |
| footer tag 回指 | 正确 | 正确 |

⟹ **CRC 与命令数两个解释都失效**（这一版两者都对）。剩下的解释只有一个：
`MstarUpgrade.bin` 这个全量升级入口要求**脚本的 20 个分区段必须齐全**，删任何一段都被
当成不完整包拒掉。这也回过头解释了 v3（当年删的正是 `userdata`）——它很可能不是死于 CRC。

三次自制/改造包的实测全部失败（20 KB 只写 `misc`、32 MB 只写 `recovery`、3.3 GB 删一节），
每次都只能验证一个假设，且都需要人工跑到电视机前按机身键。**这条路到此停止投入**：
在 `MstarUpgrade.bin` 入口下"自制包"与"保 `/data` 刷机"都做不到。

mboot 里确实存在 `do_usb_partial_upgrade_to_emmc` / `usb_partial_upgrade_to_emmc`
（日志串 `partial upgrade from USB to eMMC`），但它的触发条件（另一文件名？env？boot mode？）
在静态分析里没找到——`mboot.bin` 的字符串引用不是简单的字面量池或 `adr`，
用文件偏移与加载基址 0x27400000 两种口径都扫不到，继续挖的性价比不高。



## 九、物料

| 东西 | 状态 |
|---|---|
| FAT32 U 盘 | 有（28.6 GB，卷标 TVFLASH） |
| 机身实体电源键 | 有 |
| 红外遥控 | 有（只用于开机，不能当输入） |
| USB-TTL 串口线 | **没有**；有它就能直接读 mboot/内核日志，本文档一半的推断可以变成读数 |
