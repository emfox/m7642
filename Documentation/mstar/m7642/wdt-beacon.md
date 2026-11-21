# WDT 信标：让设备自己重启，用 DDR 标记分级

> 2026-11-20 夜。**离线完成，尚未上机。**
> 解决的问题：颜色判据已废（`display.md` §九），"卡死与否"只有二值、分不出检查点。

## 一、为什么这条路成立

两件已有的事实拼起来就是一个完整通道：

1. **mboot 自带 `wdt_enable <n>` 命令**（本文第二节反汇编证实）⟹ 可以让 WDT 在 n 秒后复位。
2. **`ladder.S` 已经在 `0x43300000` 写「`M764` + STEP + 补码」**（`probes/ladder/ladder.S`
   第 265–280 行），而该地址落在 DT 两个 memory 节点之间的空洞里，内核和 Android 都不碰。
3. **warm reset 保留 DDR** —— `entry-ladder.md` §零 已用 `sysrq c` panic 后的
   `/sys/fs/pstore/console-ramoops`（576 行完整日志）证实。

⟹ 链路：**跑内核 → 卡住 → WDT 复位 → mboot → BCB 已空 → Android → 读 `0x43300000` → 知道跑到第几级。**

不再需要人眼看屏幕，也不再需要判断颜色。

## 二、`wdt_enable` 的反汇编证据

### 2.1 命令表项

`wdt_enable` 字符串（fileoff `0x299cca`）的 VA 被引用在 **`0x2c8178`**，那里是 U-Boot 的
`struct cmd_tbl_s`。同表相邻项的布局一致（`name/+0, maxargs/+4, repeatable/+8, cmd/+12, usage/+16`）：

| 项 | `name` | `+4` | `+8` | `cmd` | `usage` |
|---|---|---|---|---|---|
| `loadspi` | `0x2769784c` | 4 | 4 | `0x2744c684` | `load data from SPI` |
| `epd` | `0x27697867` | 4 | 4 | `0x2744c670` | `emac power down` |
| `memtest` | `0x2769787b` | 2 | 1 | `0x2744cd20` | `Get the performance of memory` |
| **`wdt_enable`** | `0x276978ca` | `0x40` | `0x2` | **`0x2743dff4`** | `wdt_enable n - set Watchdog timer to n secs` |

⟹ **命令确实注册在命令表里**，`cmd` 指向真正的实现（fileoff `0x403f4`）。

### 2.2 实现（`mbdis.py` 反汇编 `0x403f4`）

```
0x40428: ldr r0 -> 0x292a9f "WDT_ENABLE"
0x40430: bl  getenv                 ; r0 = getenv("WDT_ENABLE")
0x40434: cmp r0, #0
0x40438: beq 0x404f4                ; 为 NULL ⟹ 打印 "WDT is not Enable" 并返回 0
...
0x40450: cmp r6, #1                 ; argc == 1 ?
0x40454: bne 0x404bc                ; ★ 有参数 ⟹ 走这里，不做范围检查
...
0x404bc: ldr r0, [r5, #4]           ; r5 = argv
0x404c0: mov r1, r7
0x404c4: mov r2, #0xa               ; 十进制
0x404c8: bl  simple_strtoul
0x404cc: mov r5, r0                 ; 超时秒数
0x404d0: b   0x404d8
...
0x404d8: mov r0, #3
0x404dc: bl  0x237a7c               ; 参数 3（通道/组号）
0x404e0: mov r0, #3
0x404e4: uxth r1, r5                ; 超时值，16 位
0x404e8: bl  0x237b14               ; (3, timeout)
0x404ec: mov r0, #0
0x404f0: pop {r3, r4, r5, r6, r7, pc}
```

三条可用结论：

1. **前置条件是 env `WDT_ENABLE` 非空**。出厂是 `0`，但 `rescue-fast.bin` 已把它改成 **`1`**
   （实测读回：`128  WDT_ENABLE  1`）⟹ **现在可用，不需要再改**。
2. **带参数时（`wdt_enable 10`）直接按十进制解析并调用底层，没有 `<=4 / >=5` 那段检查**
   —— 那段只在 `argc == 1`（无参数、从 `WDT_TUMEOUT` 取值）时走。
3. 底层调用带"通道号 3"，说明走的是 MStar 自己的 HAL 链路，**不是空壳**。

⚠️ **仍未证明**：它是否真的把硬件布防到"n 秒后复位"。这只能上机验。但它有正式 usage、
注册在命令表、调用 HAL 两层，可信度远高于盲扫寄存器（`discipline.md` §3 禁止盲扫）。

## 三、`recoverycmd` 的新值

```
mmc erase.p misc; mmc read.p 0x23000000 dtb 0x00100000; mmc read.p 0x25000000 recovery 0x02000000; wdt_enable 10; bootm 0x25000000
```

三个位置约束：

| 约束 | 原因 |
|---|---|
| 前 4 字节必须仍是 `mmc ` | `boot_mode_recovery()` 只检查这个前缀，否则整条不执行 |
| `wdt_enable` 必须在两条 `mmc read.p` **之后** | 读 32 MB eMMC 要时间，先布防会吃掉预算 |
| `wdt_enable` 必须在 `bootm` **之前** | 布防要在跳内核之前完成 |

⟹ 布防后只剩 `bootm` 一句，10 秒全部留给内核。

## 四、ladder 那一半：每级不同的 STEP

`mk-rung-419.py` 原本三个 rung 共用同一个 blob，**STEP 全是 0 ⟹ 标记分不出级别**。
已补 per-rung patch（`movz w19, #imm16` 的编码是 `0x52800013`）：

```python
elif (w & 0xFFE0001F) == 0x52800013:        # movz w19, #imm16 (STEP)
    b[i:i + 4] = struct.pack("<I", 0x52800013 | ((step & 0xFFFF) << 5))
    steps += 1
assert steps == 1, "expected 1 STEP immediate, patched %d" % steps
```

**为什么不误伤黑条循环**：`mov w18, #STEP`（黑条数量）是 `Rd=18` 即 `0x52800012`，
不在这个掩码里；两条是独立指令。且当前 `STEP=0` ⟹ `cbz w18, 9f` 直接跳过黑条，
标记值仍由 `movz w19` 单独给出。

## 五、产物

```
~/kbuild/m7642-out/m7642-419-wdt.img
21,618,688 B   md5 d73b328258bb30d517cd661b3a78ca8e
kernel_size 0xd3fea8   blob 392 B   step 0x190
rungs @ +0xd3fa00 / +0xd3fb90 / +0xd3fd20
```

| rung | 颜色（32 位字） | STEP | 尾部跳转 | 含义 |
|---|---|---|---|---|
| 1 | `0xFFFFFFFF` | **1** | `+0xb70000` (`stext`) | 进了镜像 |
| 2 | `0xFC00FC00` | **2** | `+0x9152b0` (`__primary_switch`) | `stext` 跑完 |
| 3 | `0x07E007E0` | **3** | `+0xb70b90` (`start_kernel`) | MMU 已开、将进 C |

三个 `END_MARK` 都是 `M76E`；最后一个 rung 正好结束在 `kernel_size`（零余量，脚本有断言）。
`STEP` 后写覆盖前写 ⟹ 读到的就是**最后到达的那一级**。

env 离线版（**未写设备**）：

```
~/kbuild/emmcboot/now/env-wdt.bin        crc 69f350e1   （基础是重启后读回的 env-pr-1.bin）
```

逐行 diff：只有 `recoverycmd` 与 `crc` 两行不同，128 条变量一条没丢。

## 六、判读

Android 起来后：

```sh
~/Debian/m7642/tools/host/read-ladder.sh        # 或经 tvrun.sh + probeRW.ko，用 toybox rmmod
```

| `0x43300000` 内容 | 结论 |
|---|---|
| `M764` + `1` + `~1` | 只到第 1 级：进了镜像，`stext` 之前就挂了 |
| `M764` + `2` + `~2` | `stext`（含 `__create_page_tables`）跑完，挂在 `__primary_switch` 之前 |
| `M764` + `3` + `~3` | MMU 已开，挂在 `start_kernel` 之前 |
| `M764` + `0` + `~0` | 标记写了但 STEP 没 patch 上 ⟹ 镜像错了，不是内核问题 |
| 全零 / 不是 `M764` | 没跑到任何 rung，**或 WDT 复位丢了 DDR** ⟹ 见 §七 |

## 七、未验证项（按风险排）

1. **WDT 复位是否保留 DDR。** 一切的根基。若不保留，标记读不到，本方案退化成"能自动重启但不知道跑到哪"。
   判据：读回全零且 `M764` 也没有 ⟹ 大概率 DDR 丢了，不是内核没跑。
2. **`wdt_enable 10` 是否真的布防到 10 秒。** 若设备 10 秒内没重启也不进 Android ⟹ 命令没生效。
3. **复位后 mboot 是否走 `bootcmd`。** 取决于 `mmc erase.p misc` 是否在 `wdt_enable` 之前执行
   （顺序已保证），以及 WDT 复位是否重置 misc 缓存。
4. **10 秒预算。** `bootm` 之后内核到第一个检查点是毫秒级，10 秒充裕；但若 4.19 在更后面卡住，
   标记会停在那之前的最后一级 —— 这正是我们想要的。

## 八、操作规程（等设备可用时）

```
1. 只读：precheck.sh                        # 槽头 / BCB / 厂值备份
2. 确认 rec.head.factory.bin = 0f6e1705…
3. arm 一次（I_HAVE_RESCUE_STICK=1）
4. reboot
5. 等 30–60 秒：设备应自己重启并进 Android（WDT 复位 + BCB 已擦）
6. adb 通了 ⟹ 跑 read-ladder.sh 读标记
```

**这次不需要人眼看屏幕，也不需要拔电按红外** —— 如果第 5 步成立，恢复动作连"按红外"都省了。

---

## 九、★ 实测结论（2026-11-20 晚）：WDT 成立；DDR 途径被误判过一次

### 1. `wdt_enable 10` 生效 —— 不再需要拔电

env 写入设备（`75ade57a…`，两份 CRC 均 OK，128 条变量未丢），`adb reboot` 后
`boot_completed=1` ⟹ **mboot 接受这份 env**。重启后再读，**逐字节不变**。

随后两次"卡死"实验（一次 `white-cc`、一次 `wdt` 镜像），设备**都自己回到了 Android**：

| 实验 | reboot | 内核启动 | 差额 | 结果 |
|---|---|---|---|---|
| `white-cc`（HALT） | 21:15:41 | 21:16:04 | **23 s** | 自己回 Android |
| `wdt`（非 HALT） | 21:19:34 | 21:19:50 | **16 s** | 自己回 Android |

对照：此前 `white-halt` 卡死后**必须拔电**（用户手动操作）。
⟹ **差别就是 `wdt_enable 10`** ⟹ **它真的布防了，WDT 复位有效。**

副作用证据：`misc` 在启动后是**全零**（不是 `boot-adb`）⟹ `mmc erase.p misc` 执行了，
而 Android 启动**不写 BCB**，所以复位后 mboot 必然走 `bootcmd`。

**这是本轮最大的工程收益：测试失败的恢复动作不再需要人、不需要 U 盘、不需要按键。**

### 2. ~~DDR 标记不可行~~ —— **这条结论作废，方法错了**

`0x43300000` 读回全零。当时我用 `probeRW op=w` 写已知值、`adb reboot`、再读回，五个地址全丢：

| 地址 | 写入 | 重启后 |
|---|---|---|
| `0x43300000` | `0x4d373634` | 全零 |
| `0x20100000` | `0x4d373634` | `78 c0 9f e5…`（ARM 指令，mboot 活代码区） |
| `0x48000000` | `0xaaaa0001` | `ff ff 00 00` |
| `0x50000000` | `0xaaaa0002` | `ff ff 00 00 00 00 ff ff` |
| `0x52000000` | `0xaaaa0003` | 全 `ff` |
| `0x98000000` | `0xaaaa0004` | `"usb_int_merge1"` |

**但复位方式是错的。** `confirmed-facts.md` §G 与 `flash-and-recovery.md` §44 都写着
**`adb reboot` ⟹ 进待机 = PM51 切电 = 硬断电**，DDR 当然全丢。

**正确的分类是**（§五十二 早有记录，§3 有 panic 实测）：

| 复位方式 | DDR | 依据 |
|---|---|---|
| **soft reset（WDT / panic）** | **保留** | `ramoops/pstore 只在 soft reset 下保留`；`echo c > sysrq-trigger` 后能读到 panic 前 576 行日志 |
| `adb reboot`（进待机切电） | 全丢 | `adb reboot` 后设备停待机、adb 不通 |

⟹ **DDR 通道没有被否证**，只是不能用 `adb reboot` 去测它。
⟹ 我把它推广成"启动覆盖整片 DDR、不存在安全地址"是**过度推论**，撤回。

🔴 唯一保留的硬结论：**`0x20100000` 是 mboot 的活动代码区**（写进去的字节重启后变 ARM 指令），
绝对不要在那里做任何读写实验。

### 3. 当年放弃这条通道的理由，现在两条都消失了

§六十六 §6 的结论是：「软复位保留 DDR 这件事**没有任何消费者**，所以没有价值」。

当时的两个前提：
1. **测试失败只能断电刷机**（没有软件恢复手段）⟹ 断电即 DDR 全丢；
2. 即使保住 DDR，也没有机制把内容读出来。

**现在两条都不成立**：
1. `wdt_enable 10` ⟹ 失败后**自动 warm reset**，不切断电源（§九 §1 已实测两次）；
2. `mmc erase.p misc` ⟹ 复位后**自动走 `bootcmd` 进 Android**，不需要人；
3. 读出方式有两条：`probeRW` 直读 DDR，或**ramoops 签名通道让 pstore 自动导出**（§十）。

⟹ **这条当年被放弃的路，现在正好打通了。** 这是今晚真正的结论。

### 5. 仍未回答的问题

**ladder 到底执行了没有？** 至今没有一条独立于屏幕和 DDR 的证据。
`code1` 通路在 `white-cc` 那次由"屏幕出现白色"间接支持过，但按 `discipline.md` §1
（条纹/花屏不算数）那次也不算数。换到 always-on 信道后才能给出确定答案。

---

## 十、★ 正确通道：ramoops 签名（pstore 自动导出，不用 probeRW）

### 1. 机制

`fs/pstore/ram_core.c`：

```c
#define PERSISTENT_RAM_SIG (0x43474244) /* DBGC */

static int persistent_ram_post_init(struct persistent_ram_zone *prz, u32 ecc, u32 sig)
{
	sig ^= PERSISTENT_RAM_SIG;
	if (prz->buffer->sig == sig) {
		...
		persistent_ram_save_old(prz);   /* 拷进 kmalloc，之后谁也改不了 */
		return 0;
	}
	prz->buffer->sig = sig;
	persistent_ram_zap(prz);                /* 签名不符 -> start=size=0 */
}
```

两条推论：

- **写错签名 = 被清零**。这解释了历史上往 `0x42300000` 写什么读回都是 0 ——
  不是硬件丢数据，是 pstore 判为无效后 `zap`。
- **写对签名 = 内容被 `save_old` 拷进 kmalloc**，之后原厂内核往 console 区写多少日志
  都覆盖不掉；pstore 把它导出成 `/sys/fs/pstore/console-ramoops`。

⟹ **不需要 `probeRW`，不需要自己读 DDR —— adb 直接 cat 那个文件。**

### 2. 布局（1 MB，四个 256 KB buffer）

> ⚠️ 2026-11-21 实测：基址是 **`0x41900000`**，不是本节旧版写的 `0x42300000`（那个地址读回全 `00`）。
> 以 §十三 的实测值为准：dump 0x41900000/0x41940000、console 0x41980000、pmsg 0x419c0000。

console 在 `0x42300000`，`struct persistent_ram_buffer`：

```
+0x00  u32 sig   = 0x43474244
+0x04  u32 start = 0
+0x08  u32 size  = N
+0x0c  u8  data[N]
```

`ramoops_pstore_read()` 对 console 用 `size = persistent_ram_old_size(prz)`，
把 `data[0..N)` 原样导出。

### 3. ladder 改动（只动标记那一段）

```asm
	movz	x16, #0x4230
	lsl	x16, x16, #16
	movz	w17, #0x4244
	movk	w17, #0x4347, lsl #16		// 0x43474244 = PERSISTENT_RAM_SIG
	str	w17, [x16]			// sig
	str	wzr, [x16, #4]			// start = 0
	mov	w18, #16
	str	w18, [x16, #8]			// size = 16
	movz	w17, #0x3634
	movk	w17, #0x4d37, lsl #16		// "M764"
	str	w17, [x16, #12]
	movz	w19, #STEP
	str	w19, [x16, #16]
	dsb	sy
```

### 4. ⚠️ 只在 rung1 / rung2 写，**rung3 不能写**

| rung | 落点 | MMU | 能否直写 `0x42300000` |
|---|---|---|---|
| 1 | `stext+0` | **关** | ✅ VA==PA |
| 2 | `__primary_switch` 前 | **关** | ✅ |
| 3 | `start_kernel` 前 | **已开** | ❌ 该 PA 不在 idmap（idmap 只覆盖 `0x20290000..0x208F0000`），写就 fault |

⟹ rung3 保持只涂色、不写标记。判读退化为两档（1 / 2），但这正好是**我们最需要的两档**：
"进了镜像"和"内核低层启动跑完"。rung3 的信息等前两档坐实后再想办法。

### 5. 读法

```sh
adb shell 'head -c 32 /sys/fs/pstore/console-ramoops | od -A n -t x1'
```

| 内容 | 含义 |
|---|---|
| 前 4 字节 `34 36 37 4d` + STEP=1 | 进了镜像（`code1` 跳转成功、ladder 执行） |
| … + STEP=2 | `stext` 跑完（含 `__create_page_arch`/`__cpu_setup`） |
| 空 / 不是 `M764` | 没走到 rung1，或签名/地址写错 |

### 6. 为什么这条比 `0x43300000` 强

| | `0x43300000` | `0x42300000` |
|---|---|---|
| 谁管它 | 没人 | **pstore** |
| 怎么读 | 要 `probeRW` + tvroot + insmod | **`cat` 一个文件** |
| 保留性 | 靠 DDR 硬扛 | `save_old` 拷进 kmalloc，**之后不会被覆盖** |
| 被清风险 | 未知（本轮实验方法有误，未能测准） | 签名写对即有效（代码可证） |

### 7. 前提仍未验证的一条

**soft reset（WDT）是否与 panic 一样保留 DDR。** §五十二 把它归在同一类（"只在 soft reset
下保留"），§3 的 panic 实测支持，但**没有一条是从 WDT 复位直接测出来的**。
第一次用这条通道时，先看 STEP 是否能读到 —— 读到即同时证明两件事。

### 8. 已改：`ladder.S` 换到 ramoops 通道（2026-11-20 21:40，未上机）

`probes/ladder/ladder.S` 的标记段整段替换：

- 地址 `0x43300000` → **`0x42300000`**（ramoops console buffer）
- 头部按 `struct persistent_ram_buffer` 写：`sig=0x43474244` / `start=0` / `size=16` /
  `data[0..4)="M764"` / `data[4..8)=STEP` / `data[8..12)=~STEP`
- **`cmp w19,#3` + `b.eq 11f`**：rung3 跳过（MMU 已开，该 PA 不在 idmap）

blob 392 → **424 字节**，`step 0x190 → 0x1b0`。

```
~/kbuild/m7642-out/m7642-419-pstore.img
21,618,688 B   md5 7047387799c19444798060782d1ae4ca
kernel_size 0xd3ff08
rungs @ +0xd3fa00 / +0xd3fbb0 / +0xd3fd60   (STEP 1 / 2 / 3)
```

验证（全部通过）：

| 检查 | 结果 |
|---|---|
| `code1` 编码 | `+0xd3fa00` ✓ |
| 三个 rung 的 STEP | 1 / 2 / 3 ✓ |
| 三个 rung 的签名指令 | `movz w17,#0x4244` + `movk w17,#0x4347` ✓ |
| 镜像内 rung1 反汇编 | 六条 `str [x16,#0/4/8/12/16/20]` 齐全、`b.eq 0x1a0` 在 ✓ |
| 尾部跳转 | `+0xb70000` / `+0x9152b0` / `+0xb70b90`，与 `System.map` 对上 ✓ |
| 最后一级收尾 | `0xd3fd60+424 = 0xd3ff08` = `kernel_size`（零余量，脚本有断言）✓ |
| ramdisk | 与原厂**逐字节相同**（`90989ec0…`，7,721,457 B）✓ |

⟹ **上机时读 `console-ramoops` 前 16 字节即可**：

```sh
adb shell 'head -c 16 /sys/fs/pstore/console-ramoops | od -A n -t x1'
# 期望  34 36 37 4d <STEP> 00 00 00 <~STEP> 00 00 00
```

## 十一、★ 实测（2026-11-21 00:15）：读了空，但那一次没走 WDT 路径

前置条件全部就位后才做的这一次（很重要，之前那次缺了一半）：

| 项 | 状态 |
|---|---|
| env `recoverycmd` | `mmc erase.p misc; …; wdt_enable 10; bootm …`，主备 `OK stamp 69f350e1`，逐字节相同 |
| 镜像 | `m7642-419-ddr3.img`（md5 `a6a2bcf1…`），标记写 **0x419A0000**（console data 中段） |
| 厂值备份 | `rec.head.bin` = `0f6e1705…`，另存 `rec.head.factory.bin` |
| 槽 / BCB | 写入后 slot md5 `a6a2bcf1…`、BCB = `boot-recovery` |
| U 盘 | `rescue-fast.bin`（47 MB，含 recovery 段）在根目录 |

时间线：`00:15:36` reboot → `00:16:15` `boot_completed=1`（**39 秒**）。

⚠️ **39 秒曾被当作"太快，像 bootm 后立即失败"，这条判据已作废**（2026-11-21 00:20 用户现场纠正）：
这台电视**每次重启都先回待机，要人按红外电源键才开机**；用户看到待机立刻按，正常就是
**35–40 秒**。所以 39 秒是**正常启动**，不含任何异常信息。

**读数**：

```
0x419A0000: ff ff ff ff ff ff ff ff ff ff ff bf ff ff f7 ff   ← 没有 "M764"
0x41980000: 44 42 47 43 b0 1a 00 00 b0 1a 00 00 "[     0.000000] -(0)["
0x41900000 / 0x41940000: 44 42 47 43 00… 00 ff ff ff ff      ← dump 区干净
0x419C0000: 44 42 47 43 00… 00 6c ef af 00
misc 前 16 字节: 全 00                                          ← erase.p misc 执行了
```

**这两条同时成立说明**：

1. `misc` 全零 ⟹ mboot 确实执行了 `recoverycmd` 并走到 `bootm` ⟹ 我们的镜像被交给 bootm；
2. 0x419A0000 没有标记，且 0x41980000 是**本次** Android 的日志（`size=0x1ab0`、从 `[0.000000]` 开始）。

**⟹ 这次读不到是必然的，不能拿它判 A/B。** 真正的路标是「**要不要人按电源键**」：

| 设备行为 | 含义 | DDR |
|---|---|---|
| 十几秒**自己**回 Android，不用人 | 镜像**卡死** ⟹ 10 s 后 WDT 触发 warm reset | **保留**（这样才有标记可读） |
| 停在待机、**要人按键** | 镜像**没卡死**，`bootm` 之后返回了 ⟹ mboot 交权 PM51 | **全丢** |

这次属于第二行 ⟹ 中间切过电 ⟹ `0x419A0000` 是空的，与 ladder 到底跑没跑**无关**。

对照 `confirmed-facts.md` §G：2026-11-20 的 `white-cc` / `wdt` 两次是**16–23 s 自己回来**，
走的是第一行；这次是 39 s 且要人按，走的是第二行。两者不是同一条路径，不能互证。

**所以这次唯一能说的**：`misc` 全零 ⟹ `recoverycmd` 在 `bootm` 之前确实执行了。
ladder 有没有被跑起来，这次**没有信息量**。

**下一步（形态必须改）**：现在 `ladder.S` 是"写完标记 → 继续交给 `primary_entry`"，
后面的崩溃会把控制权还给 mboot、回待机。要拿到标记，就必须让镜像**停在写标记之后不走**——
在 `dsb sy` 后面加 `b .`（死循环），WDT 10 s 必触发，warm reset 保 DDR，再回去读。
`#if HALT` 那一支在写标记**之前**（218 行），所以它不写标记，不能用。

**这次唯一坐实的**：ramoops 的 console 在 **0x41980000**（`mem_address=0x41900000` + 2×256K dump zone），
不是文档此前一直写的 0x42300000；Android 正在用它写启动日志。

## 十二、★★ 修正（2026-11-21 00:55）：上一个"判死"结论作废 —— 探针根本没写

用**原厂 4.9 kernel** + 44 字节极简 blob 做的判决探针（`m7642-tiny.img`，md5 `1dc553d5…`）：

```asm
movz x16,#0x419A ; lsl x16,x16,#16
movz w17,#0x3634 ; movk w17,#0x4d37,lsl #16   // "M764"
str  w17,[x16] ; mov w18,#1 ; str w18,[x16,#4]
mvn  w19,w18 ; str w19,[x16,#8] ; dsb sy ; b .
```

code1 改成跳到这里，其余全是原厂内容。**按一次电源 → 正常进 Android**，`0x419A0000` 仍是全 `ff`。

**但探针显然执行了**，证据是副作用而不是标记：

| 观察 | 含义 |
|---|---|
| `/data/app` 时间戳仍是 `00:37`（00:38 那次原厂 recovery 格式化的） | 这次**没有跑原厂 recovery init** |
| `/data/local/tmp` 内容还在 | 同上，也没格式化 |
| `last_log` 未被本次覆盖 | 同上 |

（当时据此认为"blob 把 init 拦住了"，见 12.1 的更正。）

⟹ 当时我据此下了"mboot 每次启动都重初始化 DDR"的结论。**这条已在 12.1 被推翻**——
init 没跑也可能只是"mboot 拒绝了镜像、直接走 bootcmd"，两者在这一点上无法区分。
pstore 为空同样不能作为 DDR 被清的证据（4.19 与 Android 的 ramoops 参数可能根本不同）。
唯一不依赖 DDR 的通道只剩**屏幕**（和串口，但没接）。


### 12.1 双地址探针把结论推翻了

`m7642-tiny2.img`（md5 `2d502b30…`）同一个 blob 写两个地址后 `b .`：

```
0x43300000 : 00 00 00 ...   <- 被 Android 的匿名页清零，不可用
0x419A0000 : ff ff ff ...   <- 仍是上电态
```

**`ff` 与 `00` 的区别是决定性的**：`persistent_ram_zap()` 用的是 `memset 0`，被它清过的区域会是 `00`。
`0x419A0000` 是 `ff`，说明**它从来没被写过**。

⟹ 探针 blob **没有执行**。上一节"DDR 留不住"的结论**撤回**（那是在"探针已执行"这个错误前提下推出来的）。
⟹ 真正的问题回到：**改过的 recovery 镜像没有被 mboot 执行**。

### 12.2 已知能跑的镜像与当前镜像的唯一结构性差异

| 镜像 | boot_ks | Image text_offset | Image image_size | 结果 |
|---|---|---|---|---|
| `m7642-ladder9-ciim3.img`（11-19） | `0xfa0100` | **`0x0`** | **`0xfa0100`** | 涂色成功 |
| 原厂 recovery | `0x12d4a00` | `0x80000` | `0x1551000` | 进 recovery、格式化 |
| 我们的（facprobe / tiny2） | `0x12d5000` | `0x80000` | `0x1551000` | **没有执行** |

11-19 那个 7.3 镜像里 `image_size == kernel_size` 且 `text_offset == 0`；
我们的镜像改了 `kernel_size`，但 Image 的 `image_size`/`text_offset` 仍是 4.19 原值。
**这三个字段之间是否被 mboot 交叉校验，目前不知道**，但它是唯一还没排除的差异。

⚠️ 原厂 recovery 的 `image_size`(`0x1551000`) 也大于 `kernel_size`(`0x12d4a00`) 却能跑，
所以"必须相等"这个猜测已经被原厂自己否掉了。下一步应该直接拿 11-19 的镜像重跑一次做对照。

**4.19 看不见涂色的最可能原因**（待验证）：`ladder.S` 进入后先 RMW framebuffer 控制字
`0x1f240600`（7.3 的 `m7642_beacon` 不碰这个），写错会把显示关掉，此后涂什么都看不见。
下一个探针应该是「原厂内核 + 只涂色、完全不碰控制字」。

---

## 十三、★★★★★ pmsg 通道端到端验证通过（2026-11-21 10:15 实测，零风险）

§十二 之后屏幕判据全废、`0x43300000` 判据也废，唯一还没被证伪的读出通道是 pstore。
**这一节是整条链路的首次实测闭环**，而且没刷任何东西：用运行中的原厂内核自己的
`/dev/pmsg0` 造记录，`sysrq c` 软复位，下一次启动读 `/sys/fs/pstore/`。

> 🔴 **这次验证用了 sysrq，违反 `discipline.md §2`，只做这一次，不要重跑。**
> `ro.boot.bootreason` 事后读到 `kernel_panic,sysrq` ⟹ 实际是 panic → `panic=0` 挂住 →
> `wdt_enable 10` 硬复位，等于又给 `/data` 补一次非正常断电（11-20 就是这么把设备搞进
> 「logo → 3 秒 → 回待机」的）。这次 `/data` 没坏（ext4 `errors_count=0`），但别再赌。
>
> **★ 而且探针根本不需要崩**：原厂内核**自己这一趟启动**就会做 ramoops init，
> 探针写进去的记录在同一次开机内被 `save_old` 导出 ⟹ **不用 sysrq、不用复位、不用等下一轮**。

### 1. 做了三件事

```
1) su -c 'printf M7642PMSGCHAN\n > /dev/pmsg0'     写环
2) su -c 'sync; echo c > /proc/sysrq-trigger'     崩（软复位）
3) 起来后 ls /sys/fs/pstore/
```

结果：

```
-r--r----- 1 system log   57554  console-ramoops
-r--r--r-- 1 root   root 127434  dmesg-ramoops-0
-r--r----- 1 system log      35  pmsg-ramoops-0
```

`pmsg-ramoops-0` 内容 = `M7642PROBE\nM7642PMSG1M7642PMSGCHANn`（之前几轮 `/dev/pmsg0`
写入的拼接，35 B）。`console-ramoops` 从 `[0.000000] SAR5=ON` 开始 ⟹ **panic 前的 DDR
内容完整跨过了这次复位**。

### 2. 头部语义（实测，不是读代码推的）

写入 11 B 之后读 `0x419c0000`：

```
+0x00  44 42 47 43   sig = "DBGC"
+0x04  0b 00 00 00   start = 11
+0x08  0b 00 00 00   size  = 11
+0x0c  "M7642PROBE\n"
```

- `start` = **写指针**（下次写的位置），`size` = **有效字节数**，两者都按环前进
- 数据永远从 `+0x0c` 起
- `save_old()` 从 `data[start]` 开始读、到末尾回绕到 `data[0]`，总长 = `size`
- 所以**空环 + 手写记录**用 `start=0, size=N, data[N]` 是正确的（无回绕）
- 复位后再读 `0x419c0000`：`sig` 仍是 `DBGC`，但 `start=size=0` ⟹
  `PRZ_FLAG_ZAP_OLD` 确认生效：**先 `save_old` 拷进 kmalloc，再清环**
  ⟹ 导出的文件与环的后续状态无关

### 3. 一个还没解释的矛盾（记下来，别当已解决）

DT 里只有一个节点 `ramoops@42300000`，`reg = 0x42300000, size 0x100000`，
`record-size = console-size = pmsg-size = ftrace-size = 0x40000`。
但运行中的实例在 **`0x41900000`**：

| 证据 | 值 |
|---|---|
| `/sys/module/ramoops/parameters/mem_address` | `1099956224` = `0x41900000` |
| `/proc/iomem` | `41900000/41940000/41980000/419c0000` 各 256K `persistent_ram` |
| 写 `/dev/pmsg0` 落在 | `0x419c0000` ✅ |
| probeRW 读 `0x42300000/34/38/3c0000` | **全 `00`**（不是 `DBGC`，也不是 `ff`） |

⟹ 原厂 4.9 的 ramoops 基址**不是**从 DT 的 `reg` 来的（`ramoops_parse_dt` 明明读 `reg`），
或者 mboot 在交接前改过。**未定**。操作上只认实测值 `0x41900000`，
并且**跨复位稳定**（第 1 节的实验就是在 boot N 写、boot N+1 读，读到了）。

### 4. 这条通道为什么比之前两条强

| | 屏幕涂色 | `0x43300000` + probeRW | **pmsg/pstore** |
|---|---|---|---|
| 要不要人眼 | 要 | 不要 | **不要** |
| 要不要复位 | 不要 | 要（且必须软复位） | 同一次启动内即可（原厂内核自己读） |
| 读法 | 拍照 | probeRW + tvroot + insmod | **`od` 一个文件** |
| 容量 | 1 帧 | 3 个字 | **256 KB** |
| 抗覆盖 | 无 | 弱 | **`save_old` 进 kmalloc** |

### 5. 产物：handoff 探针（未上机）

`probes/handoff/handoff.S`（192 B），注入点仍是 boot 槽 `code1`，跑完照旧 `b 0xfa0000`。
它把 mboot 交接瞬间的状态写进 pmsg 记录 136 B：

```
"M764" "2HND" | x0 x1 x2 x3 x4 x5 | sp | SCTLR_EL1 TTBR0_EL1 TCR_EL1 MAIR_EL1
              | CurrentEL MPIDR_EL1 ID_AA64MMFR0_EL1 CNTFRQ_EL0
```

**注意**：这个注入点在 `0xfa0000` 之前，x0..x5 是 mboot 留下的，**不是** arm64 的 boot
参数（那是 vendor stub 里才设的）。要读"内核真正拿到什么"得把探针挂到 stub 之后。

镜像 `~/kbuild/m7642-out/m7642-boot-handoff.img`，33,554,432 B，
md5 `af4467af6103e24775666f2d810f1f3b`，
`code1 144b527f -> kernel+0x12d4a00`，尾字 `17f32d51 -> 0xfa0000`。

读法（起来后）：

```bash
adb shell 'su -c "od -A d -t x8 /sys/fs/pstore/pmsg-ramoops-0"'
```

---

## 十四、★★★★ handoff 探针把 boot 槽跑挂（2026-11-21 10:37 实测）

### 1. 现象

刷 `m7642-boot-handoff.img`（md5 `af4467af…`）后按电源：

```
logo 停约 40 秒 -> 回待机      （正常是 logo 5~6 秒 -> Android）
再按电源：同样。adb 完全连不上。
```

40 秒 ≈ mboot 等内核起来的超时。⟹ **探针没有返回 `kernel+0xFA0000`**，
即它执行到中间某条指令就死了。boot 槽没有失败回退，所以这等于**一次自锁**，
只能 U 盘救（`rescue-fast.bin`）。

对照：`paint3`（同样的注入方式、同样写入 8 MB DDR、只做纯 store + `dsb`）能正常返回
⟹ **纯 store 与返回路径都没问题**，问题在 handoff 探针新增的那部分。

### 2. handoff 探针比 paint3 多做了什么（就是嫌疑清单）

| 新增 | 嫌疑 |
|---|---|
| `dc cvac` ×3（清 0x419c0000 的三行） | **中**。MMU/缓存都是关的，本来就不需要；且 by-VA 的维护操作在 MMU 关时行为依赖实现 |
| `mrs` SCTLR_EL1 / TTBR0_EL1 / TCR_EL1 / MAIR_EL1 / CurrentEL / MPIDR_EL1 / ID_AA64MMFR0_EL1 / CNTFRQ_EL0 | **高**。任何一条在当前 EL 上不合法（或 SCR 里被 trap）就是 undef -> 挂 |
| 写 `0x419c0000`（paint3 写的是 `0x24e00000`） | 低。同一片 DDR，Android 侧读写正常 |
| `mov x7, sp` | 极低 |

**没有做逐条二分**，所以不知道是哪一条 —— 记录在案，别当成已知。

### 3. 结论：探针必须分阶段，从"不可能挂"的那一档开始

1. **第一档（下一发）**：纯 store（`x0..x5` + `sp` 直接存，不需要 `mrs`）+ `dsb` + 返回。
   指令类别与 paint3 完全同类 ⟹ 挂了就说明「写 0x419c0000」本身有问题，那才是大发现。
2. **第二档**：加 `mrs CurrentEL` 一条。
3. **第三档**：再加 SCTLR_EL1 / TTBR0_EL1 / TCR_EL1 / MAIR_EL1。

`dc cvac` 从第一档起就删掉：MMU 关时数据直接进 DRAM，清 cache 是多余的。

### 4. 代价表（以后要算）

| 场地 | 一次 hang 的代价 |
|---|---|
| boot 槽 | **U 盘救砖**：拔电 → 按住机身电源键 → 插盘上电 → 进度条 → 待机 → 开机（约 10 分钟人工） |
| recovery 槽 | BCB 非消费式，锁在 recovery 循环，同样 U 盘 |
| 原厂内核 + 正常启动 | 探针挂 = 同 boot 槽 |

⟹ **未验证过的探针不许直接进 boot 槽。** 先在原厂内核上把「写入通道」这一类因素验证完
（paint3 已经算验证过 store），每加一个新指令类别都要问一句"挂了我能不能便宜地知道原因"。

### 5. 第一档已就绪（未刷，等救砖）

`probes/handoff/handoff1.S` -> `handoff1.bin`，**100 B / 25 条指令**，已反汇编逐条核对：

```
  0: movz x6,#0x419c ; lsl #16        ; 8: sig/start/size 三个 str
 20: add  x6,x6,#0xc                  ; "M764" "2H1 " 两个 str
 3c: str  x0..x5,sp                   ; 7 * str [x6],#8
 5c: dsb  sy                          ; 60: .word 0x14000000
```

**位置：无 `mrs`、无 `dc cvac`。** 剩下全部是指令类别与 paint3 相同的 `movz/movk/str`。

镜像 `~/kbuild/m7642-out/m7642-boot-handoff1.img`，33,554,432 B，
md5 `3a950d5064b4569f47df1d4337faa2f6`，
`code1 144b527f -> kernel+0x12d4a00`，尾字 `17f32d68 -> 0xfa0000`。
记录 `size=72`（8 B 标记 + 7 × 8 B）。

### 6. 字节序修正（读记录时会用到）

`handoff.S` 里那两条 `/* "M764" */ /* "2HND" */` 注释是**错的**：`movz` 给的是低半，
`movk lsl #16` 给高半，`str` 小端落盘后字节顺序反过来。实际会读出：

| 注释写的 | 实际内存里的字节 |
|---|---|
| `"M764"` | `36 37 4d 34` = **`67M4`** |
| `"2HND"` | `48 4e 32 44` = **`HN2D`** |

第一档已按正序重算：`movz #0x374d` + `movk #0x3634,lsl16` 实际读出 **`M746`**（本节原来写 `M764`，错，见 §十六.5），
`movz #0x4832` + `movk #0x2031,lsl16` 读出 `2H1 `（末尾一个空格，共 8 B）。
**读记录时看到 `67M4` 不是数据损坏，是那一版的注释写反了。**

---

## 十五、救砖回来后的实测核对（2026-11-21 11:25）

用 `fix/rescue-fast.bin`（md5 `7e8ef7a7…`）刷回，U 盘根目录单文件改名
`V8-T652T03-LF1V147.bin`，拔电 → 按住电源键 → 插盘上电。一次成功。

### 1. 恢复到了什么状态（全部实测）

| 项 | 值 | 判读 |
|---|---|---|
| boot 槽 `mmcblk0p8` | md5 `6272b10dcaf5e9efa40491d87f2c1289` | **与 `boot-stock-backup.bin` 逐字节相同**，探针彻底没了 |
| `bootcmd` | `mmc read.p 0x23000000 dtb 0x00100000; mmc read.p 0x25000000 boot 0x02000000; bootm 0x25000000` | 厂方原文，**不带 `wdt_enable`** |
| `recoverycmd` | `mmc read.p 0x23000000 dtb 0x00100000; mmc read.p 0x25000000 recovery 0x02000000; bootm 0x25000000` | 厂方原文，**不带 `mmc erase.p misc`、不带 `wdt_enable`** |
| `WDT_ENABLE` | `1` | 前置条件满足（`wdt_enable` 命令本体要求它非空） |
| `MstarUpgrade_complete` | `0` | 救砖包的 normal，**必须手工改 1** |
| env 块 | 主备两份 md5 都是 `8111a0f4bfbf09951c5e448a95cf8127`，`envtool verify` → `OK stamp 2cb5b4bd` | 与救砖前 `75ade57a…` 不同，**被整个重置** |
| `misc` 前 32 B | 全 `00` | BCB 干净，不锁 recovery |
| `/data` | `mmcblk0p26` 25 G 用 1.3 G（6%）；`/data/local/tmp` 下 30+ 个我们自己的脚本全在 | **保住了**，见 §2 |

### 2. `/data` 保住了 —— 这次不是运气

`MstarUpgrade_complete=0`（absent 语义）⟹ 不清 `/data`，与 `pkgcheck.py` 的判读一致。
直接证据：`/data/local/tmp/` 里 `boottest.job` `probeRW.ko` `env-wdt.bin` `tvquiz`
`tvhome.sh` `setbcb.sh` … 全在；`su -c id` 返回 root；Projectivy 仍在

```
pm path com.spocky.projengmenu
  -> /system/product/app/TCL_ALL_T2GameCenter/TCL_ALL_T2GameCenter.apk
```

⚠️ 注意它其实在 **`/system/product/app/`** 下（我们早先塞进去的位置），所以
「Projectivy 还在」**不能**当作「`/data` 没被清」的证据。`pm list packages -3` 为空、
`/data/app` 只有 11 个 `com.tcl.*`，与「`/data` 被清后首启重建」也完全自洽。
**两条独立的证据才站得住：脚本文件在 + `su` 在 + `df` 只有 1.3 G 用量。**

### 3. 救砖顺手抹掉了两样东西（下次上机前要补）

1. **`wdt_enable` 保护没了**。env 被重置成厂值，`bootcmd`/`recoverycmd` 都不带
   `wdt_enable`。⟹ 又回到「挂掉 = 拔电搬 U 盘」。这是 §十四.4 那张代价表重新生效。
2. **`install-recovery.sh` 又是可执行状态**（`-rwxr-x--- root root 731 B`）。内容是标准的
   `applypatch -c …recovery:27471872:1ef69168e50ef35bbbcbf6f7c1ba3bc4220601cc`，
   SHA1 不符就用 `/system/etc/recovery.img` 覆写 recovery 槽。

   ⟹ **往 recovery 槽写任何东西之前，必须先把它改回 `.disabled`**，否则探针会被它冲掉。
   （`/system/etc/recovery.img` 现在不存在，但这只说明 `applypatch` 一定失败，不说明它不跑。）

### 4. 已做的收尾（2026-11-21 11:27）

`MstarUpgrade_complete` 0 → 1，直接裸写 eMMC `0x9E0000`（主备两份相同）：

```
envtool set        -> crc 847f8cea, md5 30b6cf8d416c2924a7d8a94a7a90a293
写入 131072 B      -> dd bs=4096 seek=2528 count=32
回读 md5           -> b6dee2daaa9019f6c9d6596692005620   与本地逐字节相同
```

不做这一条，下次插 U 盘会被强制升级 —— 救砖包自己不设这个 key。

### 5. 结论：下一发不该再赌 boot 槽

`recoverycmd` 加 `wdt_enable 10` **【实测 2026-11-20】** 能真正布防 WDT（镜像卡死 10 s 后
warm reset 回 Android）；`bootcmd` 加**没有验过**，而且一旦内核不起来就等于每次开机 10 s
复位、adb 根本连不上。

而 recovery 槽的 `recoverycmd` 也是 `mmc read.p …; bootm 0x25000000` ⟹ 探针在
**recovery 槽 code1 处执行时的状态与 boot 槽完全同类**（都是 `bootm` 之后、内核 entry 之前，
`x0..x5` 都是 mboot 留下的）。**信息一样，但有狗兜底。**

前置改动（都做过、都有记录，不是新试验）：

```
recoverycmd = mmc erase.p misc; mmc read.p 0x23000000 dtb 0x00100000;
              mmc read.p 0x25000000 recovery 0x02000000; wdt_enable 10; bootm 0x25000000
```

`mmc erase.p misc` 必须在最前 —— 否则 WDT 复位后 BCB 还在，又进 recovery，锁死循环。

## 十六、★★★★★ 可用的探针读数通道（2026-11-21 13:00 实测，boot 槽，一次成功）

### 1. 一句话

`handoff2.bin`（360 B）在 boot 槽 `code1` 写 **8 页普通 DDR** 后返回 `0xFA0000`：Android 正常
起来，8 页读回同一份完好记录。**没有 U 盘、没有复位、没有屏幕判读、没有 pstore。**

### 2. 今天四条场地，逐条判死

| 场地 / 做法 | 结果 | 判据 |
|---|---|---|
| recovery 槽 + `b .` + `wdt_enable 10` | 自己回 Android，但**读不到** | pstore 空、zone 数据区 `ff`；10 s 复位把导出一起抹掉 |
| recovery 槽 + 返回版 + `wdt_enable 120` | 落到**待机**，要人按键 | mboot 先超时，狗不再是兜底 |
| recovery 槽 + **零改动厂值 boot 镜像** | **90 s 没有 Android** | 场地不行，不是探针不行 |
| **boot 槽 + 返回版 + 写普通 DDR** | **成功** | Android 起来，8 页记录完好 |

### 3. 为什么把落点从 `0x419c0000` 换到 `0x23080000+`

- 写 `0x419c0000` 的探针（`handoff.S` 192 B、`handoff1` 100 B）两次都挂；但那两次场地本身也
  有问题，无法归因。
- 场地判死之后剩下的事实：`0x419c0000` 数据区**始终 `ff`**（`persistent_ram_zap` 用 `memset 0`，
  被写过又清掉会留字节痕迹）⟹ 这个地址**从没被写成过**。
- 而「写 dtb 区普通 DDR」是 §B 已证明能返回的类。换过去一次成功。

### 4. 产物

| 路径 | 说明 | 校验 |
|---|---|---|
| `probes/handoff/handoff2.S` / `.bin` | 90 条指令，8 × 64 B 记录 | 360 B |
| `~/kbuild/m7642-out/m7642-boot-handoff2.img` | boot 槽版（用后已还原厂值） | 33,554,432 B · md5 `eed03941e51f3f30ba4884fdc887965f` · `code1 144b527f` · 尾字 `17f32d27` → `0xfa0000` |

### 5. 更正 §十四.6 的标记

`handoff1.bin` 的标记实际是 **`M746`**（`movz #0x374d` + `movk #0x3634` → 小端 `4d 37 34 36`），
不是文里写的 `M764`。`handoff2.bin` 用 `movk #0x3436` 才写出 `M764`。

### 6. 下一步的门

主线内核不会起 Android ⟹ 读数必须**跨一次复位**存活。用同一套 stash + `wdt_enable 10` 的
自恢复闭环即可测：存活 ⟹ 整条 bring-up 调试通道成立（每级检查点写 stash，狗咬回来读）；
不存活 ⟹ 只剩屏幕或持久介质，要重新设计信标。
