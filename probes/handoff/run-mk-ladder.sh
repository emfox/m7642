#!/bin/bash
# Run the __pi_early_map_kernel in-function checkpoints in order.
# Stops at the first "no return" (that checkpoint is the hang site).
set -u
D=$(cd "$(dirname "$0")" && pwd)
B=$HOME/Debian/m7642-build/out
ADB=/home/emfox/Debian/tv/adb/platform-tools/adb
mark(){
	$ADB connect 192.168.10.60:5555 >/dev/null 2>&1; sleep 1
	$ADB -s 192.168.10.60:5555 exec-out su -c \
		"dd if=/data/local/tmp/mark.bin of=/dev/block/by-name/misc bs=512 seek=16376 count=8 2>/dev/null; sync; dd if=/dev/block/by-name/misc bs=512 skip=16376 count=1 2>/dev/null | od -An -tx1 | head -1" | tr -d '\r'
}
for spec in \
	"mk1 371627c1fd729baa16723a3912bcbe1a" \
	"mk2 50a5f07f5f37e0aa5f3320c880fcaa70" \
	"mk3 3b7dac457072a6c815f9c82a3d08c0f2" \
	"mk4 83cb6f291c5cf838be34301d6c4bc910" \
	"mk5 5d567f3a45998c9af33aff9a1bc8fb6e" \
	"mk6 893a2274b321cab41137b4b57008cc13"; do
	set -- $spec
	echo "### $1 (misc marker: $(mark))"
	"$D/run-postmmu.sh" "$B/m7642-rec-73-$1.img" "$2" "$1"
	r=$?
	echo "### $1 rc=$r"
	[ $r -eq 0 ] || { echo "### STOP at $1"; exit $r; }
done
echo "### ladder complete"
