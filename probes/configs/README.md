# 构建基线（可复现）

这些文件是 2026-11-25 之后的工作基线。内核源码在
`~/Debian/m7642-build/kernel/linux-git`（分支 `m7642-7.3.5`），构建树
`~/Debian/m7642-build/kernel/linux-735-clean`（干净 out-of-tree）。

- `m7642-735-clean.config`：完整 `.config`（副本，用于重建构建树）
- `m7642-735-clean.md5`：`.config` / `System.map` / 裸 `Image` 的 md5

## 重建步骤

```sh
O=~/Debian/m7642-build/kernel/linux-735-clean
rm -rf $O && mkdir -p $O
cp ~/Debian/m7642/probes/configs/m7642-735-clean.config $O/.config
make -C ~/Debian/m7642-build/kernel/linux-git O=$O ARCH=arm64 \
     CROSS_COMPILE=aarch64-buildroot-linux-gnu- olddefconfig dtbs Image
```

关键配置项（相对 `linux-735-out` 基线的增量）：

```
CONFIG_INITRAMFS_SOURCE="/tmp/initramfs"
CONFIG_INITRAMFS_COMPRESSION_GZIP=y
CONFIG_DEVMEM=y
# CONFIG_STRICT_DEVMEM is not set
CONFIG_DEVTMPFS=y
CONFIG_DEVTMPFS_MOUNT=y
CONFIG_MAGIC_SYSRQ=y
CONFIG_PANIC_TIMEOUT=5
CONFIG_FB_SIMPLE=y
# CONFIG_DRM_SIMPLEDRM is not set
CONFIG_FRAMEBUFFER_CONSOLE=y
```

## 铁律

`make Image` 之后**不要**用 `mkbootimg.py` 包容器：`tools/host/mk-mainline-abort.py`
的 `--image` 参数要的是**裸 Image**，容器头由它从 `--src` 模板生成。
`probes/handoff/mkimage.sh` 会断言这一步（`Image[:2] == "MZ"`）。
