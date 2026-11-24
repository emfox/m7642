import os

# 1) 内核构建 README：把"待退役"写死成条件
p = os.path.expanduser("~/Debian/m7642-build/kernel/README-git.md")
s = open(p).read()
s = s.replace("- [ ] `linux-main` 退役",
 "- [ ] `linux-main` 退役 —— **要等 7.3.5 的真机实测通过之后**（2026-11-23 记）。\n"
 "      在此之前 `linux-main` 是唯一被真机验证过的构建（`Image` md5 `18f7ed3c…`），\n"
 "      任何回退/对照都还要靠它")
s += """

## patches 与 bundle 的分工（2026-11-23 实测）

| | `patches/series/*.patch` | `patches/kernel-m7642-7.3.5.bundle` |
|---|---|---|
| 体积 | 560 KB | **115 KB** |
| 内容 | 每个提交的 diff + 提交信息（纯文本） | 真实的 git 对象（commits/trees/blobs） |
| 恢复方式 | `git am` 到**源码树** | `git fetch <bundle>` 到含 base commit 的**仓库** |
| 恢复后树对象 | **相同**（实测 `HEAD^{tree}` 一致） | 相同 |
| 恢复后提交 SHA | **不同**（committer/时间变了，实测） | **相同**（原始对象） |
| diff 上下文漂移 | 会受影响（`git am` 需要精确上下文） | 不受影响 |
| 二进制/模式/符号链接 | `format-patch` 默认不含二进制 | 完整保留 |
| 人工 review | **友好**（可读、可 grep、可评论） | 不友好 |

结论：**两者都要留**。patch 是"人能读、能 rebase 的表述"，bundle 是"能证明 SHA 完全一致的归档"。
在偏移依赖精确代码布局的 bring-up 项目里，后者是廉价的保险（115 KB）。
两者都必须有上游 base：patch 要 base 源码，bundle 要 base 的 commit 对象。
"""
open(p, "w").write(s)
print("README-git.md: 退役条件 + patch/bundle 分工")

# 2) 项目仓库：给未来的会话留一笔
p = os.path.expanduser("~/Debian/m7642/Documentation/mstar/m7642/paths.md")
s = open(p).read()
if "build 布局（2026-11-23 更新）" not in s:
    s = s.rstrip("\n") + """

### build 布局（2026-11-23 更新）

内核源码已 **git 化**：`~/Debian/m7642-build/kernel/linux-git`，分支 `m7642-7.3.5`
（基线 `753f54c3` Linux 7.3.5），9 个提交就是我们的全部改动。当前构建树
`~/Debian/m7642-build/kernel/linux-735-out`。详见 `~/Debian/m7642-build/kernel/README-git.md`。

**`linux-main`（旧的 7.3 构建树）暂不退役**：它是唯一被真机验证过的构建
（`Image` md5 `18f7ed3c290050be3102d8665636ea27`）。**等 7.3.5 的真机实测通过后再退役。**

镜像偏移不再手工维护：检查点写成 `<符号>+<delta>`，由 `tools/host/ckpt.py` 按 System.map 解析
（7.3 → 7.3.5 实测：函数地址整体位移，但函数内相对偏移不变）。`mk-zfix.sh` 接受名字。
"""
    open(p, "w").write(s)
    print("paths.md: 布局与退役条件已记")

# 3) patches/README：把分工也写进去
p = os.path.expanduser("~/Debian/m7642/patches/README.md")
s = open(p).read()
if "patch 与 bundle 的分工" not in s:
    s = s.rstrip("\n") + """

## patch 与 bundle 的分工（2026-11-23 实测）

- **patch 系列**：人能读、能 review、能 grep，`git am` 到同版本源码树即可重建；
  实测恢复后 **树对象完全一致**，但**提交 SHA 不同**（committer/时间变了）。
- **bundle**（115 KB）：真实的 git 对象，恢复后**提交 SHA 也一致**；不受 diff 上下文漂移影响，
  二进制/模式/符号链接完整保留。在不方便 review 的场合没用，但它是"能证明完全一致"的归档。
- 两者都需要上游 base：patch 要 base 源码，bundle 要 base 的 commit 对象。
"""
    open(p, "w").write(s)
    print("patches/README.md: 分工已记")
