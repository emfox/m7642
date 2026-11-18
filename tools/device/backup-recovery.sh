#!/system/bin/sh
# Back up the recovery partition so a bad kernel can be rolled back with dd
# instead of the USB-card rescue dance (no unplugging the TV).
#
# recovery = mmcblk0p7 (32 MB).  Runs through the tvgate root service.
set -x
rm -f /data/local/tmp/recovery-backup.img
dd if=/dev/block/mmcblk0p7 of=/data/local/tmp/recovery-backup.img bs=1048576
chmod 644 /data/local/tmp/recovery-backup.img
md5sum /data/local/tmp/recovery-backup.img
ls -l /data/local/tmp/recovery-backup.img
echo DONE
