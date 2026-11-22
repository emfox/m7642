# dumps/ — FCIE 相关函数的机器码快照（2026-11-22）

全部用设备上 `/data/local/tmp/wdtdump.ko` 的 `sym=` 参数转储，运行时地址来自模块自己打印的
`wdtdump: <sym> at 0x...` 行（内核 4.9.118+，Android 9，无 KASLR 迹象）：

| 文件 | 符号 | 运行时地址（VA） | 长度 |
|---|---|---|---|
| `eMMC_PlatformInit.bin` | `eMMC_PlatformInit` | `0xffffff8008ca6264` | 1024 |
| `eMMC_Init_Device.bin` | `eMMC_Init_Device` | `0xffffff8008c925ec` | 1024 |
| `eMMC_Init_Ex.bin` | `eMMC_Init_Ex` | `0xffffff8008c92610` | 1024 |
| `eMMC_Init.bin` | `eMMC_Init` | `0xffffff8008c92710` | 512 |
| `eMMC_FCIE_Init.bin` | `eMMC_FCIE_Init` | `0xffffff8008c97720` | 1024 |
| `eMMC_FCIE_Reset.bin` | `eMMC_FCIE_Reset` | `0xffffff8008c957fc` | 1024 |
| `eMMC_CMD17_MIU.bin` | `eMMC_CMD17_MIU` | `0xffffff8008c993fc` | 2048 |
| `eMMC_FCIE_SendCmd.bin` | `eMMC_FCIE_SendCmd` | `0xffffff8008c95c00` | 1024 |
| `eMMC_FCIE_ClearEvents.bin` | `eMMC_FCIE_ClearEvents` | `0xffffff8008c95950` | 256 |
| `eMMC_FCIE_PollingEvents.bin` | `eMMC_FCIE_PollingEvents` | `0xffffff8008c95080` | 512 |
| `eMMC_CheckR1Error.bin` | `eMMC_CheckR1Error` | `0xffffff8008c964d8` | 512 |
| `eMMC_GetR1.bin` | `eMMC_GetR1` | `0xffffff8008c96498` | 512 |
| `eMMC_DMA_MAP_address.bin` | `eMMC_DMA_MAP_address` | `0xffffff8008ca22e0` | 256 |
| `eMMC_translate_DMA_address_Ex.bin` | `eMMC_translate_DMA_address_Ex` | `0xffffff8008ca2254` | 512 |
| `eMMC_FCIE_ErrHandler_RestoreClk.bin` | `eMMC_FCIE_ErrHandler_RestoreClk` | `0xffffff8008c95740` | 1024 |
| `glob_9358000.bin` | 数据：`0xffffff8009358000` 起 128 B | — | 128 |

**规则：raw binary 上 `--start-address` 无效**（见 discipline.md）。复算方式：

```sh
~/Debian/m7642-build/toolchain/gcc13/bin/aarch64-buildroot-linux-gnu-objdump \
    -D -b binary -m aarch64 --adjust-vma=<上表地址> <文件>
```

`eMMC_FCIE_Reset.bin` / `eMMC_FCIE_Init.bin` 用来核对「复位不碰时钟域」与 `RST` 的位定义；
`glob_9358000.bin` 是 `mstar_pm_base` 那一页的原始字节（`0xffffff800000000a` 那个读数就是
从这里来的，见 confirmed-facts §32.1）。

注意：`wdtdump` 的 `len` 是「最多」——`kernel_write` 实际写入的字节数没有校验。
本轮所有 dump 的长度都与 dmesg 的 `wrote N bytes` 一致，但**下次用之前仍应核一遍**
（比对函数边界或末尾 `ret`）。
