# 纪律：代价换来的规矩

> **本文件是必读。** 只写"违反过就会付代价"的条目，每条都注明为什么。
> 事实与结论在 [confirmed-facts.md](confirmed-facts.md)，路径在 [paths.md](paths.md)。
> 跨项目的通用约定（打包、邮件、Git 时间戳等）在 `~/.workbuddy/MEMORY.md`，这里不重复。

## 0 三条总则

1. **只改被要求的那几行。** 不顺手加注释、不顺手"加固"。「技术上行得通」≠「应该做」。
2. **结论必须分三档**：实测 / 有对照的推论 / 推测。拿不到证据的写"待确认"，不写推测当结论。
3. **一次试验 = 一次赌注。** 见 §2。

---

## 1 判读纪律：什么才算读数

**只有整屏纯色算数。**

- 不许叠加图案，不许拿颜色序列当读数。**看最后停在那一屏。**
- 判据是"整屏纯色"，条纹 / 花屏 / 渐变一律不算。
- **土黄不能判 rung**：`0xCCCC` 是我们自己 stub 的填充色，内核一被跳转执行第一眼必然土黄。
  且 `0xcccc` 与 `0xCCCCCCCC` 在 RGB565 下同色，无法区分。
- **洋红来源不明**：曾经以为 mboot 进 recovery 会画洋红底 `boot_recovery.jpg`，但 2026-11-20
  实测 `find / -xdev -iname "*boot_recovery*"` 零命中、`/tclconfig` 下只有 5 个品牌 `boot0.jpg`
  ⟹ 该图**不存在**，那句 `run_command("bootlogo … boot_recovery.jpg")` 必然失败。
  所以停在洋红**既不能判"内核没跑"，也不能判"跑到第几级"**。见 `boot-test.md` §三 更正块。
- `0x4210` 是**暗紫蓝 RGB(66,65,132)**，不是中性灰。真灰是 `0x4208` / `0x8410`。
- 哨兵色必须避开 `0xCCCC` / 白 / 红 / 绿 / 黄 / `0x4210` / `0x8410`。

**为什么定这么死**：`ladder4/6/8` 的 rung 与 beacon 四版**逐字节相同**，结果却一次纯绿、三次花屏。
代码相同而结果不同 ⟹ 拿颜色序列当读数等于自欺。

**反汇编核对镜像，不要信"当前源码"。**

- `head.S` 源码里的检查点顺序与 `.img` 里的实际排布**不一致**。
- raw binary 上 `--start-address` 无效：必须先按偏移切段，再
  `objdump -D -b binary -m aarch64 --adjust-vma=<vma>`。
- `code1` 在 Image **偏移 4**，算跳转目标时 **PC = base + 4**。按 `base+0` 算会差 4 字节，
  会误判成"镜像坏了"。

**向人询问观测结果时，选项必须互斥、完整。**

- **必须单列"全黑 / 全白 / 无信号"**。漏掉这个基本情况，对方只能挑一个近似项，
  记录下来的却是另一件事。
- **不能把两种状态塞进同一个选项**。犯过：`"纯色洋红 + 条纹，无图案"` 自相矛盾，
  对方选了，我按"纯色"推出一整套判读（2026-11-20）。
- **不能把"没变化"和"没看清"合并**。又犯过：实际是"一片黑"，被记成"涂色无效"，
  进而推出"fb0 不是扫描源"这个错误结论（2026-11-20）。
- 观测项超过三个时，**逐项单独问**，不要一次给一屏选项。

**为什么定这么死**：这两次都不是看错屏幕，而是**问错问题**。选项设计本身就成为污染源，
下游所有推论都建在错误记录上，且很难自查——因为"记录"看起来是对方亲口确认的。

**先划清判据的盲区，再拿它推结论。**

- 这台机器 **adb 走 WiFi** ⟹ 「adb 有反应」只等于「Android 完整起来了」。探针挂住 /
  内核只跑到 recovery / 落回待机，在 remote 侧**完全同形**。
- ⟹ 凡是要区分「没起来」的原因，必须另有**不依赖 Android** 的读数（人眼看屏、或下一次启动读）。
- 代价：2026-11-21 用「有没有 adb / 多久回来」连推三轮，得出「探针没返回」「镜像没被执行」
  两个错误结论，最后靠零改动镜像对照才推翻。

**跨轮对比之前，先列出「除目标变量外还有哪些不同」。列不出来就写"不可比"。**

本项目的易变项（每一轮实验都可能不同，必须逐项核对）：

| 项 | 举例 |
|---|---|
| ladder blob | 窗口 disable、cache clean、色值、`HALT` 开关、blob 长度 |
| env | `recoverycmd` 是否带 `mmc erase.p misc`、`MstarUpgrade_complete`、`WDT_ENABLE` |
| 刷入位置 | recovery 槽 / boot 槽、BCB、misc 是否被擦过 |
| 镜像内容 | 哪个内核、哪版 head.S |
| 判读手段 | 颜色 / 点密度 / 文字 |

- 犯过（2026-11-20）：拿 4.19 的表现去解释"为什么和 7.3 不同"，而两次之间至少四个变量不同
  ——ladder 版本、`recoverycmd` 是否擦 misc、色值、`HALT`；且两次"表现"都不是实测，
  都来自覆盖率只有 0.01% 的颜色通道。
- **"以前是 X，现在是 Y ⟹ 说明 Z" 这个句式，必须先证明 X 和 Y 是在相同条件下测得的。**
  做不到就写"**不可比**"，绝不要写"不同"。

---

## 2 赌注纪律：刷机之前先算成本

**`boot` 和 `recovery` 都是单向车道。**

- 刷坏 `boot`：logo → 几十秒 → 待机，**按电源键只是重播同一段**，adb 永远不回来。
  唯一出路是 U 盘救砖（mboot 无失败回退）。
- **`recovery` 槽不是"零成本场地"**：mboot 对 `boot-recovery` 是**非消费式**的，写进 `misc` 之后
  每次开机都进 recovery。已经踩过一次锁死。
- ⟹ **跑非厂值内核挂了就没 adb；「挂了就 `adb reboot`」是自相矛盾的，不许再写这句话。**
- ⟹ **不要反复"按一下看看"。** 「回待机」= PM51 直接切电 = **硬断电**，`/data` 会损坏，
  坏了之后更难救，形成自我强化。
- ⟹ **不要用 `sysrq` 制造软复位。** `echo b > /proc/sysrq-trigger` 走 `machine_restart`，
  不 umount、不等写缓存落盘，对 `/data` 与「回待机」同等有害（2026-11-20 实测：一次就把设备
  送回「logo → 3 秒 → 回待机」）。`panic=0` 又堵死了 `echo c`：它只挂死、不重启。
  要软复位只有两条路——让被测内核自己崩（WDT），或接受 `adb reboot` 的硬断电。
  - **2026-11-21 10:18 又犯了一次（血账）**：为了验 pstore/pmsg 通道，跑了
    `sync; echo c > /proc/sysrq-trigger`。结果 `getprop ro.boot.bootreason` = **`kernel_panic,sysrq`**
    ⟹ 实际路径是 panic → `panic=0` 不重启 → 挂住 → **`wdt_enable 10` 把设备硬复位**，
    等于又给 `/data` 补了一次非正常断电。这次侥幸没坏（`/sys/fs/ext4/mmcblk0p26/` 的
    `errors_count=0`、`first/last_error_time=0`，`/data` ext4 正常挂载 6%），但**结论不变：
    不许再用 sysrq**。
  - 顺带纠正一条事实：`/proc/sys/kernel/sysrq` 实测是 **0**，可 `echo c > /proc/sysrq-trigger`
    照样生效 —— 往 `/proc/sysrq-trigger` 写是独立入口，不受 `sysrq` 开关约束。
    「sysrq=0 所以 echo c 没用」这个旧结论是错的。

**换场地 / 换方案之前，先用零改动的东西把「场地」本身判掉。**

- 2026-11-21：在 recovery 槽连赌四轮，最后靠**厂值镜像原样**（`6272b10d…`）放进去 90 s
  起不来 Android，才判定是场地不行、不是探针不行。这一步本该第一个做。
- ⟹ 顺序固定：**场地能不能出读数 → 工具能不能出读数 → 才开始赌自研代码**。

**断言 env 要按字段，不能按整块 md5。**

`MstarUpgrade_complete` 是一次性标志（mboot 读到 `1` 就消费掉、写回 `0`）⟹ 整块 env 的 md5
每次上电都会变。2026-11-21 用整块 md5 做写前断言，白烧一轮。

**刷机前必须核对的三件事**

1. `/system/etc/install-recovery.sh` 是 `.disabled`（否则每次 Android 启动都会用
   `/system/etc/recovery.img` 把槽整段覆盖）。
2. `/data/local/tmp/rec.head.bin` 的 md5 是厂值（见 confirmed-facts §D）。若不是 ⟹ 厂值回滚已失效。
3. `misc` 的 BCB 不是 `boot-recovery`。

**任何「到达」必须由 stash 证明，不能只看「设备回来了」。** 2026-11-21 20:1x：
多数 rung 判定只等了 `sys.boot_completed=1` 就宣布"到了"。但若 `adb reboot recovery` 没生效、
mboot 走了 `bootcmd` 直接进 Android，设备同样会"回来"，于是给出**假阳性**——这能一次解释
`0x465E80` 一会儿"过"一会儿"不过"的全部矛盾。
规则：`到达` 必须验证 stash 的 `magic == "M764"` **且** `x30 == image_base + off + 4`；
不满足就记 `INCONCLUSIVE`，不参与二分。

**「没回来」这种判定，先确认不是等太短。** 2026-11-21 19:0x：判定脚本只等 120 s，
非正常掉电后 Android 修 `/data` 会让启动变慢 ⟹ 慢启动被误判成「检查点没到」，导致同一镜像
一会儿"过"一会儿"不过"。规则：等待 ≥ 300 s、记录到达时的 uptime、关键结论重复 2 次。

**探针里任何「长时间」常量，先算一遍量级再上机。**

- 2026-11-21 15:2x：`paint-hold.S` 想空转约 10 s，写成 `movk x9, #0x2, lsl #48`（应为 `lsl #32`），
  实际 1.4×10^14 次迭代 ⟹ 等于死循环 ⟹ **把 bootstrap 槽刷坏**，每次开机卡 30–40 s 回待机，
  最后靠 U 盘救砖。
- ⟹ 含长空转/长循环的镜像**禁止进 boot 槽**；先在 recovery 槽或纯计算里核对迭代数。

**按电源键之前先确认设备不在 Android 运行态。**

- Android 运行中按电源 = 待机 = PM51 切电 = 硬断电（`/data` 风险）。工具 `tools/host/tvpower.sh` 默认拒绝，需 `--force` 才按。
- 只能用于「待机/挂死 → 开机」这个方向；救砖（按住机身键 + 插电）IR 做不了。

**「设备自己回来了」不能当「狗咬了」的证据。**

- 必须另有一个**不依赖时间**的判据证明这一轮确实进过 recovery：`misc` 第 2 页标记是否被
  `mmc erase.p misc` 擦掉。
- 代价：2026-11-21 把几次「26 s 自己回 Android」当成 `wdt_enable` 生效，据此写下「10 s 狗是
  有效兜底」，后来用标记法才知道那几次**根本没进 recovery**（BCB 没写进去，走了 `bootcmd`），
  而真进了 recovery 的两次都是**挂住不恢复**。

**`boottest.sh arm` 只许执行一次。**

它每次都**无条件**备份"当前槽内容"。arm 两次就会把我们自己的镜像当成厂值备份，
`rec.head.bin` 永久失效，厂值回不来了。

**`precheck` 通过 ≠ 可以 arm —— 它检查的是备份文件，不是槽内容。**

2026-11-20 实际踩过：`precheck` 报 `rec.head.bin md5 = 0f6e1705`（厂值）✓，
同时槽头 `kernel_size = 0x00d3fd60` —— 那是 **rung0 的**（厂值是 `0x012d4a00`）。
两个字段互相矛盾，而我只看了前者，于是第二次 `arm`，把 rung0 备份成了"厂值"。

⟹ **arm 前必须直接对比「槽内容 md5」与「厂值 md5 `0f6e1705…`」**，
不能只看 `rec.head.bin`。槽里有我们自己的镜像时，先决定要不要先恢复厂值再 arm。

⟹ 附带事实：**`rescue-fast.bin` 不恢复 recovery 分区**（2026-11-20 实测：救砖后槽里仍是 rung0）。
它恢复的是 `misc` + `boot`。所以"救过砖"不代表槽是干净的。

⚠️ **上一条要按 md5 区分，别按文件名。** 47,263,776 B 这个尺寸有两个包：

| md5 | 脚本里有 recovery 段 | 用处 |
|---|---|---|
| `7e8ef7a7…`（`fix/rescue-fast.bin`） | **有**（`filepartload 0xA000 0x1A33000` + `erase.p` + `write.p`） | 真能重写 recovery 槽 |
| `326132c7…`（`fix/rescue-norecovery.bin`） | **无**，只有注释行 | 只写 misc/dtb/boot，修不了坏槽 |

2026-11-20 救砖失败的直接原因就是 U 盘根目录放的是后者（名字同样叫 `V8-…bin`）。

**U 盘纪律**

- 根目录**只能有一个 `.bin`**，且文件名必须是 **`V8-T652T03-LF1V147.bin`**。mboot 找包是
  prefix + postfix 拼接（`filenamefind %s .bin`），TCL 配的前缀是 `V8-`；**只放
  `MstarUpgrade.bin` 时它根本不会去读**（2026-11-17 第四次实测，同名双份也成功过）。
- 强制升级要从**关机状态**开始：拔电 → **按住机身实体电源键** → 插电 → 按住 10–15 秒直到
  出现进度条才松手。**不是**"插电进待机再按一下"。
- 救砖包 `rescue-fast.bin` **自己不设** `MstarUpgrade_complete` key ⟹ 每次救砖后要手工重置成 1，
  否则下次插 U 盘会被强制升级。

---

## 3 观测纪律：不要拿寄存器去试错

**禁止 MMIO 盲扫。** 厂商块里有未实现的空洞，读到就 external abort，arm64 直接 panic。
代价：曾在 `0xFD200000+0..0x40000` 按 `0x100` 步长扫 USB 块，电视当场重启。

**碰新块先用对齐的字宽读**（`readl`），不要逐字节 hexdump。
代价：按字节读 HDMI RX 块（`pm+0x2E7000`），电视再次重启。

**地址算术错一位不会报错**，只会读到"平静的一整片 0"。凡读到全零，**先复核算术**再怀疑硬件。
（`pm+0x22600` 是 `0xffffff800a022600`，不是 `…0a226000`。）

**读之前记 uptime**；崩了第一时间抓 `/sys/fs/pstore/console-ramoops`。
Android 的 init 会在启动时清 pstore，晚几分钟就只剩新启动的日志。

**内核符号地址只能用 `kallsyms_lookup_name` 在模块内取。** `/proc/kallsyms` 全是 0，
`kptr_restrict=2` 对 root 也生效。

**`insmod` 用 `/vendor/bin/busybox`。** toybox 的走 `finit_module(2)`，在这台机器上会自旋。

**提权走 `/data/local/tmp/tvroot.cmd`**：写命令 → 等 12–15 秒 → 读 `tvroot.out`。
调用封装是 `~/kbuild/tvrun.sh <本地脚本>`。

**`adb` 的 server 会随上一个 shell 结束而死**，`connect` 与动作要写在同一个调用里。

**dmesg 必须在 9 秒内抓。** 环缓冲里 0–8.x 秒的 `setup_arch` 段会被 `avc: denied` audit 洪水冲掉。
`loglevel=3` 只约束控制台、**不约束环缓冲**（所以"被 loglevel 挡住了"这个解释是错的）。
采集**不要**用 `adb reboot recovery`：会锁 recovery 循环，且 recovery 里 adb 多半不可用，回不来。

---

## 4 构建纪律

**7.3 只走 `~/Debian/m7642/tools/build-mstar-kernel.sh`。**

- 裸 `make -j8 Image` 不带 `ARCH` 会进**交互式** `syncconfig`，卡住。
- `make olddefconfig` 会把 `.config` 改成 **x86**。
- 停构建用 `pkill -x make`（别用 `-f`，会匹配到自己）。
- 梯级（rung）是独立汇编的 ⟹ **改梯级零内核重编**，别为了改一个颜色重编整个内核。

**4.19 树（`~/kbuild/tcl-419/`）专属**

- `make clean` 是**坏的**（`No rule to make target 'clean'`）⟹ 改用 `tcl419-clean.sh`。
- 厂家把构建产物（`.o`/`.a`/`.cmd`/`modules.order`）**提交进了 git**。只删一部分 `.o` 会让 kbuild
  以为目录归档还在，报 `ar: <dir>/built-in.a: No such file or directory`
  ⟹ **要么全删要么不删**（`*.o *.a .*.cmd .*.o.d *.mod *.mod.c *.ko modules.order modules.builtin
  .tmp_* *.symvers` 一起清）。
- **`syncconfig` 之后必须核对 `include/generated/autoconf.h`。** 曾经 `auto.conf` 是 m7642 而
  `autoconf.h` 是 m7332 ⟹ C 代码按 m7332 编、Makefile 按 m7642 走，那次"链接成功"是混编侥幸。
- **`HOSTCFLAGS=-fcommon`**：GCC ≥ 10 默认 `-fno-common`，老 dtc 的 lexer/parser 依赖
  tentative definition，否则 `multiple definition of 'yylloc'`。
- **执行位**：整棵树解包时丢了 +x（259 个 `.sh`），且 `HOSTCC` 新链出的 host 程序是 `0664`。
  编译前 `chmod +x` 所有 `.sh`/`.pl`，并对 `scripts/ tools/` 下的 ELF 补 +x。
- **sandbox 的 `rm` 包装器**在一个 turn 内删到第 50 个文件就拒绝，会杀掉 kbuild 的 `.tmp_*` 清理。
  编译时用 `env -i PATH=<toolchain>:/usr/bin:/bin`——**PATH 里不能有 `safe-bin`**。

**动手之前先查有没有残留后台任务在改这棵树。**
代价：上一次会话残留的 `git checkout -f HEAD` 跑了 3 h 30 m，期间补丁"静默回滚"、
`fixdep` 执行位被重置，整整三小时的失败都源于它。

**改 Image 之前先 `readelf -SW vmlinux`**，落点必须 `< _edata`，patch 脚本要硬断言。

**★ 上机前从 `autoconf.h` / `System.map` 复算，不要相信文档里的"当前配置"。**

交付代价：2026-11-20 重编的 7.3 Image 实际是 `CONFIG_MSTAR_M7642_BUILTIN_DTB=n`，
而 boot-test §二十五/二十六 的方案依赖 `=y`；mboot 又只交 `x0=0` ⟹ `setup_arch` 拿不到设备树。
此后 11-20→11-22 所有「MMU 之后挂住」的判定都建立在这个镜像上，而且「MMU 已开」还是靠一个
**否定项**（`__no_granule_support` 未到达）推出来的。

⟹ 每次上机前把这三样抄进日志：`grep MSTAR .config`、`grep MSTAR include/generated/autoconf.h`、
`grep -E " (_end|boot_args|primary_entry)" System.map`；镜像 md5 与这三样写在一起。

**★ 检查点镜像必须与"已验证档"保持同一组补丁。**

所有带 stash 验证的深检查点（`0x455048` / `0x465E4C` / `0x465E78`）都是在
`nop @0x46804C`（`preserve_boot_args` 的 `b dcache_inval_poc`）的镜像上测到的。
2026-11-22 01:0x 的 post-MMU 镜像漏了这个 nop，NO_RETURN 因此**无法归因**（可能是内核没到，
也可能是漏补丁导致的早挂）。

⟹ 新镜像的补丁清单（nop、shim、tramp、handover）写进文档，构建脚本里固定下来，别靠手打。

---

## 5 本机环境纪律

- **要动系统、写工作区外、碰块设备 / 挂载 / U 盘，第一时间 `ssh emfox@localhost` 出沙箱。**
- 沙箱 `/tmp` 是 10 MB tmpfs 且**每条命令开始时清空** ⟹ 不能当备份、放不下大文件。
- 沙箱里多行命令会被压成单行 ⟹ 用 `;` 分隔，或先写成脚本再 `bash 脚本`。
- 产物一律落 `~/Debian/<项目>/` 或 `~/kbuild/`，不在外面新开目录。
- 沙箱里 `ls -l` 显示 `root:root` 是 userns 映射假象，`chown` 报 `Invalid argument`，别去"修"。
- 网络：`github.com:443` 直连不通、`api.github.com` 通；推仓库走 SSH（`-F /dev/null` +
  `~/.ssh/id_ed25519_github`）或 `127.0.0.1:7890` 代理。**PAT 不写进 remote URL。**

---

## 6 文档纪律

- **★ 开工前先查，别凭记忆分析。** 任何"对比 / 排查 / 核对"动手前，先 `grep -l <关键词> *.md`
  扫一遍 `index.md` 的指针表。2026-11-20 就犯过：又去 grep 4.9 的 `head.S` 找 MIU 偏移和
  `NODTB`，而 `confirmed-facts.md` 第 32 行和第 194 行早就有结论（前者在确证事实里，
  后者在"已否定"表里）。**重复劳动不只是浪费——它会让人以为"刚发现的"，进而推翻已有结论。**
- **★ 查关键词要从「问题」出发，不要从「地址 / 变量」出发。** 同一天第二次栽在同一处：
  要判断"DDR 能不能跨重启保留"，却只 grep 了地址 `43300000`，没有 grep
  `跨重启` / `保留` / `ramoops` / `soft reset` —— 而结论（"只在 soft reset 下保留；
  救砖要断电，DDR 全丢"）就在那组词下面。**结论因此被搞反，还写了一整套"否证"。**
  ⟹ 查之前先自问："这个结论如果存在，它会用哪些**概念词**写？"至少用两组词各查一次。
- 每篇文档体例固定：**结论 → 证据 → 对主线的意义 → 待办**。
- 数字必须能在本机复算（给命令，不只给结果）。
- 写"已否定"的假设时要留原假设的文字 ⟹ 防止以后有人重新走一遍。
- 文档与记忆的边界：**记忆只放"决定下一步动作"的事实 + 指针，细节进文档。**
