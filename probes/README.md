# probes/

设备端内核探针模块。**所有在线取证都靠它**——这台机器的内核与厂商源码差 8 字节的
`struct module`，`module_init` 从不执行，所以探针的逻辑必须放在 `module_exit`，由 `rmmod` 触发。

## 内容

| 文件 | 用途 |
|---|---|
| `probeG/` | **参数化探针**（主力）：`sym=` dump 代码、`addr=` dump 内存、`csym=` 调函数 |
| `probeS/` | GOP 全量快照（扫 idx × bank × offset） |
| `probeRW/` | 读物理内存（`op=r addr= len=`），code1 记录的标准读出工具 |
| `wdtdump/` | 按符号 dump 代码（`sym=`），取证反汇编用 |
| `fcie/` | eMMC/FCIE：18 步 CMD17 读通道 + 各级诊断镜像 |
| `handoff/` | post-MMU 检查点仪器（tramp + handover + 运行脚本） |
| `ladder/` | pre-MMU 梯级 stub（`-DCOLOUR= -DSTEP= -DHALT=`） |
| `feat/`、`pmbase/`、`rstcall/`、`panicmod/`、`hangmod/`、`mark600/`、`pstub/`、`tramp/`、`pmsg/` | 专题小工具 |
| `expect.tsv` | 设备内核的符号 CRC 表，用来合成 `Module.symvers`，保证 vermagic/CRC 对齐 |
| `device-config.gz` | 设备 `/proc/config.gz`，模块必须按它编 |

早期一次性探针（`probeD/`、`probe1..8.c`、颜色期与入口期的 `paint*/`、
`entry2/`、`entry-race/`、`factory-hook/` 等）已移到仓库外
`~/Debian/m7642-attic/probes/`；本目录只留仍在使用的源码。

构建产物（`.bin`/`.elf`/`.ko`/`.o`）一律不入库，用各目录的 `build*.sh` 现生成。

## 用法

```sh
# 加载（必须用 busybox 的 insmod，toybox 的会内核态自旋）
/vendor/bin/busybox insmod /data/local/tmp/probeG.ko sym=MHal_GFLIP_ReadGopReg len=256
/system/bin/rmmod probeG          # 触发 module_exit，干活

# 结果在 /data/local/tmp/probeG.out（root 0600，取回前 chmod 644）
```

设备上没有直接 root shell，走 init 的 `tvroot` 服务：

```sh
echo "sh /data/local/tmp/rung.sh \"addr=0xffffff800a022600 len=64\"" > /data/local/tmp/tvroot.cmd
sleep 12 && adb shell cat /data/local/tmp/tvroot.out
```

## 安全

- **只读已确认的小窗口**，禁止盲扫（详见 `Documentation/mstar/m7642/index.md`）。
- 大 dump 不要走 `tools/device/rung.sh`（结尾有 `cat | head -80`，会截断），直接 pull `probeG.out`。
