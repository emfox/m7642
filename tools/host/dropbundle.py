import os, re

R = os.path.expanduser("~/Debian/m7642")

# 1) 仓库里删 bundle
p = os.path.join(R, "patches/kernel-m7642-7.3.5.bundle")
if os.path.exists(p):
    os.remove(p); print("deleted:", p)
p = os.path.join(R, "patches/kernel-m7642.bundle")
if os.path.exists(p):
    os.remove(p); print("deleted:", p)

# 2) patches/README.md：去掉 bundle 小节，改成惯例说明
p = os.path.join(R, "patches/README.md")
s = open(p).read()
s = re.sub(r"\n## 完整恢复（含 8 个提交的历史）.*?(?=\n## )", "\n", s, flags=re.S)
s = re.sub(r"\n## patch 与 bundle 的分工.*$", "", s, flags=re.S)
s = s.replace("""## 为什么不把整棵内核树推到 GitHub

内核树 `.git` 约 **297 MB**，其中 99.9% 与上游重复；而 `series/` + bundle 合计约 **670 KB**，
可读、可 review、可重放。需要"能浏览的整树 + 分支"时，另建 `torvalds/linux` 的 **fork**
（GitHub 侧共享对象，零存储成本），只上传我们新增的几十个 blob。""",
"""## 为什么不把整棵内核树推到 GitHub

内核树 `.git` 约 **297 MB**，其中 99.9% 与上游重复；`series/` 只有约 560 KB，
可读、可 review、可重放。

**按内核惯例，这里只存补丁系列**：补丁进仓库（或邮件列表）就是归档形态；想要"远端持久化的
git 分支"，惯例是推一个公开的树（如 `torvalds/linux` 的 fork，GitHub 侧共享对象、零存储成本，
只需上传我们新增的 blob），而不是在仓库里塞 git bundle——bundle 是气隙传输用的，不是归档格式。""")
open(p, "w").write(s); print("patches/README.md 已改为惯例说明")

# 3) README-git.md：删掉 bundle 对比表，留下"分支才是真相"
p = os.path.expanduser("~/Debian/m7642-build/kernel/README-git.md")
s = open(p).read()
s = re.sub(r"\n## patches 与 bundle 的分工.*$", "\n", s, flags=re.S)
s = s.rstrip("\n") + """

## 归档形态（按内核惯例）

- **补丁系列** `~/Debian/m7642/patches/series/`（`git format-patch` 产物，9 个）：进仓库、可 review、
  可 `git am` 重放（实测恢复后树对象与分支一致）。
- **git 分支**：本地 `linux-git` 的 `m7642-7.3.5` 是真相；需要远端就推公开树
  （`torvalds/linux` 的 fork，共享对象、零存储成本），不要在仓库里塞 bundle。
- bundle 只在气隙传输时用，不作为归档。
"""
open(p, "w").write(s); print("README-git.md 已改")
