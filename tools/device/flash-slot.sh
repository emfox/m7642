#!/system/bin/sh
# Flash probe-slot5.img into the recovery partition (mmcblk0p7) and verify it
# landed.  The boot partition is untouched, so Android keeps starting normally
# until something explicitly asks mboot for recovery.
#
# Image is 24111104 bytes = 11773 * 2048, so the read-back is exactly the same
# length and the two md5s must match.
set -x
dd if=/data/local/tmp/probe-slot5.img of=/dev/block/mmcblk0p7 bs=2048
sync
dd if=/dev/block/mmcblk0p7 of=/data/local/tmp/rec-verify.bin bs=2048 count=11773
chmod 644 /data/local/tmp/rec-verify.bin
md5sum /data/local/tmp/probe-slot5.img /data/local/tmp/rec-verify.bin
echo DONE
