# 自建恢复 U 盘：把"改了就回不来"变成"插盘就回来"

> 结论先行：mboot 的 U 盘升级文件是一个**纯文本 MBOOT 脚本 + 若干分区镜像**。脚本里能
> `mmc write.p` 任意分区。所以**我们可以自己做一张救援盘**，把原厂 misc/dtb/boot/recovery
> 写回去。这是目前唯一能在"内核不跑"的情况下把机器救回来的手段，而且它的有效性可以用
> **零风险**的方式先验证。

## 一、BIN 的结构（`fw/mstar-bin-tool-master` 源码 + 实测互证）

```
+0x0000  16 KB header = 纯文本 MBOOT 脚本，以单独一行 '%' 结束，其余填 0xFF
+0x4000  part 1     \  依次拼接，每个 part 4 字节对齐，空隙填 0xFF
         part 2     /
         ...
尾部 40 字节（实测我们生成的 BIN，与 pack.py 的描述一致）：
  31 32 33 34 35 36 37 38    "12345678"（8 字节 magic）
  03 8e 2f 16 00 00 00 00    header 的 CRC32，u64 小端（高 32 位为 0）
  27 4a 71 52 00 00 00 00    parts 的 CRC32，u64 小端
  23 0a 23 20 ... 79         header 的前 16 字节
```

两个 CRC 的覆盖范围（已实测核对）：

| 字段 | 覆盖 | 验证 |
|---|---|---|
| CRC1 | 前 16 KB（脚本块） | `crc32(header) = 0x162f8e03`，与写入值一致 |
| CRC2 | **只有 parts**（不含 16 KB 头、不含 footer） | `crc32(d[0x4000:-40]) = 0x52714a27`，与写入值一致 |

CRC1 与我们自己独立写的 `fw/fix_footer_crc.py` 判定完全一致（那个工具只改 CRC1，
因为它处理的是"改了脚本"的场景）；CRC2 的覆盖范围是从 `pack.py` 的实现反推并试算对上的。

## 二、脚本里能用的命令（从 mboot 二进制里实证）

| 命令 | 证据 |
|---|---|
| `mmc read.p <addr> <part> <size>` | 内置 `recoverycmd` = `mmc read.p 0x45000000 recovery 0x00800000; bootm 0x45000000` |
| `mmc write.p <addr> <part> <size>` | 6 处引用，是升级脚本写分区的主力 |
| `filepartload <addr> <file> <offset> <size>` | 从 U 盘里的 BIN 取一段到内存 |
| `setenv` / `saveenv` / `cleanallenv` | 有；`saveenv` 会写 env 分区（含备份份 + CRC） |
| `mmc erase` / `mmc slc` / `mmc rmgpt` | 有 |

**没有 `booti`。** 搜到的 5 处命中都是 `booting` 的子串。这一代 U-Boot（2011.06）的
`bootm` 只按 32 位起核，**没法把 arm64 的 `Image` 直接从 U 盘引导起来**。
⟹ 想跑我们的内核，必须先把镜像落到某个分区，再让 mboot 自己的 arm64 加载路径去启动它。

## 三、于是有两条脚本路线

**A. 救援盘（先做）**

```
mmc write.p <addr> misc     0x00800000     # 原厂 misc（BCB 复位）
mmc write.p <addr> dtb      0x00100000     # 原厂 DTB
mmc write.p <addr> boot     0x02000000     # 原厂 boot.img
mmc write.p <addr> recovery 0x02000000     # 原厂 recovery
```
插盘上电即复位。这是"变砖"的唯一出口。

**B. 测试盘**

```
mmc write.p <addr> recovery 0x02000000     # 我们的 boot.img
mmc write.p <addr> misc     0x00800000     # 预先做好的、command = boot-recovery 的扇区
```
上电 → 自动进 recovery 槽 → 跑我们的内核。**失败时插 A 盘上电即可回滚。**

## 四、payload 已经有了（`/home/emfox/kbuild/backup/`）

| 文件 | 大小 | md5 |
|---|---|---|
| `boot.img` | 33554432 | `6272b10dcaf5e9efa40491d87f2c1289` |
| `recovery.img` | 33554432 | `7c2f467bbda49053951c0ce547d11a00` |
| `dtb.img` | 1048576 | `b3e1886db49b2299e363bf1f611e7d97` |
| `misc.img` | 8388608 | `f675a81b04498cbc4ca79c62692bcc77` |

全部用 `dd` 从 `/dev/block/by-name/*` 整分区读出，`chmod 644` 后 `adb pull`。

## 五、怎么零风险验证 mboot 认不认自制 BIN

BIN 不对时 mboot 只会忽略它、照常启动 —— **这一步本身不写 flash**。
所以第一张盘只放**已经和现网完全相同**的 payload（原厂镜像写回原厂内容），
观察量是"插盘上电后会不会自动重启 / 分区 md5 有没有变"。变了 = 通道成立。

文件名还没确认：mboot 里出现过 `MstarUpgrade.bin` 与 `*.bin` 两种痕迹，
先按 `MstarUpgrade.bin` 放在 U 盘根目录（FAT32）试。

## 六、为什么这条路能解开"sticky BCB"

此前卡死的地方是：`boot-recovery` 一旦写进 misc 而内核起不来，每次上电都再进 recovery，
而 recovery 里的 adbd 因为 `ro.debuggable=0` 根本不起（见 `mboot-bootmode.md`）。
有了救援盘，**出口不再是软件，而是"插盘 + 上电"** —— 一次物理动作，不需要按键、
不需要屏幕、不需要串口。

## 七、待办

- [ ] 用 `pack.py` 配一张 A 盘（原厂四分区），验证通道成立
- [ ] 确认 mboot 找的文件名（`MstarUpgrade.bin` / `*.bin` / 大小写敏感）
- [ ] 通道成立后再做 B 盘（测试盘）
