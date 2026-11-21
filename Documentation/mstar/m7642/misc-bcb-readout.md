# misc / BCB 判读卡（2026-11-19 19:2x 实测）

只写这次量到的东西，不重新发明结论。

---

## 一、分区映射本身是对的（先排掉「读错分区」）

`/proc/partitions`、by-name 符号链接、整盘绝对偏移三者一致：

| 名字 | 结点 | 起始 LBA | 大小 |
|---|---|---|---|
| misc | `mmcblk0p6` | `0x19800` = 104448 | 8 MiB / 16384 扇区 |
| recovery | `mmcblk0p7` | `0x1d800` = 120832 | 32 MiB |
| boot | `mmcblk0p8` | `0x2d800` = 147456 | 32 MiB |

验证：`dd if=/dev/block/mmcblk0 bs=512 skip=104448 count=1` 与
`dd if=/dev/block/mmcblk0p6 bs=512 count=1` **逐字节相同**。
⟹ 不存在「by-name 指错分区」。

★ 这台机器的分区表**不是 GPT**，是 MStar 自有格式：LBA0 为引导扇区，从 LBA1 起每扇区一条，
每条前 12 字节是 `start_lba(恒 0x5840) / 0 / end_lba`，`size_sect` 在第 12 字节，
第 16 字节起是 ASCII 名。**`end_lba` 是累计值**，某分区起始 = 上一条的 `end_lba`。
共 26 条，顺序与 `mmcblk0p1..p26` 严格对应。

## 二、misc 的实际内容

| 时刻 | 内容 |
|---|---|
| 2026-11-19 18:37（`misc.head.bin`，4096 B） | **全零**（md5 `620f0b67a91f7f74151bc5be745b7110`）|
| 2026-11-19 19:19（`misc.full.bin`，8 MiB） | 前 **48 字节**非零，其余全零 |

那 48 字节是 boot image header v0 从 `magic` 到 `os_version` 的完整字段区（到 `name` 之前）：

```
41 4e 44 52 4f 49 44 21  "ANDROID!"
00 4a 2d 01              kernel_size  = 0x012d4a00 = 19,743,232
00 00 28 20              kernel_addr  = 0x20280000
f1 d1 75 00              ramdisk_size = 0x0075d1f1 = 7,721,457   ← 厂值 recovery ramdisk
00 00 28 21              ramdisk_addr = 0x21280000
00 00 00 00              second_size  = 0
00 00 18 21              second_addr  = 0x21180000
00 01 28 20              tags_addr    = 0x20280100
00 08 00 00              page_size    = 0x800 = 2048
01 00 00 00              header_version = 1
36 01 00 12              os_version   = 0x12000136
```

与 `mmcblk0p7`（recovery）前 48 字节**逐字节相同**；与 `mmcblk0p8`（boot）只差
`ramdisk_size` 那 4 字节（boot 无 ramdisk，为 0）。

⟹ 这 48 字节是 **recovery 分区 header 的副本**，不是 BCB 命令。

## 三、18:37 那个全零不能用来判 BCB 归因

- 11-19 下午每个刷机包的第一条都是 `mmc erase.p misc`（`2026-11-19.md:556`）；
- 用户在 ladder8 实刷（18:3x）之后报「重开还是这个粉底图，**我重刷了**」；
- 18:37 的 dump 落在这次重刷**之后**。

⟹ 那 4096 B 全零是刷机的产物，**符合**「刷机清 BCB」的预期。
**它既不能证明也不能否定 18:3x 当时 misc 里有 `boot-recovery`。**
17:2x 那条 BCB 死循环归因（`boottest.sh arm` 写 `misc[0]="boot-recovery"`，mboot 非消费式
⟹ 每次开机都进 recovery 槽里的 ladder）**仍然是最简解释，未被推翻。**

★ 别再犯这个错：把「刷机之后读到零」当成「当时也是零」。

## 四、`boottest.sh show` 的 BCB 段是坏的（这条确定）

它写的是：

```
dd if=/dev/block/by-name/misc bs=1 count=16 | od -A n -t c
```

`bs=1 count=16` 读 block device 时拿到的是 **recovery header 的前 16 字节**
（`A N D R O I D !`），不是 misc 偏移 0。所以它打印的「BCB」一直是假读数 ——
之前据此判断「BCB 已空」的记录全部作废。

**以后要判 BCB，只用**：`dd if=/dev/block/by-name/misc bs=512 count=1 | od -A d -t x1z -N 64`。

## 五、19:1x `adb reboot recovery` 留下的 48 字节无害（实测）

- 之后系统自动重启并正常进入 Android；
- misc 里那 48 字节仍在。

⟹ 它**不是**「下次进 recovery」的开关，不需要清理。
也因此不能把它当成「已 arm」的标记去依赖 —— 它和 `boot-recovery` 是两回事。

## 六、未解（明确标注，别猜）

- 48 字节到底由 `reboot recovery` 写、还是 recovery 起来后自己写？无法区分，
  只能靠 UART 看 mboot 时序，用户已排除 UART。
- mstar 判定「这次启动 recovery」的机制：标准 BCB（misc 偏移 0 的 `boot-recovery` 字符串）
  是**在用的**（17:2x 归因依赖它），但 `adb reboot recovery` 显然走了另一条路。
  两条路的关系未查清。
- 11-17 观察到的 `boot-adb`（Android 每次启动重写 misc 前 8 字节）在 11-19 数次刷机后
  再没出现。**未查。**
