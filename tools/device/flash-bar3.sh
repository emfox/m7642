#!/system/bin/sh
# Flash probe-bar3.img into the recovery partition and verify it landed.
#
# This build replaces the single full-screen beacon with a progress bar: every
# checkpoint reached in primary_entry paints one 64-line white band, so the
# number of bands on the panel is the number of checkpoints the kernel actually
# got through.  One flash therefore brackets the whole boot path instead of
# testing one step per flash-and-rescue cycle.
#
# Image is 13762560 bytes = 6720 * 2048.
set -x
dd if=/data/local/tmp/probe-bar3.img of=/dev/block/mmcblk0p7 bs=2048
sync
dd if=/dev/block/mmcblk0p7 of=/data/local/tmp/rec-verify.bin bs=2048 count=6720
chmod 644 /data/local/tmp/rec-verify.bin
md5sum /data/local/tmp/probe-bar3.img /data/local/tmp/rec-verify.bin
echo DONE
