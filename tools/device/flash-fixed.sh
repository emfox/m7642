#!/system/bin/sh
# Flash probe-fixed.img into the recovery partition and verify it landed.
#
# The probe that finally lit the panel is now in primary_entry: steer GOP0's
# eight windows at 0x2d100000, commit with GOP_FWR, flood magenta.  Four later
# checkpoints each flood a different colour and hold for half a second, so the
# colour left on screen names the last checkpoint reached.  Nothing parks in
# wfe, so if the kernel makes it to userspace the box comes back on its own.
#
# Image is 13762560 bytes = 6720 * 2048.
set -x
dd if=/data/local/tmp/probe-fixed.img of=/dev/block/mmcblk0p7 bs=2048
sync
dd if=/dev/block/mmcblk0p7 of=/data/local/tmp/rec-verify.bin bs=2048 count=6720
chmod 644 /data/local/tmp/rec-verify.bin
md5sum /data/local/tmp/probe-fixed.img /data/local/tmp/rec-verify.bin
echo DONE
