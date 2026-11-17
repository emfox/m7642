#!/bin/sh
# Build a rescue BIN for the m7642 TV out of pristine partition images.
#
# Usage: make-rescue-bin.sh <backup-dir> [out.bin]
#
# <backup-dir> must hold boot.img recovery.img dtb.img misc.img as dumped from
# the device (see Documentation/mstar/m7642/recovery-stick.md).
#
# The result goes on a FAT32 stick as MstarUpgrade.bin in its root directory.
set -eu

BACKUP=${1:?usage: $0 <backup-dir> [out.bin]}
OUT=${2:-$PWD/m7642-rescue.bin}
HERE=$(cd "$(dirname "$0")" && pwd)
TOOL=${MSTAR_BIN_TOOL:-/home/emfox/Debian/tv/fw/mstar-bin-tool-master}

for f in boot.img recovery.img dtb.img misc.img; do
	[ -f "$BACKUP/$f" ] || { echo "missing $BACKUP/$f" >&2; exit 1; }
done

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT
cp "$HERE/m7642-rescue.ini" "$WORK/config.ini"
mkdir -p "$WORK/pack"
for f in boot.img recovery.img dtb.img misc.img; do
	cp "$BACKUP/$f" "$WORK/pack/$f"
done

cd "$WORK"
python3 "$TOOL/pack.py" config.ini
[ -f MstarUpgrade.bin ] || { echo "pack.py produced nothing" >&2; exit 1; }
cp MstarUpgrade.bin "$OUT"
ls -l "$OUT"
echo "put $OUT on a FAT32 stick as MstarUpgrade.bin"
