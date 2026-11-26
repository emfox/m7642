# RULES.md — 动手前必读（10 行硬约束）

> 这份文件存在的唯一原因：长会话被压缩后，我会忘记下面这些**用失败换来的硬约束**，
> 然后重复踩坑、浪费设备时间。**每次要碰设备（adb / 烧写 / 断电）之前，先读这一页。**
> 不要把它合并进别的文档，不要摘要它，保持短。

## 一、跑我们的镜像：只有一条路

**只用 `tools/host/run-bcb.sh <tag>`。** 它写 `boot-recovery` 进 misc 然后插座断电。

**`adb reboot recovery` 是坏的**：Android 在关机/下次启动时用 `/system/etc/recovery.img`
覆盖 recovery 分区，mboot 加载到的仍是厂内镜像 —— 表现为"我们的镜像什么都没做"。
*这条我 2026-11-26 上午又犯了一次，浪费约 4 小时。*

## 二、电源与恢复时序（最短）

断电 **10 秒** → 上电 → **等 3 秒** → 红外 `POWER`。
Android 恢复约 **49–97 秒**；adb 要 **~100 秒**后才应答。

## 三、adb 是"会撒谎"的通道

- 每个 adb 步骤前：`kill-server` → `start-server` → `connect`，**不是只 connect**。
- 读回空 ≠ 失败，**必须重试**（3 次）。
- 推送要先用 **文件大小** 判定，再用 md5；失败要重推，不是只看 md5。
- **同一时刻只允许一个 adb 操作者** —— 包括"我自己顺手直查一下"。并发会互相 kill-server。

## 四、判据

- **不要用 `reboot()` 当"真"分支**：它走 `device_shutdown()` → `mmc_shutdown()` →
  `FLUSH_CACHE`，在这颗控制器上会挂死（取决于 eMMC 卡状态，所以时好时坏）。
  用 **panic**：`echo 10 > /proc/sys/kernel/panic` + `echo c > /proc/sysrq-trigger`，
  走 `emergency_restart()`，不经过 `device_shutdown`。
- **不要用 `/dev/mem` 读寄存器窗口**（如 `0x1f202600`）——会挂总线。
  `/dev/mem` 只能用于已知是内存的地址。
- **结论等脚本判定**，不要中途看功率/看一次 adb 就下"挂了"的结论。

## 五、构建

- DTB 是 **`.incbin` 编进内核**的（`CONFIG_MSTAR_M7642_BUILTIN_DTB=y`，走
  `arch/arm64/kernel/m7642-dtb.o`）。改 DTS 后**必须删 `m7642-dtb.o`**，
  并且**先 `make dtbs`，再 `make vmlinux Image`**（同一条 make 里会抢跑）。
- `mk-multi.sh` 必须显式给 `PANIC_DUMP_VA`（否则报错）。

## 六、机器与工具

- 功率读数会失效（读到 `0 W` 但设备在跑）→ 不能当唯一判据。
- `pgrep -f`/`pkill -f` **会匹配到执行它的那条命令行**，把自己杀掉。
  用括号正则（`runon[e][.]sh`）并排除 `$$`。
- 宿主机休眠/关机打断一切后台作业，恢复后**残留脚本会继续抢设备**，先按 pid 清干净。
- adb 走 **WiFi**：Android 的 WiFi 没关联时 adb 和 ping **同时全灭**，不代表设备死了。

## 七、当前已知未解问题（别反复重推）

1. **我们的内核写 eMMC 不落盘**（`O_DIRECT` 同启动内读回一致，跨重启丢失）；
   Android 写同一 LBA 能保留。唯一坏的环节是 `FLUSH_CACHE` 的完成判定，未修好。
2. **`ramoops` 内核侧三层已验证通过**（probe 成功、console 收数据、写入落地），
   但 Android 不导出（`/sys/fs/pstore` 始终为空）。
3. **WiFi 缺 MStar EHCI 的 PHY 上电序列**；DT 与 `split-registers` 已就绪，
   `drivers/phy/mstar/` 的移植在调试中（PHY 序列一跑就挂，原因未定）。
