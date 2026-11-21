# 待机是硬件状态机：PM51 拥有电源键

> ⚠️ **排查任何"重启循环"之前先读这段（2026-11-19，用户第三次纠正）**
>
> 这台电视**重启/上电后一律停在待机**，必须按机身电源键或红外开机键才真正启动。
> 所以用户口述的"重启"、"几秒后又自动重启"，真实序列是：
>
> ```
> 出 logo → 自己重启（= 进待机） → 按红外开机键 → 出 logo → 约 3 秒 → 又回待机
> ```
>
> - 「3 秒后重启」= **3 秒后回待机**，不是复位循环，也没有 5 秒/205 秒的固定节拍可套；
> - 每按一次开机键 = **一次**启动机会 = 一次观测；
> - 凡是拿"周期恒定/抖动"去区分看门狗与 panic 的推理，都先要排除中间那次待机 + 人工按键。
>
> 我曾三次把"回待机"当"重启"来算时间，导致看门狗、自动重刷、panic 三条线全部推错。

> 用户的两条观察（重启/上电后默认待机、必须红外开机；无论系统多卡，关机都是秒关）
> 在源码和 sysfs 里都能对上。**它们改变了我此前的一个错误结论。**

## 一、硬件：待机 MCU 是 PM51

厂商 cmdline 直接写着：

```
PM51_ADDR=0x43FF0000 PM51_LEN=0x10000
RTPM_INFO=1,0x43FF0000          # 运行期 PM 共享区，和 PM51 同一地址
pm_path=/vendor/tvconfig/config/PM.bin
```

- `PM51` 是 MStar 的待机 MCU（8051 核），跑在自己的 SRAM 里，由常电供电；
- `/vendor/tvconfig/config/PM.bin` = **65536 字节**，就是它的固件；
- 0x43FF0000 落在 RAM 的两个窗口之间的空洞里（第一段到 0x41800000、第二段从 0x54400000 开始），
  所以它是"藏在内存空洞里"的一块共享区。

## 二、关机是"把电源交给 MCU"，不是软件流程

`drivers/mstar2/hal/m7322/cpu/arm64/pm.c:475`：

```c
static void mstar_pm_power_off_prepare(void)
{
#ifdef CONFIG_MSTAR_SYSFS_BACKLIGHT
	MDrv_PM_TurnoffBacklight();          /* 先灭背光 */
#endif
	MDrv_PM_SetPMCfg(PM_STANDBY_MODE);   /* 告诉 MCU：进待机 */
	MDrv_PM_CopyBin2Sram();              /* 把 PM.bin 拷进 MCU 的 SRAM */
	mstar_sleep_cur_cpu_flush();
}

static void mstar_pm_power_off(void)
{
	MDrv_PM_SetSRAMOffsetForMCU_DC();    /* 把 SRAM 偏移交给 MCU，然后切断 DC */
}
...
	pm_power_off_prepare = mstar_pm_power_off_prepare;
	pm_power_off         = mstar_pm_power_off;
```

关键点：内核最后做的事只是**拷固件 + 交权**。真正把电源切掉的是 PM51。所以
"无论系统多卡都是秒关"是设计使然——负载、锁、I/O 全都不在这条路径上。

## 三、红外电源键是 PM51 解码的（这推翻了我之前的结论）

此前我写过"IR 解码在内核里（`input0 = Tcl Smart TV IR Receiver`），所以内核一挂遥控器就无效"。
**对普通按键成立，但电源键不成立。** 证据链：

```
/proc/kallsyms:  parse_PM51_all_keymaps          <- 解析 PM51 的键表
                 tz_pm51ctl / tz_pm51ctl.part.3
drivers/mstar2/drv/ir_mirc/ir_dynamic_config/ir_dynamic_config_main.c:405
     parse_PM51WK_all_keymaps()   ->  DBG_INFO("PowerKey code:0x%x\n", ...)
                                     ir_PM51WK_profiles[]        (WK = wakeup)
drivers/mstar2/drv/pm/mdrv_pm.c:450
     MDrv_PM_Write_Key(PM_KEY_DEFAULT, &PM_WakeCfg_t, sizeof(...))
drivers/mstar2/drv/pm/mdrv_pm.c:497
     u8 MDrv_PM_GetPowerOnKey(void)   <- 反过来问 MCU "这次是哪个键开机的"
```

⟹ **内核把"哪些红外码算开机键"写进 PM51**（`PM_WakeCfg_t`），之后 SoC 断电，
PM51 用这份键表自己解码。这就是"断电后仍能遥控开机"的机制。

## 四、用户空间能直接看到的接口

```
/sys/class/pm/pm/
  PM_Info        644   状态（本机读出来是空的）
  WakeCfg        666   唤醒键配置（96 字节二进制，实测内容见下）
  WoBTCfg        666   蓝牙唤醒（本机 = 0x0d）
  WoEWBSCfg      644
  SARCfg         666
  PowerDownCfg   644   本机 = 0x03 00
  LEDCfg         644   本机 = 00 00 00 01 ...
  IrKeyCfg       644   本机为空
/proc/mstar_lp_standby   666   只读时返回 "Mstar standby mode procfs!"（写它应可主动进待机）
/proc/apm                444   1.13 1.2 0x02 0xff ...
```

`WakeCfg` 实测（96 字节）：

```
ff f5 46 d5 00 00 00 07 00 0f 00 d5 00 00 00 00
...（32 字节 0）...
48: 00 00 2c e0 32 54 eb a8 02 00 00 00 ...   80: 00 00 00 00  ff
```

没找到 `PM_WakeCfg_t` 的定义（头文件不在 GPL 包里），字段含义暂不猜。

## 五、对移植计划的三个影响

1. **"断电"不再是唯一的物理动作。** 红外电源键永远有效（PM51 常电），所以
   `断电/重启 → 红外开机` 可以完全自动化（用户的音箱已经在做）。之前"要不要买智能插座"的问题消失了。

2. **"卡死之后怎么办"没有变。** 红外只能把电断掉再送上，**它不改变下次启动加载什么**。
   `boot-recovery` 仍在 misc 里 ⟹ 上电还是同一个卡死的内核。
   所以救援盘（`recovery-stick.md`）依然是唯一出口。

3. **观察通道要重新评估。** 待机时背光是关的（`mstar_pm_power_off_prepare` 第一句就是灭背光），
   而 mboot 在启动早期会画开机 logo（`delaylogo=true`、`recovery_fbaddr=0x2D100000`）。
   所以一次启动测试的现象是：**屏幕上从"logo"变成"文字"就说明内核走到了 console 初始化**；
   一直停在 logo = 内核没走到那一步。这条判断不需要串口，但需要有人看一眼屏幕或拍照。

## 六、实测记录（2026-11-17 18:51）

```
18:51:42  发 adb reboot（当时 uptime 27 min，load 53，屏幕处于待机）
+2m30s    网络不通、adb 不通 —— 停在待机，等红外开机
```

与"开机状态下重启会自己回来"的旧观察不同，说明**重启是否自行启动取决于重启前的电源状态**。
⟹ 以后凡是让电视重启，都要预留"需要有人发一次红外开机"。

## 七、待办

- [ ] 写 `/proc/mstar_lp_standby`（`1`/`0`）验证能否主动进/出待机（需 root，且会自动断 adb）
- [ ] 读 `/sys/class/pm/pm/WakeCfg` 与 `/vendor/tvconfig/config/PM.bin`，确认唤醒键表的具体编码
- [ ] 确认"上电即待机"是 `boot_ctrl`/`power_mode.bin` 决定的，还是 PM51 的固定策略
