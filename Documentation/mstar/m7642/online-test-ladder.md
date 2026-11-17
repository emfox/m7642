# 交叉编译 + 在线验证：四条阶梯，实测到哪一步

2026-11-17。用户问能不能"交叉编译 + 在线测试"逐个验证硬件可移植性。这份是实测记录，不是设想。

## 结论先说

**能，但要分两层**：

- **源码层的可移植性**（驱动代码离主线有多远）→ 完全离线可测，批量、零风险，今天就能出结果；
- **硬件层的可验证性**（这段寄存器序列在这块板子上到底成不成）→ 必须先能让代码跑起来，
  而这台机器目前**只有一条路是通的：刷 boot 分区**。在线那几条，实测卡住了。

## 阶梯与实测结果

| 级别 | 手段 | 风险 | 现状 |
|---|---|---|---|
| L0 | 源码对主线头文件试编译，统计报错/改动行数 | 无 | ✅ 可做，未开始 |
| L1 | 自建内核模块 `insmod` 进运行中的系统 | 中（能拖垮内核） | ⚠️ **模块能加载，但 `module_init` 从不执行**——探针代码必须放进 `module_exit`，靠 `rmmod` 触发。详见 [display.md](display.md) |
| L2 | `kexec` 热加载新内核 | 中 | ❌ 不可用：`# CONFIG_KEXEC is not set`、`# CONFIG_DEVMEM is not set` |
| L3 | 刷 boot 分区，失败用 U 盘救 | 低（可回滚） | ✅ 可行，约 10 分钟一轮 |

## L1 实测细节（今天做的）

**交叉编译这一半完全成功：**

```
vermagic = 4.9.118+ SMP preempt mod_unload modversions aarch64   ← 与设备逐字相同
__versions = 2 条：module_layout 0xdac13caf、printk 0x27e1a049   ← 与设备 __versions 完全一致
```

做法：用设备 `expect.tsv` 里的 2908 个符号 CRC **合成一份 Module.symvers**，再用它编译外部模块，
这样模块自带的 `__versions` 就是设备的真实 CRC，不需要内核源码一致。

**权限这一半也搞清楚了：**

| 提权方式 | CapEff | 能否 insmod |
|---|---|---|
| `/factory/su -p -c` | `0000000000000000`（bounding set 只剩 SETUID/SETGID） | ❌ EPERM |
| init 服务 `tvroot`（`/init.rc:911`） | `0000003fffffffff`（全能力） | ✅ 可以尝试 |

**但加载这一步一开始卡死，后来定位到工具问题：**

```
/system/bin/insmod  <file>          → 进程 R、100% CPU、零日志、SIGKILL 无效   ❌
/vendor/bin/busybox insmod <file>   → 正常加载，initstate=live               ✅
/system/bin/rmmod <name>            → 正常卸载                                ✅
/vendor/bin/busybox rmmod <name>    → chdir(/lib/modules) 失败，卸不掉         ❌
```

**结论：toybox 的 `insmod` 走 `finit_module(2)`，这条路在这颗内核上自旋；
busybox 的 `insmod` 走老的 `init_module(2)`，正常。** 卸载反过来——toybox 的 `rmmod` 可用，
busybox 的会先 `chdir("/lib/modules")` 而那个目录不存在（`/lib` 是只读的创建不了）。

一次实测记录：

```
empty 16384 0 - Live 0x0000000000000000 (O)      # 空模块，init 返回 0
hello 16384 0 - Live 0x0000000000000000 (O)      # 带 pr_info 的模块，initstate=live
```

所以现在的在线循环是：

```sh
/vendor/bin/busybox insmod /data/local/tmp/<drv>.ko   # 加载
cat /proc/modules | grep <drv>                        # 确认在
dmesg | grep <标记>                                   # 看输出
/system/bin/rmmod <drv>                               # 卸载，改代码重来
```

**代价**：搞砸了最坏是内核 panic/自旋 → 断电重启，不碰任何分区、不需要 U 盘。

## 所以真正能批量做的，是 L0

对每个厂商驱动，用主线头文件试编译，产出三列数字：

| 驱动 | 编译错误数 | 缺的子系统/API | 结论 |
|---|---|---|---|
| `mstar_mci_v5.c`（eMMC） | ? | ? | ? |
| `mdrv_emac_v3.c`（网口） | ? | ? | ? |
| `mspi-mstar`（SPI） | ? | ? | ? |
| `gflip`/`graphic`（显示） | ? | ? | ? |

这个表能把"1.5–3 人年"拆成"哪几个驱动便宜、哪几个是天价"，而且一次跑完、不碰设备。

## 遗留

- 之前的自旋进程已随重启清除；设备当前干净（无残留模块）。
- `toybox insmod` 自旋的确切位置仍未定位（`/proc/<pid>/stack` 需要 CAP_SYS_ADMIN，
  `sysrq-t` 没编进内核），但已不影响使用——绕开即可。
- 顺带确认：空模块（`module_init` 直接返回 0）**也会**自旋，所以问题在加载路径而不在模块内容。
