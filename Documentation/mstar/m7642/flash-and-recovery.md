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

### ★ 第四次实测（2026-11-17 23:05）：**成功** —— 闸门是文件名，不是包内容

同一张减法包（19 段、CRC `0xb8b6a99d`、payload 与官方 v5 逐字节相同），**只改了一件事**：
根目录同时放上 `MstarUpgrade.bin` 和 `V8-T652T03-LF1V147.bin`（同内容）。

结果：进度条出现 → 刷完 → **应用全在**（Projectivy / F-Droid / tv-quiz 都没丢）。

⟹ 三个结论同时成立：

1. **`V8-T652T03-LF1V147.bin` 这个文件名是必需的**（或至少"双文件名"是必需的）。
   mboot 找升级包的逻辑是 prefix + postfix 拼接（`filenamefind %s .bin`、
   `not found %s%s, try vendor partition !`），TCL 配的前缀是 `V8-`；
   根目录只有一个 `MstarUpgrade.bin` 时**根本不会去读它**。
2. **脚本可以改**，删 `userdata` 段 + 重算 header CRC 就被接受 ⟹
   **「刷机不擦 `/data`」成立**，拿到了一个能保住应用与设置的全量刷机包。
3. **命令条数不是闸门**（147 条 vs 官方 150 条照样过），`check_script_cmd_count`
   只防空脚本/溢出，不是"必须 150 条"。

#### 补记（23:20）：`/data` 不是被脚本擦的，是 mboot 自己擦的

上表那次"成功"刷完后，`/data/app` 为 0 个应用、`/data/data` 0 个包、
`/data/system/packages.xml` 时间戳是刷机后首次启动（23:15）。即 **`/data` 被格式化了**，
"保住 `/data`"这个目标没达成。

关于 WiFi 密码：用户观察到刷这个包后 WiFi 还在，而**刷官方完整包后 WiFi 密码会没有**。
这条差异说明 WiFi 配置并非存在不受影响的 `persist` 里（`persist`/`MPOOL`/`eeprom_a`
两个包都不写，两种情况本该一样）。配置实际位于 `/data/misc/wifi/WifiConfigStore.xml`
（里面能看到 `zzz_5G`），即位于被格式化的分区内 ⟹ **TCL 在刷机后另有一步恢复它，
机制未查明**。这一点先记为观察，不当作结论。

原因在 mboot 里：

```
do_wipe_datacache_check
do recovery wipe data or cache.
```

⟹ **按键强制升级这条路径下，mboot 自己会擦 data/cache**，与脚本里有无
`mmc erase.p userdata` 无关。所以「删 userdata 段以保住数据」这个思路从一开始就不成立，
之前所有围绕它的推理都白费。

**推论**：想保住数据，唯一可能是**不触发 wipe 判断**，而 wipe 判断大概率挂在
「升级了 system/vendor」上。所以**只写 `recovery` 的部分升级包**才是换内核的正确路径——
它不碰 system/vendor，应当不触发 `do_wipe_datacache_check`。
mboot 里的 `do_usb_partial_upgrade_to_emmc`（日志 `partial upgrade from USB to eMMC`）
正是为这种场景准备的。

#### 前面三次失败全部归因错误

| 时间 | 包 | 当时的结论 | 真实原因 |
|---|---|---|---|
| 21:33 | 20 KB 只写 `misc` | "misc 是禁区" | 单文件名，没被读 |
| 21:57 | 32 MB 只写 `recovery` | "`0xb74aabba` 是签名" | 单文件名，没被读 |
| 22:30 | 3.3 GB 删 `userdata` | "20 个分区段必须齐全" | 单文件名，没被读 |
| 23:05 | 同上 + `V8-` 文件名 | — | **成功** |

教训：**先确认包被读到了，再讨论包内容**。"没有任何进度界面、直接正常开机"这一现象
对「包被拒」和「包没被找到」是完全一样的，而我三次都把前者当成了唯一解释。
唯一的区分线索是文件名布局，而它一直在我的视野之外。

**因此「自制包」这条线重新打开**：payload 可以随意换（v5 已证明 AllBinCRC 不强制），
脚本也可以改，只要 (a) 根目录有 `V8-*.bin` 这个名字、(b) header CRC 重算正确。
这意味着可以用 U 盘直接刷入自定义的 `recovery` 分区镜像来试内核，不必依赖 adb。

mboot 里另有 `do_usb_partial_upgrade_to_emmc` / `usb_partial_upgrade_to_emmc`
（日志串 `partial upgrade from USB to eMMC`），触发条件仍未解；但现在已知
单/双文件名的影响，可以把它作为下一步的一个变量去试。



## 九、部分升级包：从官方包里裁出任意分区子集

`tools/host/rescue/mk-partial.py`：读官方 3.3 GB 包，按 `# File Partition:` 段
挑出指定的几个，重排 payload（只改 `filepartload` 的偏移，其余行原样），重算
header CRC，AllBinCRC 沿用原厂值。

```
mk-partial.py --src V8-T652T03-LF1V147.bin --keep recovery,set_config -o out.bin
mk-partial.py --src V8-T652T03-LF1V147.bin --keep recovery --dry-run   # 只打印脚本
```

已生成（`/home/emfox/kbuild/rescue/partial/`，payload 与源包逐字节一致，md5 同源段）：

| 包 | 段 | 大小 | header CRC |
|---|---|---|---|
| `m7642-reconly-full.bin` | recovery + set_config | 27 488 288 | `0x23192646` |
| `m7642-reconly-min.bin` | recovery | 27 488 288 | `0x56056f91` |

### 为什么先刷这个（零风险）

payload 就是**原厂 recovery 镜像本身**，所以刷完 recovery 分区内容与现在完全一样；
boot/system/vendor 一字不动，唯一的副作用是 `misc` 被擦（BCB 清空，本来也该清）。
它只回答两个问题：

1. 只含 1 个分区段的包，mboot 认不认（段数/大小是不是闸门）；
2. **不碰 system/vendor 的部分升级会不会仍然触发 `do_wipe_datacache_check`**。

第 2 点是关键：过 ⟹ 保 data 刷机有了正路，以后换内核只写 recovery；不过 ⟹
wipe 与写了什么无关，得从 `MstarUpgrade_complete` 一类环境变量上想办法。

判读：插盘上电，出现进度界面 = 包被读到；刷完进系统后看应用还在不在。

### 第五次实测（2026-11-17 23:30）：单段包被接受，但**仍然擦 data**

刷 `m7642-reconly-full.bin`（recovery + set_config，27.5 MB）：

- 出现进度条，几秒钟完成 ⟹ **段数不是闸门**，27 MB 单段包同样被接受；
- 重启后屏幕出现「正在清除...」，几秒后再次重启进系统 ⟹ **wipe 照样发生**；
- 刷后 `/data/local/tmp` 为空（原先有 `tvquiz/`、`tvroot.out` 等），`/data/app`、
  `/data/data` 均空 ⟹ `/data` 确实被清。

⟹ **上一节那个推论被推翻**：wipe 与「写了 system/vendor」无关。只写 recovery、
boot/system/vendor 一个字节不动，mboot 一样清 data。

剩下两种可能：

1. 只要走 USB 按键升级这条路，mboot 就无条件 wipe（MStar 的「强制升级 = 恢复出厂」常规设计）；
2. 由脚本里的某条命令触发 —— 该包里 recovery 段有 `mmc erase.p misc` +
   `setenv recoverycmd ... ; saveenv`，set_config 段有 `setenv MstarUpgrade_complete 1` +
   `saveenv`。

第 2 条可以廉价地排除：`m7642-reconly-min.bin` 只有 recovery 段，末行是 `saveenv`，
**没有 `MstarUpgrade_complete`**。此刻 `/data` 已经是空的，再刷一次没有额外代价，
是这个变量最好的测试窗口。

### ★ 第六次实测（2026-11-17 23:36）：**没擦 data** —— 保 data 刷机成了

刷 `m7642-reconly-min.bin`（只 recovery 一段，27.5 MB）。刷前在 `/data/local/tmp/`
放了个标记文件 `marker-2332.txt`（内容带时间戳 `23:33:15`），因为 `/data` 已经是空的，
没有参照物就看不出 wipe 有没有发生。

- 进度条照走，几秒钟完成 ⟹ 包被接受；
- 刷完**没有出现「正在清除...」**，直接停在待机，用红外遥控开机进系统；
- **标记文件还在**，内容时间戳未变 ⟹ `/data` 一个字节没动。

⟹ **wipe 不是 USB 升级路径的固定行为，是脚本里的命令触发的。**
两个包只差 `set_config` 段，最可能是 `setenv MstarUpgrade_complete 1`：mboot 升级收尾时
看这个标记，是 1 就当成"官方完整升级完成"，顺手把 data/cache 清掉。

同一个原因也解释了「刷完停在待机、不自动重启」：不设这个标记，mboot 认为升级没收尾，
就不往下走重启。补一条 `reset` 即可，或者在包里保留其余 setenv 只去掉这一条。

**保 data 刷机的配方**（已验证）：

1. 用 `mk-partial.py` 从官方包裁出要写的分区（换内核就只要 `recovery`）；
2. 脚本里**不要**出现 `setenv MstarUpgrade_complete 1`；
3. 头部 CRC 重算，`V8-*.bin` 文件名，双文件名布局。

代价是刷完要手动开机。收益是 data、应用、WiFi 配置全在，27 MB 的包几秒钟刷完。

## 十、不用 U 盘：adb + root `dd` 直接写分区

U 盘那条路每刷一次都要断电、按键、等启动，而且（除非用上面的保 data 配方）会擦 data。
系统正常起来的时候有更快的一条：`/factory/su` 提权后直接 `dd` 写块设备。

### root 从哪来

固件里有 `tvroot` 这个 init 服务，由 `/vendor/etc/init/tvgate.rc`（vendor 分区，刷机不会动）
拉起 `/data/local/tmp/tvquiz/gate.sh`，以 root 跑。**data 被清空后这个服务只是少了脚本，
`/vendor/etc/init/tvgate.rc` 还在** —— 把 `tv-quiz` 的文件推回去（`tools/install.sh`），
服务立刻恢复，**不需要重启电视**：

```
cd ~/Debian/tv-quiz && ADB=~/Debian/tv/adb/platform-tools/adb tools/install.sh
ADB=~/Debian/tv/adb/platform-tools/adb tools/tvroot.sh 'id'
```
```
uid=0(root) gid=0(root) groups=0(root),1000(system) context=u:r:shell:s0
```

`tvroot.sh` 的做法：命令写到 `/data/local/tmp/tvroot.cmd`，由服务执行、结果写回
`tvroot.out`，主机侧轮询回读（上限 15 秒，命令里不要放长 sleep）。

### 分区映射（实测）

```
/dev/block/by-name/recovery -> /dev/block/mmcblk0p7   32768 KB = 32 MB
```

校验方式（零风险，纯读）：按官方镜像长度取分区前缀算 md5，与官方包的 recovery 段比对：

```
dd if=/dev/block/by-name/recovery bs=4096 count=6707 | md5sum     # 4096*6707 = 0x1a33000
```

实测得到 `0d6e895a090442fdcb8699e1b583c3d6`，**与官方包 recovery 段的 md5 完全一致**，
既证明前面那次 U 盘刷机确实写进去了，也证明这条读取通道可信。

### 写

```
adb push <镜像> /data/local/tmp/new.img
tools/tvroot.sh "dd if=/data/local/tmp/new.img of=/dev/block/by-name/recovery bs=4096; sync"
```

不清 data、不断电、几秒完成。注意镜像长度要 ≤ 分区容量，`dd` 不会替你截断分区；
写错了还能用 U 盘那条路救回来。

## 十一、物料

| 东西 | 状态 |
|---|---|
| FAT32 U 盘 | 有（28.6 GB，卷标 TVFLASH） |
| 机身实体电源键 | 有 |
| 红外遥控 | 有（只用于开机，不能当输入） |
| USB-TTL 串口线 | **没有**；有它就能直接读 mboot/内核日志，本文档一半的推断可以变成读数 |

## 十一、陷阱：`adb reboot recovery` 会把设备锁在 recovery 循环里

2026-11-18 00:0x 踩到的。用 `adb reboot recovery` 试内核，内核起不来（卡 logo），
屏幕一直停着。以为断电重上电就能回系统，**结果还是卡 logo**。

原因在 BCB（`misc` 分区）：`adb reboot recovery` 往里写了 `boot-recovery`。
正常情况下 recovery 启动后会自己清掉这个标记，可这次内核压根没跑起来，
recovery 的 init 一行都没执行 ⟹ 标记一直留着 ⟹ **每次上电 mboot 都往 recovery 走**。
`boot` 分区完好无损，只是永远轮不到它。

这不是砖，是死循环。解开只需要擦 `misc`。最省事的办法是刷一个含
`mmc erase.p misc` 且不设 `MstarUpgrade_complete` 的包 —— 例如
`m7642-reconly-min.bin`（官方 recovery + 擦 misc，且不擦 data）：

```
拔电 → 按住机身电源键 → 插电 → 进度条 → 刷完停待机 → 红外开机
```

教训：**凡是 `adb reboot recovery` 去试一个没验证过的镜像，都要先确认自己有一个
「能擦 misc」的 U 盘包在手边**。否则一次失败就得多绕一圈物理操作。

（`mmc erase.p misc` 在官方脚本的 recovery 段里本来就有，所以任何裁自官方包的
recovery 子集包天然带这条命令。）

### 实测（2026-11-18 00:01）：min 包成功解锁，而且保住了 data

按上面的办法刷 `m7642-reconly-min.bin`，设备恢复。三项验证全过：

```
misc(mmclk0p6, 8MB) 前 32 字节  00 00 00 00 ...（全 0）   ⟹ BCB 已清
recovery 前 0x1a33000 md5       0d6e895a090442fdcb8699e1b583c3d6  ⟹ 官方镜像已写回
/data/local/tmp/marker-2332.txt 时间戳仍是 23:33          ⟹ data 没被动过
pm list packages                 projengmenu + fdroid 都在
```

⟹ **「保 data 配方」在救砖场景下同样成立**：擦 BCB、写回官方 recovery、data 一个字不动。
这是目前最理想的救援动作，比 3.3 GB 官方全量包（会擦 data）好得多。

## 十二、★ 首选救砖包：`rescue-fast.bin`（47.3 MB，保 data，约 4 秒）

2026-11-19。min 包只修 p6/p7，一旦坏到 p8（boot）或 env（`bootcmd`）就无能为力。
这个包把"内核实验真正会碰坏的东西"一次全覆盖，同时保持保 data、保持快。

| 项 | 值 |
|---|---|
| 产物 | `~/kbuild/backup/fix/rescue-fast.bin` |
| 大小 / md5 | 47,263,776 B / `7e8ef7a725e163672af7fb824b066abc` |
| 生成工具 | `~/kbuild/backup/mkrescue.py` |
| 覆盖 | p6 misc（擦）、p12 dtb、p7 recovery、p8 boot、`bootcmd`/`recoverycmd`/`WDT_ENABLE` |
| 不覆盖 | system / vendor / userdata / optee / tvservice / factory_a |
| 尾部 | `crc32(header)=0xc773300f`，常量 `0xb74aabba`，`hdr[:16]` 一致 |

脚本顺序（三段都用**厂方自己的长度**，见下）：

```
mmc erase.p misc
filepartload … 0x4000    0x5AF3     → dtb      ; erase.p dtb      ; write.p dtb 0x5AF3 1
filepartload … 0xA000    0x1A33000  → recovery ; erase.p recovery ; write.p recovery 0x1A33000 1
filepartload … 0x1A3D000 0x12D5800  → boot     ; erase.p boot     ; write.p boot 0x12D5800 1
setenv bootcmd mmc read.p … boot …\; bootm …        ← 不带 saveenv 前缀
setenv recoverycmd mmc read.p … recovery …\; bootm …
setenv WDT_ENABLE 0
saveenv
```

脚本里**没有** `MstarUpgrade_complete`，这是故意的，理由见第十三节。

**为什么能比 68 MB 那个小 20 MB**：早先按分区容量写（32 MiB × 2），而厂方脚本只写镜像
本身长度（recovery `0x1A33000` = 27.5 MB、boot `0x12D5800` = 19.7 MB）。改用厂方长度后
载荷 47.2 MB，USB 读取时间从约 5 s 降到约 3 s，eMMC 写入量也少 20 MB。

**为什么不能省掉 `saveenv`**：`bootcmd` 一旦被 `-wdt` 那版污染（前缀 `saveenv\;`），
每次启动都会布防一只 **5 秒**看门狗（不是 205 秒，见 `boot-test.md` §57 更正），
正常 Android 首启必然超时 ⟹ 自己造出"logo → 几秒 → 待机"的循环。
这个包把 `bootcmd` 重置成厂方原文并落盘，是唯一能一次性解掉的动��。

**长度与偏移校验**（回读文件按脚本声明的偏移取 md5）：

```
dtb        off 0x00004000 len 0x5AF3    5dae157554e3596ac5b77ddaca918380  SAME
recovery   off 0x0000A000 len 0x1A33000 0d6e895a090442fdcb8699e1b583c3d6  SAME
boot       off 0x01A3D000 len 0x12D5800 f9fce8e1a61c92060f62f4ca7392797f  SAME
```

用法：U 盘上改名为 `V8-T652T03-LF1V147.bin`（mboot 只认这个名字），
断电 → 按住机身电源键 → 插盘上电 → 进度条走完 → 停待机 → 按电源键开机。

## 十三、`MstarUpgrade_complete` 到底有没有"默认值"

2026-11-19 追问。「不设它会不会被当成 1，从而把 /data 清掉？」

### 1. 没有"默认值"这个东西

U-Boot 环境变量只有两种状态：**存在**或**不存在**。不存在时 `getenv()` 返回 `NULL`，
没有"未设置则取 1"这种缺省机制。所以"默认值是多少"这个问题本身不成立，
真正该问的是两件事：**变量现在是什么值**、**不设它时值会怎么变**。

### 2. 这台机器上它不是"不存在"，而是明确等于 0

2026-11-18 22:48 从设备 dump 的 env（`~/kbuild/mpool3.bin`，主备两份副本）都是：

```
MstarUpgrade_complete=0
```

### 3. 不设它，实测不会清 /data

第六次实测（2026-11-17 23:36，见 §十）：`m7642-reconly-min.bin` 只有 recovery 段，
末行 `saveenv`，**整个脚本没有 `MstarUpgrade_complete`**。刷完结果：

- 没有出现「正在清除...」；
- 事先放的标记文件 `marker-2332.txt` 还在，时间戳未变 ⟹ `/data` 一个字节没动。

若"不设即视为 1"，这次必然 wipe。所以**不设 ≠ 1**，这条是行为层实证，不依赖反汇编。

### 4. mboot 自己会把它清 0

`mboot16.bin` 里 `0x290a02`（VA `0x27690a02`）有一段内置字符串：

```
setenv upgrade_mode
setenv MstarUpgrade_complete 0
setenv upgrade_status
setenv force_upgrade
```

旁边还有格式化串 `setenv %s 0;saveenv`、`setenv %s 0` 和日志 `last upgrade complete`，
在 `0x28fe82` 一带（与 `recoverycmd`、`reboot-bootloader` 同池）。⟹ 升级流程开始时会把它
置 0，脚本里若出现 `setenv MstarUpgrade_complete 1`，收尾才被当成"官方完整升级完成"。

这也解释了 dump 为什么是 `0` 而不是 `1`：即便上一次全量包设过 1，下一轮升级开始时又被清回 0。

> **证据强度说明**：第 4 条是"字符串存在 + dump 为 0"的间接证据。试过 `add rX,pc,#imm`
> （基址无关）、`add rX,pc,rY`、literal 绝对地址、`movw`/`movt`（含机器码直接搜索）四种方式
> 追引用，全部 0 命中——该镜像代码与数据混排，字符串引用方式没能静态确定，控制流未实证。

### 5. 历史序列反证了"继承值会 wipe"这个担心

一度担心：不设的语义是"保持 env 现值"，而官方全量包末尾 `setenv MstarUpgrade_complete 1`，
那么全量包刷完之后再用不设的包，会继承 1 从而 wipe。**这个担心被实测否掉了。**

把本机 24 个自制包的脚本全扫一遍（`~/kbuild/scan_pkgs.py`），结果只有一个包设过这个变量：

| 包 | `MstarUpgrade_complete` | 刷后结果 |
|---|---|---|
| `m7642-reconly-full.bin` | **1**（官方 set_config 原样保留） | **清了 /data** |
| 其余 23 个（含 `reconly-min`、全部 misc 包、`rescue-fast`） | 都没有 | 都没清 |

而这两次刷机是连着的：

```
23:30  刷 reconly-full   → 设 1 + saveenv → wipe
23:36  刷 reconly-min    → 脚本里没有这个变量 → 没 wipe，标记文件还在
```

中间只隔 6 分钟。reconly-full 刚 `saveenv` 过 1，所以 23:36 开始时 env 里**几乎必然还是 1**。
若"不设 = 继承 1 = wipe"，那次必然再清一遍，但它没有。⟹ **不设不会因为继承值而 wipe。**

### 6. 自洽的模型，以及为什么不要画蛇添足

唯一能同时解释全部观测的模型：

```
升级开始   mboot 无条件 setenv MstarUpgrade_complete 0
脚本中     只有在脚本显式 setenv ... 1 时才变 1
收尾       值 == 1 → 视作"官方完整升级完成" → wipe data/cache + 自动重启
           否则 → 不 wipe，停在待机（需按电源键）
```

逐条对账：

| 观测 | 模型解释 |
|---|---|
| 23:30 reconly-full（设 1）→ wipe | 收尾值 1 |
| 23:36 reconly-min（不设）→ 不 wipe | 开始时被清 0，收尾仍是 0 |
| 全量包 → 清 data 并自动重启 | 脚本设 1 |
| `mpool3.bin` 里是 `0` 而不是 `1` | 最后一次刷的是不设的包，收尾落盘 0 |
| 11-18 连刷多个不设的包，值仍是 0 | 每次开始都被清 0 |

在这个模型下，"显式 `setenv MstarUpgrade_complete 0`" 与"完全不提这个变量"**完全等价**——
因为开始时它已经是 0 了。加那行不会更安全，只是多一条没人验证过的命令。

所以 `rescue-fast.bin` **不设它是正确的**，也是那些写 misc 的包一贯的做法；
它们"一直不清 data"不是运气，是这套机制的正常结果。

> 反面教训：我曾按"继承值"假设给包加了一行 `setenv MstarUpgrade_complete 0`，
> 属于在没验证的假设上做"加固"。已撤回，产物 md5 回到 `7e8ef7a725e163672af7fb824b066abc` / CRC `0xc773300f`。

## 十四、设备为何反复起不来：是复发，不是一次事故

2026-11-19 早上出现「logo → 约 3 秒 → 回待机」。查证后结论是**同一症状第二次出现**，
中间隔着一次成功的全量刷机和数小时正常运行。

### 1. 两条曾被当成判因、实际不成立的说法

| 说法 | 为什么错 |
|---|---|
| misc 里残留 `boot-recovery` ⟹ recovery 死循环 | v5 包脚本第 19 行就是 `mmc erase.p misc`，每次刷机都擦净 |
| `bootcmd` 被 `-wdt` 版污染 ⟹ 每次布防 5 秒狗 | v5 包 `set_config` 段有 `setenv WDT_ENABLE 0`，且 `bootcmd` 已重写为官方串 |

取证命令（16 KiB 头就是明文脚本）：

```sh
dd if=X.bin bs=1 count=16384 | tr -d '\000'
```

### 2. 时间线（同一症状两次出现）

| 时间 | 事件 |
|---|---|
| 11-19 凌晨 | 「logo → 3 s → 回待机」，每次按键只有一次启动机会 |
| 之后 | 刷 v5 全量包 → **完全救回** |
| 数小时内 | 设备持续可用：部署 tv-quiz/Projectivy、`status.sh` 全绿、跑测试、编译安装 su、推 3 次 GitHub |
| 01:5x | 设备停在待机；该小时只做静态产物（`mk-ladder.py`），未接触设备 |
| 06:2x | 用户开机 → 又是「logo → 3 s → 黑」 |

### 3. 复发说明什么

分区内容刷完即固定。病若在 `boot` / `dtb` / `misc` / `recovery`，刷 v5 之后不可能
几小时又坏。**能"刷完好了、跑一阵又坏"的，只能是运行期写入的持久数据，或硬件。**

运行期动过的持久位置，按嫌疑排序：

| 位置 | 动作 | 嫌疑 | 依据 |
|---|---|---|---|
| `/data` | dex2oat、应用数据、日志，写入量最大 | **高** | 与第十一节结论一致 |
| `/vendor/etc/init/*.rc` | 手工装的 `lchome.rc`、`tvgate.rc` | 低 | 只影响 `boot_completed` 之后 |
| `/system/bin/su` | `-t` remount 写入 6755 的 mksh | 低 | `device/su/install.sh` 里 `sync` 在 `remount,ro` 之前，且用 `mv -f` 原子替换 |

### 4. ★ 自我强化循环（最重要的一条）

「回待机」是 PM51 直接切电，**不是正常关机**，等于硬断电。ext4 在反复硬断电下会损坏，
而损坏又让下一次启动更容易失败。

⟹ **每一次失败的启动尝试都在继续伤 `/data`。**
⟹ 设备起不来时**不要反复"按一下看看这次行不行"**。要观测就一次做完。

### 5. 选包判据：这个包碰不碰 `/data`、`/system`、`/vendor`

| 包 | 大小 | 写的分区 | `/data` |
|---|---|---|---|
| `rescue-fast.bin` | 47.3 MB | misc · dtb · recovery · boot | 保 |
| `v5-system-full.bin` | 3.0 GB | misc · dtb · recovery · boot · **system** · **vendor** | **保** |
| `V8-T652T03-LF1V147-v5.bin` | 3.3 GB | 全部 | 清 |

boot/dtb/misc/recovery 已验为厂值时，只写这四个的包（如 `rescue-fast.bin`）**属于白刷**——
病灶大概率在它不碰的地方。

判读链：

```
刷 v5-system-full.bin（保 data）
  ├─ 能进系统  ⟹ 病在 system/vendor，data 无辜
  └─ 仍 3 s 回待机 ⟹ 病在 /data，再刷全量包（清 data）
        └─ 全量刷完仍 3 s ⟹ 病不在软件，在 eMMC 或 PMIC
```

### 6. 刷前静态校验：`tools/host/pkgcheck.py`

设备没有错误通道——坏包和找不到包表现完全一样（无进度条、直接开机）。所以能在主机
做的检查必须做完再走过去。

```sh
python3 tools/host/pkgcheck.py <pkg.bin>
```

检查项：

1. footer 四件：`"12345678"` · `crc32(header)` · 常量 `0xb74aabba` · `header[0:16]` 回指
2. 脚本终止符 `% <- this is end of script symbol` 存在，其后只有 0xFF/0x00 填充
3. 每条 `filepartload` 的 `offset + size` 不越出 payload 区
4. 打印实际会被 erase 的分区列表
5. 打印 `MstarUpgrade_complete` / `WDT_ENABLE` / `bootcmd` / `recoverycmd` 的实际取值，
   并明确给出「会不会清 /data」

最后一行 `RESULT: PASS|FAIL` 可直接作为刷机前的放行条件。

### 7. 第三次复发（2026-11-20 23:05）

同一症状第三次出现，与 §十四.2 的两次隔了一天多。这次触发动作有明确记录：

```
23:05:03  echo 1 > /proc/sys/kernel/sysrq; sync; sync; echo b > /proc/sysrq-trigger
23:07–09  轮询 adb，30 次全空（设备不再回到 Android）
23:13     用户：按电源 → logo 3 秒 → 回待机；拔电 15 s 后重试，同样
```

目的本是用 soft reset 验 DDR 跨复位保留（`wdt-beacon.md` §十 §7 那条未验证前提），
结果直接复现了已知病灶。

**为什么 `sysrq b` 能一击致命**：它走 `machine_restart`，不 umount、不等写缓存落盘；
而本机 `/data` 早已处在「回待机 = PM51 切电 = 硬断电」的自我强化循环里（§十四.4）。
它不是写坏了哪个分区，而是给一个脆弱的 `/data` 又补了一次非正常断电。

**这次新增的可复核事实**：

| 事实 | 证据 |
|---|---|
| U 盘根目录放的是 `rescue-norecovery`（md5 `326132c7…`），脚本里 recovery 段被整段注释 | 16 KiB 头明文，只有 `# File Partition: recovery` 而无 `filepartload`/`mmc write` |
| 同名同尺寸（47,263,776 B）的 `rescue-fast`（md5 `7e8ef7a7…`）**有** recovery 段 | 同上，`filepartload 0xA000 0x1A33000` + `erase.p` + `write.p` |
| 所以"U 盘里有救砖包"不等于"能修 recovery 槽" | 两个包文件名相同、大小相同、CRC 都合法，只看名字分不出来 |
| `panic=0`、`sysrq=0`（默认关） | `/proc/sys/kernel/{panic,sysrq}` 实测；`echo c` 只会挂死 |

**这轮该刷的其实不是任何一个 47 MB 包**：boot/dtb/misc/recovery 已验为厂值时，
只写这四个的包属于白刷（§十四.5）。按判读链应刷保 data 的 system+vendor 包：

| 包 | 大小 | md5 | 擦写分区 | /data |
|---|---|---|---|---|
| `backup/fix/V8-T652T03-LF1V147.bin` | 3,077,484,576 | `3aab78e4a1f980d5d5fe817fcce795fe` | misc · recovery · boot · dtb · **system · vendor** | **保** |
| `Debian/tv/rom/V8-T652T03-LF1V147-v5.bin` | 3,335,655,456 | `6c7b2a00ff589678773cab1f838bb7b7` | 全部 | 清 |

前者 `pkgcheck.py` 报 `RESULT: PASS`、`MstarUpgrade_complete` absent ⟹ 不清 `/data`。

### 8. 复盘的边界：全量包救回 ≠ 病灶就是 `/data`

2026-11-21 00:05，刷原厂全量包（3,335,655,456 B，md5 `6c7b2a00…`）后设备正常启动，
adb 回到 `unauthorized`（`/data` 已清，`adb_keys` 没了，符合预期）。

**但这不能单独证明病灶在 `/data`。** 全量包擦了 18 个分区：

```
tvconfig misc recovery boot optee armfw RTPM dtb frc cm4
cache tcluserdata tclconfig system vendor tvservice factory_a userdata
```

而前面那个 3.0 GB 包只写了 `misc recovery boot dtb system vendor`，它失败 ⟹ 只能排除这 6 个。
剩下的 12 个（含 `userdata`、`cache`、`tvconfig`、`optee`、`tclconfig`、`tvservice` …）都在嫌疑名单上。

⟹ **正确的表述是**：病灶在这 12 个之中，`/data` 是其中最可疑的一个，不是唯一结论。
我中途写过"病灶确认在 /data"，那是过度推论，撤回。

**为什么仍把 `/data` 排在第一位**：

| 依据 | 强度 |
|---|---|
| 只有它是高频写入（dex2oat、日志、应用数据） | 推论 |
| 11-19 两次同症状，第二次是**整夜没操作**、早上开机就坏 ⟹ 会自己发作 | 实测 |
| 只读分区不可能"刷完好了、跑几小时又坏" | 推论 |
| `cache` 也可能（Android 会读 `/cache/recovery/*`），但写入频率低得多 | 未排除 |

**要唯一定位，下次的刷机顺序应该是**（每次一个包，二分）：

```
只擦 cache           → 好 ⟹ 病灶在 cache
只擦 userdata + 空镜像 → 好 ⟹ 病灶在 userdata
只擦 tvconfig        → 只擦 optee/tvservice/tclconfig …
```

代价是每次一次 U 盘往返。今晚没做，是因为已经把整晚耗在救砖上。

**顺带记录的教训**：自制的 `sparse_write` 包两次都在 mboot 报 ERROR（进度条一闪）。
payload 偏移已验（两处都是 `3aff26ed` sparse 头），`filepartload` 与 `mmc write.p` 同款也能刷
（`rescue-fast` 成功过），所以问题在 `sparse_write` 这条路径本身——参数或前置条件，
我没有静态证据。以后要再试，先做**只含一条 `mmc erase.p cache` 的探针包**把变量拆开，
不要一次把两条新命令塞进同一个包。
