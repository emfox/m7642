# 红外、电源与"远程救砖"的真实边界

2026-11-17 实测。回答一个具体问题：**能不能靠红外遥控器触发重启，从而不必有人在电视前？**

结论先说：**不能，而且不需要。** 但同一次调查里找到了一条真正可用的路径。

## 一、触发重启从来不需要人

`adb reboot` 一条命令即可，44 秒后设备自己回来（boot 分区没动时）。之前写「R2 需要人在场」，
指的**不是触发动作**，而是**失败之后**——那是两个完全不同的问题，此前混在一起说了。

| 阶段 | 需要人吗 | 手段 |
|---|---|---|
| 让设备重启 | 不需要 | `adb reboot` / `adb reboot recovery` |
| 让设备进入 recovery | 不需要 | `adb reboot recovery`（mboot 认 misc 分区的 `boot-recovery`）|
| 内核没起来之后 | **需要** | 见第四节 |

## 二、红外救不了砖：解码器在内核里

实测证据：

```
/proc/interrupts:
130:   104   0   0   0   GICv2  130 Level   IR

/sys/class/input:
input0 = Tcl Smart TV IR Receiver
```

- IR 接收器挂 **GIC 中断 130**，是主 SoC 的外设，不是独立待机 MCU；
- 解码后注册成 `input0`，走标准 input 子系统（**没有用 rc-core**，`/sys/class/rc/` 是空的，
  厂商自写驱动直连 input）；
- GPL drop 里 `drivers/mstar2/drv/ir/` 只有 Kconfig，**0 行 C**——与 `hdmitx4vx1` 同样的情况。

⟹ **普通按键**只有在「内核活着 + 驱动 probe 过 + input 子系统在工作」时才有意义。

### 更正（2026-11-17 18:50，用户提示后复核）

上面这段结论**对电源键是错的**。这台机器还有一颗常电的待机 MCU（**PM51**），
内核会把「哪些红外码算开机键」写给它（`MDrv_PM_Write_Key(PM_KEY_DEFAULT, PM_WakeCfg_t)`、
`parse_PM51WK_all_keymaps` 里 `PowerKey code:0x%x`），SoC 断电后由 **PM51 自己解码**。
所以电源键在待机（SoC 完全断电）时永远有效，遥控开关机是硬件行为，与内核状态无关。

实测也支持：`adb reboot` 之后设备停在待机、网络与 adb 都不通，必须红外开机。
详见 `pm51-standby.md`。

**但这仍然救不了砖**：红外只能"把电断掉再送上"，**不改变下次启动加载什么**。
`boot-recovery` 还在 misc 里 ⟹ 上电还是同一个起不来的内核。
判断"有没有救"的分界线在**启动内容**，不在**电源**。

## 三、"算不算物理在场"

| 做法 | 算不算 | 有没有用 |
|---|---|---|
| 人在电视前按遥控器 | 算（但你已经在了） | 有用 |
| 远程发红外（发射器/网关） | 不算 | **崩溃时无效** |
| **智能插座（远程断市电）** | **算** | **唯一能救内核死掉的手段** |

按 `adb reboot` 与按遥控器电源键在软件层等价（都最终走 PowerManager）；
真正的物理独占能力是**切断市电**，只有智能插座能远程做到。

补充：`/sys/power/state` = `freeze mem`，支持 suspend-to-RAM。遥控器电源键大概率是进
suspend（Android TV 待机）而非真断电，所以它连"冷启动"都给不了。

## 四、mboot 的启动模式：一条真正可用的路

从 `fw/mboot/mboot.bin`（U-Boot 2011.06-00000-gc44ec26-dirty, Sep 17 2022）的字符串里挖出：

```
get_boot_mode_from_env
get_boot_mode_from_mtd0        <- 从 flash 固定位置读，不只靠按键
get_boot_mode_from_keypad
boot_mode_recovery
update_mode  /  get/set update_mode

EN_UPDATE_MODE_NONE
EN_UPDATE_MODE_TFTP
EN_UPDATE_MODE_USB
EN_UPDATE_MODE_OAD
EN_UPDATE_MODE_NET
EN_UPDATE_MODE_USB_WITH_SEG_DECRYPTED
EN_UPDATE_MODE_NET_WITH_SEG_DECRYPTED

do_rw_en_update_mode
do_createMbootBak              <- mboot 自己会建备份
do_auto_tftp / auto_tftp [image_name]
bootcmd=if mmc rescan ${mmcdev}; then if run loadbootscript; ...
```

含义：

1. **启动模式有三个来源**：U-Boot env、flash 固定位置（mtd0）、按键。**按键只是其中一条**。
2. **有网络升级模式**（`TFTP` / `NET`），mboot 阶段网络就已经可用。
3. **`do_createMbootBak`**：mboot 自己维护备份。
4. **没有 bootcount / altbootcmd**：U-Boot 2011.06 那一代还没有，⟹ **没有"启动失败自动回退"**。

⟹ 如果能确定 `get_boot_mode_from_mtd0` 读的确切偏移与编码，就能从 Android 侧写一小段数据，
让下次启动直接进 TFTP 升级模式 —— **不需要人、不需要红外、不需要插座**，这才是长期安全网。

## 五、一条被否定的猜想（避免了一次危险操作）

调查中出现过一个很像答案的东西：`/impdata/power_mode.bin`，16 字节：

```
0000000  53 54 42 43 02 00 00 00 00 00 00 00 00 00 00 00
          "STBC"     mode=2
```

一度怀疑它就是启动模式标志。**否掉了**：`STBC` 与 `power_mode` 两个字符串
**都不在 mboot.bin 里**（mboot 里只有 `impdata` 和 `/impdata/project_id.bin`）。
⟹ 这个文件是 Android 侧（MStar PM 驱动）记录的电源状态，与启动模式无关。
**按这个猜想写值不会得到任何效果，只可能破坏电源状态记录。**

这条记下来当方法论：**名字像不等于作用像**，要用「二进制里有没有这个字符串」来证伪。

## 六、`/impdata` 里的其它有用东西

顺带盘到（p18，只读 ext4，mboot 也会读它）：

| 文件 | 用途 |
|---|---|
| `panel_data.ini` | **出厂白平衡/gamma 曲线**，三组 R/G/B 查找表（COLD/STANDARD/STANDARD2/WARM/WARM2），
25 KB。显示移植后做色彩校准的基准数据 |
| `hdcp_key.bin` / `hdcp_key2.0.bin` | HDCP 密钥，HDMI 链路要用 |
| `mac.bin` / `sn.bin` / `device_id.bin` | 网络与设备身份，首次启动要保留 |
| `project_id.bin` / `model_name.bin` | 机型判定 |
| `power_mode.bin` | 上次电源状态（见第五节）|

**`/persist`（p19，可读写）里有 `PersistData.db` 和 `tcl_logo_path`** —— 开机 logo，换内核后要保留。

## 七、结论

1. 红外控制重启：**不算物理在场，也不解决问题**。推翻这个思路。
2. 触发重启本身：`adb reboot` 就够，本就不需要人。
3. 唯一能救"内核死掉"的现成手段：**智能插座**（几十块钱，最省事）。
4. 更值得做的是：反汇编 mboot 的 `do_rw_en_update_mode` / `get_boot_mode_from_mtd0`，
   把 boot_mode 的存储偏移与编码钉死，做成"远程切升级模式"。
5. 在此之前，R2（写 recovery + dtb）仍然建议**安排一次人在场**。

## 八、待办

- [ ] 反汇编 mboot.bin 定位 `get_boot_mode_from_mtd0`，读它引用的地址
- [ ] 确认 U-Boot env 在 MBOOT 分区内的偏移（`mboot_default_env=1` 影响是否可改）
- [ ] 验证 mboot 的 TFTP 模式是否需要额外文件（`/apollo/boot_mode.ini`、`boot_cfg.ini`）
- [ ] 把 `panel_data.ini` 归档进本仓 `artifacts/`
