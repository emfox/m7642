import os
D=os.path.expanduser("~/Debian/m7642/Documentation/mstar/m7642")
p=os.path.join(D,"confirmed-facts.md"); s=open(p).read()
if "34.20" not in s:
    s=s.rstrip("\n")+"""

### 34.20 ★★★★★ 连挂三发的真凶：检查点补丁打在了**错误的入口偏移**上（2026-11-22 23:3x）

#### 现象

`n1`（v3）与 `p1`（v4）都在 `0x463978` 挂死、记录为空——而这个偏移上**旧的 `f1` 是能回来的**。
QEMU 测试台对 v2/v3/v4 两个世界全 PASS，**与真机矛盾**。

#### 真因

v2 重写把 `_start` 变成了两条指令：

```
0x00  mov x5, xzr        <- _start
0x04  b   0x110          <- _start 第二条
0x08  ...                <- _start_kva 被推到这里（原先是 0x04）
```

而 `mk-zfix.sh` 里 `kva) TGT=0x36c004` 是**写死的**。于是从 v2 起，每一发
检查点的 `bl` 都落在 `Image+0x36c004`＝`_start` 的第二条指令，**直接 `b 0x110` 进公共路径，
绕过整个 AT 探测、也没有初始化 x5**。带着内核现场的 `x5`（非零）：

| 版本 | 走到的分支 | 死法 |
|---|---|---|
| v2 / v3 | `x5≠0` → VA 分支 | 用垃圾 `x5` 当偏移写表 → 取数中止 |
| v4 | 绕过探测 → `cbz x5` 不成立 | 又去建表 → 中止 |

#### 为什么测试台没抓到（**夹具盲区**）

QEMU bench 是**按符号**跳到 `_start_kva` 的（日志里写 `entering tramp _start_kva at VA=…`），
**从不经过 `bl Image+0x36c004` 这条真实的补丁路径**。所以"入口偏移漂移"这类 bug
在夹具里天然不可见。

#### 结构性修复（不再依赖人记）

1. `tramp-postmmu.S` 里用 `.org 0x10` **钉死** `_start_kva`；
2. `build-postmmu.sh` 用 `nm` **断言** `_start==0x0`、`_start_kva==0x10`、`_start_fdt==0xc0`，
   不符即退出；并把结果写进 `tramp-entries.env`（`TRAMP_PA_ENTRY/TRAMP_KVA_ENTRY/TRAMP_FDT_ENTRY`）；
3. `mk-zfix.sh`、`mk-aligned.sh` **读这份文件**，不再写死 `0x36c004/0x36c000`；
4. 镜像构建后离线核对：`patch@0x463978 -> 0x36c010` ✓、`code1 -> 0x36c0c0` ✓。

#### 教训（已进 discipline）

**"按符号调用"的测试台，必须再加一条"按补丁入口调用"的场景**，否则它证明不了真实镜像的行为。
凡是"偏移量"这种手工同步的东西，都要变成"由构建生成 + 断言"。

镜像：`q1` = `042bb24c…`（`0x463978`）、`q2` = `b8ca5721…`（`0x4639c0`），tramp blob `3f2a9fcf…`。
"""
    open(p,"w").write(s); print("§34.20 已加")

p=os.path.join(D,"discipline.md"); s=open(p).read()
if "按符号调用" not in s:
    s=s.rstrip("\n")+"""

### 测试台要按"真实调用路径"验，不能只按符号验

2026-11-22：QEMU 夹具一直用 `bl _start_kva`（按符号）进入 tramp，而真实镜像是
`bl Image+0x36c004`（按**硬编码偏移**）。一次重写让 `_start_kva` 从偏移 4 漂到 8，
夹具照样全 PASS，真机连挂三发。**偏移量必须由构建生成并断言，夹具必须复现补丁路径本身。**
"""
    open(p,"w").write(s); print("discipline 已加")
