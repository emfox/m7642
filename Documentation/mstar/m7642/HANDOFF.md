# 交接：当前状态与下一步（2026-11-26 23:4x 重写）

> 本文件**取代**此前所有交接版本。旧的 `HANDOFF.md`/`NEXT-SESSION.md`
> 里关于"内核活不长"、"卡在 /init 之前"、"CONFIG_NET 一开就挂"的结论**是错的**，
> 已删除，不要再用。

## 一、五项成绩

| # | 目标 | 状态 | 证据 |
|---|---|---|---|
| 1 | 零风险扫描 | ✅ **完成** | 11 个分区全 ext4；DTS 原无网络节点；厂 DTB 的 emac 节点/IRQ/寄存器窗口已提取 |
| 3 | reboot | ✅ **完成并验证** | `arch/arm64/kernel/m7642-restart.c`：整块 RIU 映射 + `mdelay(1)` + AEON_SW_RESET，实测自行复位回 Android，全程无插座/红外 |
| 4 | 网络 | ✅ **驱动完全工作** | MT7663U（USB `0e8d:7663`）。1-bit 通道两次测量均 TRUE：网卡存在 ✓、**有非零 MAC** ✓ ⟹ USB 枚举 + 固件加载 + 芯片初始化 + EEPROM 读取全部成功。只差 userspace 关联/IP |
| 2 | 长时运行 | ⬜ 未完成 | 见第三节 —— **障碍是可观测性，不是内核本身** |
| 5 | ext4 / 根文件系统 | ⬜ 未完成 | 见第四节 —— eMMC 写不落盘，根因未定 |

**五项完成三项。**

## 二、★ 最重要的更正：内核一直是正常的

用 1-bit 通道做的自证实验（`memtest`，见 `confirmed-facts.md` §36.16）：

```
/init: mmap("/dev/mem", 0x23081000) → 写 8 个已知值 → msync → 同启动内读回比对
       一致 → reboot()；不一致 → 挂住（panic=0 让 panic 挂住而非重启）
```

结果 **盒子自己回来了** ⟹ 判定 TRUE ⟹ 三条同时成立：

1. **`/init` 确实执行了** ✓
2. **`/dev/mem` 写 RAM 成功** ✓
3. 内核**没有**"卡在 initcall"、**没有**"15–20 秒必死"

⟹ **唯一的失败环节是"数据跨交接存活"** ✗ —— 厂内核（Android）启动时会把
`0x23081000` 这块普通 System RAM 分配并清零。
当年那条"写到 `0x23081000` 再交接读回"的通道能work，是因为**那时的 Android 恰好没碰那页**，
它从来不是可靠通道。

## 三、可观测性：三条路，只有一条可靠

| 方案 | 状态 |
|---|---|
| 普通 DRAM 页（`0x23081000`/`0x23082000`） | ❌ 被 Android 清零（复刻文档做法验证过，§36.17） |
| DRAM 空洞（`0x43000000`） | ❌ 背后没有内存，写不进去（§36.06） |
| **ramoops 注入**（让 Android 的 pstore 读我们） | 🚧 **接近成功**，见第五节 |
| **1-bit 通道** | ✅ **唯一已验证可靠、可立即使用** |

### 1-bit 通道（务必先读这段）

```
echo 0 > /proc/sys/kernel/panic   ← 关键：panic 后挂住而非重启
sleep N
条件真 → reboot()  → 盒子自己回来 ✓
条件假 → 挂住      → 盒子卡死 ✗
```

前提由 `kernel/panic.c:727` 的 `if (panic_timeout > 0)` 保证。
内核提前死亡也只会挂住，不会被误判为"真"。
**每次上机回答一个是非问题** —— 慢，但确定。

## 四、第 5 项：eMMC 写

### 已确认的两个根因层

1. **页缓存**：`pwrite()` 到块设备只进页缓存，不 `sync`/`fsync` 就等于没写
   （早期所有"写不落盘"的测试因此**什么都没发出去**）
2. **写缓存**：`mmc_init_card()` 会开 `EXT_CSD_CACHE_CTRL`，数据只进卡的易失缓存，
   唯一落盘路径 `FLUSH_CACHE` 由 R1b 忙等驱动、在这里会挂死
   ⟹ 修法 `CONFIG_M7642_DISABLE_CACHE`（在 `->init_card()` 里清 `cache_size`）

### 但排除了两层之后仍然不落盘

`emmcbit` 探针（`DISABLE_CACHE=y` + `pwrite` + `sync` + 同启动内 `pread` 比对）：
**判定 FALSE**，而且事后读 LBA 61000000 是**全零**。

⟹ 写数据通路本身还有问题（DMA / 描述符 / 块大小），需要读寄存器才能定位 ——
而这又回到"没有观测通道"的问题。**所以先解决观调通道，再回来查 eMMC。**

## 五、ramoops 注入：当前最有希望的一条路

### 关键事实（全部实测得到）

Android 的 ramoops 参数：

```
mem_address  = 0x41900000      mem_size     = 1 MiB
record_size  = 0x40000         console_size = 0x40000
pmsg_size    = 0x40000         ftrace_size  = 0
ecc          = 0               dump_oops    = 0
```

`pstore` **已经挂载**在 `/sys/fs/pstore`（现在为空）。

### 真实 zone 布局（由厂内核 `fs/pstore/ram.c` 推导，不是猜的）

```c
dump_mem_sz  = size - console_size - ftrace_size - pmsg_size;   /* = 0x80000 */
max_dump_cnt = dump_mem_sz / record_size;                        /* = 2 */
```

| 地址 | zone |
|---|---|
| `0x41900000` | record #0 |
| `0x41940000` | record #1 |
| **`0x41980000`** | **console** ← 应该写这里 |
| `0x419C0000` | pmsg |

**ramoops 只覆盖 `0x41900000..0x41A00000`，越界会落进"没有内存的空洞"并挂死**
（我试过写四个 zone，越界了，结果挂死）。

### 之前的失败原因

一直往 `0x41940000` 写"console 格式"记录 —— 那实际是 **record #1（dmesg 区）**，
**必须带 `====` 的 kmsg 头**，没带就被 `post_init` 判无效并 zap
（读回时 sig=`DBGC` 保留、size 归零，正是 `persistent_ram_zap` 的行为）。

### 下一步（两条，二选一）

**A. 直接写 `0x41980000`**（真正的 console zone），格式同 `psinj5.c`：
`sig=0x43474244 | start=n | size=n | 文本`，然后 `reboot()`，Android 一起来立刻看
`/sys/fs/pstore`。

**B. 让内核代劳**（更稳）：把 cmdline 改成
```
ramoops.mem_address=0x41980000 ramoops.mem_size=0x40000 ramoops.console_size=0x3fff4
```
让我们内核的 `persistent_ram` 代码自己记账，格式和边界一定合法。

## 六、方法学：三条硬纪律

### 1. 烧写必须四项校验

```
本地 md5 → 推送 md5 → dd 输出字节数 → 槽前 4K md5
```

任一步失败即**中止，不产生任何结论**。已固化到 `tools/host/run-tag.sh`。

- **`adb push` 会静默失败** ⟹ 必须用**唯一文件名**（固定的 `t.img` 会让旧文件掩盖失败）
- **`su -c '<命令>'` 内层必须单引号**，双引号静默失败（这条曾让几十轮实验全白做）
- **`dd` 要加 `conv=notrunc`**

### 2. Android 会把 recovery 分区还原

测试后槽里又出现原厂镜像 `8575bff3…`。
⟹ **每次测试必须"刷完立刻重启"**，不能刷完再等。

### 3. 先静态分析，别急着上机

今天两个最大的坑（eMMC 写缓存、`CONFIG_NETDEVICES`）都是子代理**只读代码**找到的，
而我做了几十次硬件实验才走到同一步。ramoops 的 zone 布局也是读代码一行推出来的。

## 七、仓库与工具

| 工具 | 用途 |
|---|---|
| `tools/host/run-tag.sh` | **四校验的上机循环，首选** |
| `tools/host/probe-cycle.sh` | 旧版循环（校验不如上面严） |
| `probes/handoff/mk-multi.sh` | 生成探针镜像 |
| `probes/configs/m7642-735-wifi.config` | 带 WiFi 的完整配置 |
| `~/Debian/m7642-build/fw-mt7663/` | MT7663 固件（从设备取出，未入库） |
| `~/Debian/m7642-build/kernel/mstar-4.9` | 厂内核源码（静态分析用） |

设备当前状态：**Android 正常；recovery 槽为 `base15`（`609d72b5…` 校验通过）**。

## 八、下次接手的第一步

1. 读本文件 + `discipline.md` 的 §0/§1/§2
2. 确认设备状态：`adb connect 192.168.10.60:5555` → `getprop sys.boot_completed`
3. 按第五节 **A 或 B** 做 ramoops 注入 —— 通了就有完整 dmesg 通道
4. 通道通了之后，第 2 项和 eMMC 写都会变得可查
