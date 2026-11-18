#!/system/bin/sh
# Flash the GOP-beacon kernel into the recovery partition (mmcblk0p7) and prove
# it landed by reading it back.  The boot partition is untouched, so Android
# still starts normally until something asks mboot for recovery.
#
# Image is 13762560 bytes = 3360 * 4096, so the read-back is exactly the same
# length and the md5s must match.
set -x
dd if=/data/local/tmp/ours-gop-beacon.img of=/dev/block/mmcblk0p7 bs=4096
sync
dd if=/dev/block/mmcblk0p7 of=/data/local/tmp/rec-verify.bin bs=4096 count=3360
chmod 644 /data/local/tmp/rec-verify.bin
md5sum /data/local/tmp/ours-gop-beacon.img /data/local/tmp/rec-verify.bin
echo DONE
