#!/bin/bash
# Snapshot the m7642 USB register map (4x EHCI caps + 4x UTMI head).
#   tools/usb-map.sh [label]
# Offsets come from disassembling ehci_hcd_mstar_drv_probe on the live kernel
# (see usb-inventory.md), not from the m7322 HAL header -- m7642 differs.
set -u

ADB=${ADB:-/home/emfox/Debian/tv/adb/platform-tools/adb}
TV_HOST=${TV_HOST:-192.168.10.60:5555}
HERE=$(cd "$(dirname "$0")" && pwd)
LABEL=${1:-$(date +%Y%m%d-%H%M%S)}
DIR="$HERE/../snapshots"
mkdir -p "$DIR"

$ADB connect "$TV_HOST" >/dev/null 2>&1
for f in probeG/probeG.ko rung.sh usbmap3.sh; do
	src="$HERE/../probes/$f"
	[ -f "$src" ] || { echo "missing $src"; exit 1; }
	$ADB -s "$TV_HOST" push "$src" "/data/local/tmp/$(basename "$f")" >/dev/null 2>&1
done

$ADB -s "$TV_HOST" shell \
	'echo "sh /data/local/tmp/usbmap3.sh" > /data/local/tmp/tvroot.cmd' >/dev/null 2>&1

# 8 insmod/rmmod cycles, ~4 s each.
sleep 45

$ADB -s "$TV_HOST" pull /data/local/tmp/usbmap.txt "$DIR/usb-$LABEL.txt" 2>&1 | tail -1
echo "saved: $DIR/usb-$LABEL.txt"
