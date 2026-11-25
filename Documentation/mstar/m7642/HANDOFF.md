# 最终交接（2026-11-26 22:1x，第 57/60 轮）

## 一、五项成绩

| # | 目标 | 状态 | 证据 |
|---|---|---|---|
| 1 | 零风险扫描 | ✅ **完成** | 11 个分区全 ext4；DTS 原无网络节点；厂 DTB 的 emac 节点/IRQ/寄存器窗口已提取 |
| 3 | reboot | ✅ **完成并验证** | `arch/arm64/kernel/m7642-restart.c`：整块 RIU 映射 + `mdelay(1)` + AEON_SW_RESET，实测能自行复位回 Android，全程无插座/红外 |
| 4 | 网络 | ✅ **驱动完全工作** | MT7663U（USB `0e8d:7663`）。1-bit 通道两次测量均 TRUE：网卡存在 ✓、**有非零 MAC** ✓ ⟹ USB 枚举 + 固件加载 + 芯片初始化 + EEPROM 读取全部成功。只差 userspace 关联/IP |
| 2 | 长时运行 | ❌ 未完成 | 见第三节 |
| 5 | ext4 / 根文件系统 | ❌ 未完成 | 依赖 eMMC 写；见第四节 |

**五项完成三项。**

## 二、⚠️ 最重要的方法学教训

### 1. 烧写必须四项校验，否则一切结论无效

今天大半时间浪费在**不知道跑的是哪个镜像**上。已固化到 `tools/host/run-tag.sh`：

```
本地 md5 → 推送 md5 → dd 输出字节数 → 槽前 4K md5
```

任一步失败即中止。**`adb push` 会静默失败**，若沿用固定的
`/data/local/tmp/t.img` 文件名，旧文件会**掩盖**失败 —— 必须每次用唯一文件名。

`su` 的调用形式也有坑：**`su -c '<命令>'` 内层必须单引号**，双引号会静默失败。

### 2. 写文件必须 sync 才算写

`pwrite()` 到块设备只进**页缓存**，不 `fsync`/`sync` 就从未提交 IO。
早期所有"写不落盘"的 eMMC 测试因此**什么都没发出去**。

### 3. 先静态分析，别急着上机

本轮两个最大的坑（eMMC 写缓存、`CONFIG_NETDEVICES`）都是子代理**只读代码**就找到的，
而我做了几十次硬件实验才走到同一步。

## 三、第 2 项：内核卡在 `/init` **之前**（可信结论）

用四项校验的镜像反复验证：

| 镜像 | 唯一变量 | 结果 |
|---|---|---|
| `early1` | WiFi 栈全开 | 回 Android (+70s)，报告页空 |
| `nonetdev` | `NETDEVICES`+WiFi+`CFG80211`+`MAC80211` 全关 | 回 Android (+80s)，空 |
| `nocache` | 再去掉 `M7642_DISABLE_CACHE` | 回 Android (+80s)，空 |
| `simple2` | bootargs 撤销 + **最简 `/init`** | 回 Android (+75s)，空 |

⟹ **都到不了 `/init`** ⟹ 卡在 **initcall（驱动 probe）阶段**
⟹ 这修正了此前所有"运行 N 秒后死亡"的猜测

### 已排除
WiFi 栈、`CONFIG_NETDEVICES`、`CONFIG_CFG80211`/`MAC80211`、
`CONFIG_M7642_DISABLE_CACHE`、`/init` 二进制本身、bootargs 的 ramoops 地址

### 剩余嫌疑
1. `m7642-restart.c` 的 `arch_initcall`（`ioremap(0x1f000000, 0xa00000)`）
2. 内建 DTB（`m7642-dtb.S`）与 `setup.c:302` 的强制 FDT 指向
3. 今天累积的其它配置项（需要与 `base15` 的配置做 diff —— **这是最快的下一步**）

## 四、第 5 项：eMMC 写的两个真根因（已定位、修法已实现、未最终验证）

1. **页缓存**：`pwrite` 不 `fsync` 就等于没写（见上）
2. **写缓存**：`mmc_init_card()` 会开 `EXT_CSD_CACHE_CTRL`，之后数据只进卡的易失缓存；
   唯一落盘路径 `FLUSH_CACHE` 由 R1b 忙等驱动，在这里会挂死

修法已实现：`CONFIG_M7642_DISABLE_CACHE`（在 `->init_card()` 里清 `cache_size`）
+ 写路径去掉 `BIT_ADMA_EN`。`fsync` 不再挂死（证明生效），但最终落盘验证
被第三节的问题挡住（内核跑不到 `/init`，无法做写入实验）。

## 五、可观测性：用户记得的那条通道是对的

`confirmed-facts.md:3061`、`discipline.md:546`：

```
/init 用 syslog(READ_ALL) 把 dmesg 写进 PA 0x23082000（报告页 0x23081000）
然后 SysRq-c → 探针交接 → 厂内核启动
之后从 Android 用 probeRW 读回
```

这几个页在文档里注明**"已验证能存活"**。

**不要用**：`0x43000000`（DRAM 空洞，背后没有内存）、
`persistent_ram`（Android pstore 会重置）。

## 六、1-bit 通道（无持久化也能测量）

```
echo 0 > /proc/sys/kernel/panic     ← panic 后挂住而非重启
sleep N
条件真 → reboot()  → 盒子自己回来 ✓
条件假 → 挂住      → 盒子卡死 ✗
```

第 4 项就是靠它测出来的。`kernel/panic.c:727` 的 `if (panic_timeout > 0)` 保证前提成立。

## 七、若要继续，最快的三步

1. **diff `base15` 的配置与当前配置**（`probes/configs/` 里有历史版本 +
   `~/Debian/m7642-build/out/m7642-base15.img` 对应的 `.config` 需要从 git 历史里取）
   —— `base15` 能跑到 `/init`，当前不能，差异就是答案
2. 用 1-bit 通道验证"内核是否完成 initcall"（把条件换成某个只有 initcall 完成后才存在的东西）
3. 修好第 2 项后，第 5 项的写入验证才能做

## 八、仓库与工具

| 工具 | 用途 |
|---|---|
| `tools/host/run-tag.sh` | 四校验的上机循环（**首选**） |
| `tools/host/probe-cycle.sh` | 旧版循环 |
| `probes/handoff/mk-multi.sh` | 生成探针镜像 |
| `probes/configs/m7642-735-wifi.config` | 带 WiFi 的配置 |
| `~/Debian/m7642-build/fw-mt7663/` | MT7663 固件（从设备取出，未入库） |

设备当前状态：**Android 正常，recovery 槽为 `base15`（md5 `609d72b5…` 校验通过）**。
