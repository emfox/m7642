#!/system/bin/sh
# Flash probe-slot6.img into the recovery partition and verify it landed.
#
# This kernel now commits the GOP shadow registers (GOP_FWR) before painting,
# which is what every earlier beacon forgot.  If the kernel is really running,
# the panel must turn magenta; if it stays on the bootloader logo, the kernel
# genuinely never executes.
#
# Image is 13762560 bytes = 6720 * 2048.
set -x
dd if=/data/local/tmp/probe-slot6.img of=/dev/block/mmcblk0p7 bs=2048
sync
dd if=/dev/block/mmcblk0p7 of=/data/local/tmp/rec-verify.bin bs=2048 count=6720
chmod 644 /data/local/tmp/rec-verify.bin
md5sum /data/local/tmp/probe-slot6.img /data/local/tmp/rec-verify.bin
echo DONE
