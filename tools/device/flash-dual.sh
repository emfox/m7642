#!/system/bin/sh
# Flash probe-dual.img into the recovery partition and verify it landed.
#
# The bootloader starts the image at +0xFA0000, not +0, so this build pads the
# kernel out to that offset and puts a trampoline there: steer GOP0, commit with
# GOP_FWR, flood a colour, hold two seconds, then branch back to primary_entry.
# If the branch works the kernel runs for real and primary_entry's own beacons
# take over.
#
# Image is 24111104 bytes = 11773 * 2048.
set -x
dd if=/data/local/tmp/probe-dual.img of=/dev/block/mmcblk0p7 bs=2048
sync
dd if=/dev/block/mmcblk0p7 of=/data/local/tmp/rec-verify.bin bs=2048 count=11773
chmod 644 /data/local/tmp/rec-verify.bin
md5sum /data/local/tmp/probe-dual.img /data/local/tmp/rec-verify.bin
echo DONE
