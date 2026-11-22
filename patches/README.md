# 内核补丁集（m7642 / Linux 7.3）

**基线**：上游稳定版 `v7.3.5`，commit `753f54c32085b30df045344d0bae91433864dd96`（`Linux 7.3.5`）。
取法：`git fetch --depth 1 stable refs/tags/v7.3.5`（stable 树在 `gregkh/linux` 或
`git.kernel.org/.../stable/linux.git`，**不在** torvalds/linux 里；直连要走本机代理 7890）。
取上游源码：`cdn.kernel.org` 的 `linux-7.3.tar.xz`，或 `git fetch --depth 1 ... refs/tags/v7.3`（见
`~/Debian/m7642-build/kernel/README-git.md`，注意 git 直连要走本机代理 7890）。

**内容**：`series/` 下 9 个补丁，38 个文件，`+15688/-1`。这是"本地改动"的唯一权威表述。

| # | 补丁 | 性质 |
|---|---|---|
| 0001 | usb: ehci 分体 32 位寄存器支持 | 通用驱动 quirk（按 compatible 生效） |
| 0002 | phy: mstar USB2 UTMI PHY | 新增驱动 |
| 0003 | arm64: mstar 平台 + TCL 65S535D 设备树 | 新增平台/DTS |
| 0004 | arm64: mstar 内建 DTB | 受 config 保护的核心文件分支 |
| 0005 | mmc: mstar-mci FCIE eMMC 主机驱动 | **新增驱动（此前未记录，2026-11-23 补上）** |
| 0006 | arm64: dts: 更新到实际在跑的版本 | 0003 之后的后续修改 |
| 0007 | arm64: head 信标插桩（config 关） | **死代码**，独立提交便于 revert |
| 0008 | arm64: pi/map_range 注释 | 无害注释 |
| 0009 | arm64: mstar 构建说明：需先 `make dtbs` | 构建顺序（2026-11-23 发现） |

## 应用

```sh
cd linux-7.3
git am --keep-cr patches/series/*.patch
```

**已验证**：按序 `git am` 到干净 `v7.3` 上，得到的树与本地 `m7642` 分支**完全一致（0 差异）**。

## 完整恢复（含 8 个提交的历史）

`kernel-m7642.bundle`（114 KB，带 prerequisite，需要一个含 `c03c1a145` 的仓库才能恢复）：

```sh
git bundle verify patches/kernel-m7642.bundle
git clone --depth 1 --branch v7.3 <upstream> tmp && cd tmp
git fetch ~/Debian/m7642/patches/kernel-m7642.bundle "refs/*:refs/remotes/bundle/*"
```

## 为什么不把整棵内核树推到 GitHub

内核树 `.git` 约 **297 MB**，其中 99.9% 与上游重复；而 `series/` + bundle 合计约 **670 KB**，
可读、可 review、可重放。需要"能浏览的整树 + 分支"时，另建 `torvalds/linux` 的 **fork**
（GitHub 侧共享对象，零存储成本），只上传我们新增的几十个 blob。

## 历史

2026-11-23 之前这里只有 4 个手工 patch，**与实际树不一致**：缺整个 eMMC 驱动、head.S 信标插桩、
DTS 后续修改，且 0004 已无法干净应用。现由内核 git 树（分支 `m7642`）用
`git format-patch v7.3-import..HEAD` 重新生成并验证。

## 升级记录

| 日期 | 基线 | 结果 |
|---|---|---|
| 2026-11-22 | `v7.3` c03c1a145 | 9 个补丁重放零差异 |
| 2026-11-23 | **`v7.3.5` 753f54c3** | **9 个补丁重放零冲突、零差异**；构建通过；函数地址整体位移（`setup_arch` +8、`__primary_switched` +0x14、符号 +21 个），**函数内相对偏移不变** |

升级后偏移由 `tools/host/ckpt.py` 按"符号+delta"重新解析，不再有任何手工写死的偏移。
