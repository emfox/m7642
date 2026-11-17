# 远程验证移植效果：不插 U 盘、不按键的可行路径

2026-11-17。约束：人不在电视边，只能 SSH/adb 操作电脑；**不能插 U 盘、不能手按待机键**。

## 一、先看 mboot 有什么本事（从固件里读出来的）

从 `V8-T652T03-LF1V147.bin` 里切出 MBOOT 段（2.96 MB）看字符串：

| 能力 | 证据 | 用处 |
|---|---|---|
| U-Boot **2011.06**（MStar 分支） | 源码路径 `bootloader/mboot-mtk/mboot/u-boot-2011.06/...` | 老，但没有 bootcount |
| 网络栈 | `bootp`/`dhcp`/`ping`/`bootm`、`boot image via network using TFTP protocol` | 可以网络引导 |
| **fastboot** | `fastboot: processing commands ...`、`fastboot_port`、**`fb_udp_our_port=%d`** | 可能是**网络(UDP)版** fastboot |
| BCB / misc | `boot-recovery`、`begin/end write fastbootd command to misc` | 可能支持从 Android 触发进入 |
| 环境变量 | MBOOT 分区 `0x2B8794` 之后，带 `mboot_default_env=1` | **是内置默认环境**，说明实际启动命令多半写死在 mboot 里 |

这条很重要：`bootcmd=` 出现的位置里只有 U-Boot 的默认值（`fatload ... uImage`），而升级脚本是
`setenv bootcmd 'mmc read.p 0x23000000 dtb ...; bootm'` 之后 `saveenv`。现场看到的却是默认值，
说明**真正生效的启动序列不是 env 驱动的**。所以"改 env 走 TFTP"这条路不能想当然。

## 二、五条路，按风险排

| 方式 | 插 U 盘 | 按键 | 失败后怎么回来 | 评价 |
|---|---|---|---|---|
| 现状：U 盘升级 | 要 | 要 | 再插一次 | 人必须在场 |
| **修好 insmod** | 不要 | 不要 | 不碰启动，最坏重启 | **最优先，30 分钟可判定** |
| **dd 写 recovery 分区 + `adb reboot recovery`** | 不要 | 不要 | 断电重启即回正常系统 | 推荐，前提是先验证触发 |
| dd 直接写 boot 分区 | 不要 | 不要 | 断电后仍挂 → 只能 U 盘救 | 快，但赌 |
| 改 U-Boot env 走 TFTP | 不要 | 不要 | env 坏了只能 U 盘 | 最优雅，但要先逆行 mboot |

## 三、为什么 recovery 这条路相对安全

正常启动读的是 `boot` 分区，`recovery` 分区是独立的：

- 把测试内核写进 `recovery`，`boot` 一字不动；
- 测试失败 → 断电重启 → mboot 走正常 `bootcmd` → 回到 Android；
- 不需要 U 盘、不需要按键，**唯一的物理动作是断电**。

若家里有智能插座（或能让家人按一下插排），这一条就是全自动的。

**待验证的前提**：`adb reboot recovery` 是否能真的让 mboot 去读 `recovery` 分区。
升级脚本里确实设了 `recoverycmd=mmc read dtb; mmc read recovery; bootm`，但触发方式未见证据。

## 四、为什么先试 insmod

它不碰任何分区，成功就是零成本的全在线迭代。上次失败的点已经收窄：

- 编译/ABI 都没问题（vermagic 与符号 CRC 全部对齐）；
- 卡在 `insmod` 后内核态自旋（R 状态 100% CPU、零日志）。

下一步用二分法定位，代价都很小：

1. **空模块**（`module_init` 直接返回 0，不打印任何东西）——若它能加载，
   说明是 `pr_info` → 串口控制台写导致的死等（`console=ttyS0` 没有对端）；
2. 再看 `printk` 的 console 门限：`/proc/sys/kernel/printk` 是不是被设成了很低的等级；
3. 若空模块也自旋，则说明 MStar 在 `sys_init_module` 上打了钩子，这条路放弃。

## 五、建议的顺序

1. 空模块测试（30 分钟，风险：最坏再一次自旋 → 重启）
2. 通了 → 以后所有驱动都能 `insmod/rmmod` 在线试，零刷机
3. 不通 → 验证 `adb reboot recovery` 触发，改走 recovery 分区迭代
4. 都不行 → 智能插座 + dd 写 boot（保留 MBOOT/boot 备份，随时 U 盘救）
