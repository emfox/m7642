# mboot 环境变量(ENV):位置、格式、启动路径

> 2026-11-19 19:4x 实测。数据来自 eMMC 前 64 MB 转储(`~/kbuild/emmcboot/e64.bin`),
> 备份 `env-primary.bin` / `env-backup.bin`,工具 `tools/host/envtool.py`。

## 一、位置

**⚠️ 2026-11-20 实测更正：这两块在 `MPOOL` 分区（p2）里，不在 `MBOOT`（p1）。**

分区实测（`/sys/class/block/mmcblk0p*/start`，扇区×512）：

| 分区 | LBA 起 | LBA 数 | 字节范围 |
|---|---|---|---|
| `MBOOT`(p1) | 4096 | 10240 | 2,097,152 .. 7,340,032 |
| `MPOOL`(p2) | 14336 | 6144 | 7,340,032 .. 10,485,760 |

| | 全盘偏移 | MPOOL 内偏移 | LBA（bs=512） | length |
|---|---|---|---|---|
| 主 | `0x9E0000` = 10,354,688 | `0x2E0000` | 20224 | 64 KiB |
| 备 | `0x9F0000` = 10,420,224 | `0x2F0000` | 20352 | 64 KiB |

按 `bs=4096` 算更省事：主份 `skip/seek=736`，备份 `752`，各 `count=16`。

主备**逐字节相同**(md5 一致),不是带编号的冗余对,只是简单镜像。

出处是 cmdline 自己写的:

```
ENV=EMMC ENV_VAR_OFFSET=0x0 ENV_VAR_SIZE=0x10000
```

`0x1D800`、`0x2D800` 是 misc/boot 的 LBA,别与这里混。

**写回时必须落到 `MPOOL`，落到 `MBOOT` 会写坏 bootloader 本体。** 旧版本文档写的是
"在 MBOOT 内、先算 `0x9E0000 - MBOOT 起始`"，那条是错的——`0x2E0000` 减完是 `0xE0000`，
落在 MBOOT 的 5 MiB 范围里，看起来合理，实际写的是 U-Boot 代码段。

`0x4B0000` 处另有一份 `bootcmd=if mmc rescan ${mmcdev}; ...`,
那是 **U-Boot 本体里的默认值字符串**,不是生效的 ENV。别读错。

## 二、格式

```
0x0000  crc32, little endian, covers bytes [0x0004, 0x10000)
0x0004  key=value, NUL separated, zero padded to 0x10000
```

数据区实际到 `0x121A` 结束,128 条。

两条独立证据说明没有隐藏字段:

1. `zlib.crc32(blk[4:])` = `0x37BDCF02`,pack 小端正好是文件头 `02 cf bd 37`;
2. `envtool.py set` 以原值改写整块,结果**逐字节相同**。

⟹ 改写只需重算 CRC 并同时写主备两份。

## 三、决定启动走向的变量

| 变量 | 当前值 | 作用 |
|---|---|---|
| `bootcmd` | `mmc read.p 0x23000000 dtb 0x00100000; mmc read.p 0x25000000 boot 0x02000000; bootm 0x25000000` | 正常启动:dtb → **boot** 槽 |
| `recoverycmd` | 同上,但 `... recovery 0x02000000 ...` | recovery 启动:dtb → **recovery** 槽 |
| `upgrade_mode` | `null` | 非 null 时走升级路径 |
| `ForceUpgradePath` | `/v8-t652t03-lf1v147.bin` | **U 盘强制升级要找的文件名** |
| `ForceUpgrade_path` | `V8-T652T03` | 同上,前缀形式 |
| `MstarUpgrade_complete` | `0` | 刷完置 1 用于清盘 |
| `mboot_default_env` | `0` | 0 = 用这份 ENV;1 = 用 bootloader 内嵌默认 |
| `first_bootup` / `first_setup` | `1` / `1` | /data 清空后重走首次开机 |
| `WDT_ENABLE` | `1` | 看门狗 |

★ **U 盘刷机"根目录只能有一个 `.bin`、名字固定 `V8-T652T03-LF1V147.bin`"这条规矩,
出处就是 `ForceUpgradePath`。** 名字不对 ⟹ mboot 找不到 ⟹ 当没插盘处理。

★ `first_bootup=1` 与 `/data/app`=0、`/data/data`=0 同时成立,是 "/data 又被清空" 的直接现场证据。

## 四、两条启动路径

```
bootcmd      : dtb → boot      → bootm
recoverycmd  : dtb → recovery  → bootm
```

两者都读同一份 dtb(`0x00100000`),只有第三个参数(分区名)不同。
这是**唯一**的分叉点,所以在 ENV 层面把 `recoverycmd` 改成与 `bootcmd` 相同,
就能让"选 recoverycmd 的那次启动"实际从 boot 槽起来。

## 五、未解:recovery 意图怎么跨掉电保持

三个观测:

1. `misc` 首扇区全零时,`adb reboot recovery` 仍能进 recovery;
2. 19:19 转储到 `misc` 前 **48 字节** = recovery 分区 header 的副本;
3. ENV 里**没有**任何 recovery 标志(`upgrade_mode=null`)。

候选解释:

- (a) Android 侧在 `reboot recovery` 时把意图写进 misc 首 48 字节(观测 2 支持);
- (b) 意图只在 RAM / 寄存器里,掉电即失(观测 1、3 支持)。

**两者都未被验证。** 若 (a) 成立,则拔电必回 recovery 槽,与 11-19 实测"拔电没回来"一致;
若 (b) 成立,则拔电应回 boot 槽,与实际不符。⟹ 证据偏向 (a),但不足以下结论。

## 六、怎么改,怎么救

```sh
envtool.py set env-primary.bin recoverycmd='...'
envtool.py verify env-primary.bin
```

写回:主备两份都要写,`dd` 到 `0x9E0000` 与 `0x9F0000` 各 64 KiB。

风险:ENV 改坏 mboot 可能完全不启动。兜底只有 U 盘强制升级(`rescue-fast.bin`),
而那条路会清 `/data`。⟹ 改 ENV 前必须留存原始块,本目录两份即为此用。

## 七、★ 自愈式 `recoverycmd`：让 recovery 挂了也能从 boot 起

2026-11-20，为解决「测试镜像起不来就锁死在 recovery 死循环、每次都要 U 盘 + 按住机身键」而设计。
**离线验证完成，尚未写回设备。**

### 1. 机制

`recoverycmd` 唯一的约束是**前 4 字节必须 `"mmc "`**（`boot_mode_recovery()` 的检查），
之后整条被 `run_command()` 执行。而 mboot 的命令表里有 `mmc erase.p <partition>`
（二进制字符串 `mmc erase.p misc` / `mmc erase.p partition_name` 原样存在）。

⟹ 在 `recoverycmd` **开头**插一条擦 misc：

```
mmc erase.p misc; mmc read.p 0x23000000 dtb 0x00100000; mmc read.p 0x25000000 recovery 0x02000000; bootm 0x25000000
```

执行顺序：

1. mboot 读 BCB = `boot-recovery` ⟹ 决定走 recovery 路径（**读 BCB 在这一步之前**）
2. 执行 `recoverycmd`，**第一条就是擦 misc** —— BCB 没了
3. 读 dtb → 读 recovery 槽 → `bootm` 起测试镜像
4. 测试镜像起不来 ⟹ 断电重上电 ⟹ misc 是空的、不是 `boot-recovery`
   ⟹ **走 `bootcmd` ⟹ 起 boot 槽 ⟹ Android**

**关键点：擦 CB 发生在"已经决定走 recovery"之后、"起内核"之前。**
所以它不影响本次进 recovery，只影响下一次。

### 2. 收益与代价

| | 之前 | 之后 |
|---|---|---|
| 测试失败后恢复 | 拔电 + **按住机身键** + 插电 + 等进度条 + 拔 U 盘 + 补 `MstarUpgrade_complete` | **拔电 → 上电 → 按电源键** |
| 需要 U 盘 | 要 | 不要 |
| 需要 adb | 不需要（但也没有） | 不需要 |

代价：以后每次进 recovery 都会清 BCB ⟹ **recovery 不能"重启再进"**（在 recovery 里点重启会回 Android）。
对实验无害，对正常系统更新也无害（recovery 自己本来就会清 BCB）。

### 3. 离线验证（已完成）

```sh
cp env-primary.bin env-test.bin
envtool.py set env-test.bin \
  'recoverycmd=mmc erase.p misc; mmc read.p 0x23000000 dtb 0x00100000; mmc read.p 0x25000000 recovery 0x02000000; bootm 0x25000000'
envtool.py verify env-test.bin      # OK stamp 9bae6e7f
envtool.py list  env-test.bin       # 128 entries，与原件逐行 diff 只有 recoverycmd 与 crc 两行不同
```

### 4. 写回（2026-11-20 已完成）

主备两份都写，各 64 KiB，落到 **`MPOOL`**：

```sh
BB=/vendor/bin/busybox            # toybox dd 的 conv= 在这个 ROM 里被禁用了
DEV=/dev/block/by-name/MPOOL
$BB dd if=env-new.bin of=$DEV bs=4096 seek=736 count=16 conv=notrunc   # 主 0x2E0000
$BB dd if=env-new.bin of=$DEV bs=4096 seek=752 count=16 conv=notrunc   # 备 0x2F0000
sync
$BB dd if=$DEV bs=4096 skip=736 count=32 2>/dev/null | md5sum          # 读回比对
```

**实际发生的两个坑，都记在这里：**

1. **toybox dd 不支持 `conv=`**：`/system/bin/dd` 报 `dd: conv option disabled`，
   整个写入被丢弃（好在读回 md5 未变，没造成损害）。改用 `/vendor/bin/busybox dd`（1.19.2，支持）。
2. **sh 里 `DD=/vendor/bin/busybox dd` 不是赋值一个字符串**，而是赋 `DD=/vendor/bin/busybox`
   然后**执行命令 `dd`**。后续 `$DD if=...` 展开成 `/vendor/bin/busybox if=...`，
   busybox 报 "not found"，一个字节都没写。二进制名和 applet 名必须分开成两个词。

**2026-11-20 实测结果**（当前设备状态）：

```
写入前  131072 B md5 fbe7a98c5f9e9dcd9c479a798477dc6a    (= 救砖包重写后的值)
写入后  131072 B md5 ffe8f1fd266893fc3ac166900ac02df7    (= env-new.bin × 2)
envtool verify 主份 OK stamp 33a74f41
envtool verify 备份 OK stamp 33a74f41
设备读回解析：MstarUpgrade_complete=1，recoverycmd 已带 mmc erase.p misc
```

⚠️ **`rescue-fast.bin` 会重写 env**，所以救砖之后必须重新做这一步，不能沿用旧文件。
2026-11-20 那次救砖把 `MstarUpgrade_complete` 打回了 0，同时 `md5` 从 `16248b92…` 变成 `505fa09a…`。

### 4.1 `MstarUpgrade_complete` 是一次性标志（实测）

设成 `1` → 重启 → 再读，值回到 `0`，**其余 127 项一字未动**，主备两份同步重算 crc
（`33a74f41` → `9b6d7716`）。

⟹ mboot 读到 `1` 就跳过 U 盘升级、然后自己复位。所以这个 key **不需要（也无法）长期保持为 1**；
救砖后补一次即可，目的是让紧随其后的那次开播不再走升级流程。

⟹ **`recoverycmd` 在整个启动过程中稳定不变**，这是自愈机制成立的前提。

### 5. 风险与回滚

- **风险**：env 改坏 ⟹ mboot 可能完全不启动（比 dtb 坏更严重）。
  不过强制升级（按住机身键上电）走 mboot 内部逻辑、**不读 `recoverycmd`**，U 盘救砖这条路不受影响。
- **回滚资源**：
  - `emmcboot/now/env-now.bin` —— **2026-11-20 写前现场值**（128 KiB，主备两份连续），回滚就用它
  - `emmcboot/now/env-after.bin` —— 写后值，用于复核
  - `emmcboot/env-primary.bin` + `env-backup.bin` —— 更早的备份（`16248b92…`，已被救砖包覆盖，仅存档）
  - `emmcboot/e64.bin` —— eMMC 前 64 MB 全量
  - U 盘 `rescue-fast.bin`
- **回滚命令**（把现场值原样写回）：
  ```sh
  BB=/vendor/bin/busybox; DEV=/dev/block/by-name/MPOOL
  $BB dd if=env-now.bin of=$DEV bs=4096 seek=736 count=32 conv=notrunc   # 两份一起覆盖
  ```
- **副作用**：`mmc erase.p misc` 本身也会清 misc 的其它字段。`rescue-fast.bin` 同样这么做，
  属常规操作；Android 启动会把 BCB 重写成 `boot-adb`。

### 6. 未能验证的两点

1. `mmc erase.p misc` 在 `recoverycmd` 上下文里执行时的耗时与失败行为（若失败，U-Boot 一般只打错误、
   继续后续命令 ⟹ BCB 留在原地，自愈失效但不影响本次启动）。
2. misc 分区大小（决定擦除耗时）。`mmc erase.p misc` 擦整个分区。
