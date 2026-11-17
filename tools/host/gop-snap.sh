#!/bin/bash
# Capture a GOP register snapshot from the TV.
#   tools/gop-snap.sh [label] [extra insmod params...]
# Snapshots land in kernel-lab/snapshots/<label>.txt
set -u

ADB=${ADB:-/home/emfox/Debian/tv/adb/platform-tools/adb}
TV_HOST=${TV_HOST:-192.168.10.60:5555}
HERE=$(cd "$(dirname "$0")" && pwd)
LABEL=${1:-$(date +%Y%m%d-%H%M%S)}
[ $# -gt 0 ] && shift || true
DIR="$HERE/../snapshots"
mkdir -p "$DIR"

$ADB connect "$TV_HOST" >/dev/null 2>&1
$ADB -s "$TV_HOST" push "$HERE/../probes/probeS/probeS.ko" /data/local/tmp/probeS.ko >/dev/null 2>&1
$ADB -s "$TV_HOST" push "$HERE/../probes/snap.sh" /data/local/tmp/snap.sh >/dev/null 2>&1
$ADB -s "$TV_HOST" shell "echo 'sh /data/local/tmp/snap.sh /data/local/tmp/gop.snap $*' > /data/local/tmp/tvroot.cmd" >/dev/null 2>&1
sleep 14
$ADB -s "$TV_HOST" pull /data/local/tmp/gop.snap "$DIR/$LABEL.txt" 2>&1 | tail -1
echo "saved: $DIR/$LABEL.txt"
