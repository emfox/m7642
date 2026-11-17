#!/bin/bash
# one-shot: retire the single-file bring-up DTS, commit the split board/SoC files
set -e
cd /home/emfox/Debian/m7642

git rm -q arch/arm64/boot/dts/mstar/m7642-minimal.dts
sed -i 's|`dts/m7642-minimal.dts`（gic/memory/cpus/timer/simplefb 均已填真实值）|`arch/arm64/boot/dts/mstar/m7642.dtsi` + `m7642-tcl-65s535d.dts`|' Documentation/mstar/m7642/hardware.md
sed -i 's|`dts/m7642-minimal.dts` + 主线 arm64|`arch/arm64/boot/dts/mstar/` 下的 dtsi + 板级 dts + 主线 arm64|' Documentation/mstar/m7642/roadmap.md

git add -A
git commit -q -s -m "mstar: add m7642 SoC and TCL 65S535D device trees"
echo "=== log ==="
git log --oneline | head -3
git status --short
