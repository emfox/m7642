#!/system/bin/sh
# Flash ctrl-vendor-slot2.img into the recovery partition and verify it landed.
#
# Control group: the vendor kernel with exactly one change -- the 212 bytes at
# +0xFA0000 replaced by the reset beacon.  The vendor code1 is `b +0xFA0000`,
# so that offset is reached whether the bootloader enters at +0 or at +0xFA0000
# directly; the result therefore tells us whether that path executes at all.
#
# Image is 27471872 bytes = 13414 * 2048.
set -x
dd if=/data/local/tmp/ctrl-vendor-slot2.img of=/dev/block/mmcblk0p7 bs=2048
sync
dd if=/dev/block/mmcblk0p7 of=/data/local/tmp/rec-verify.bin bs=2048 count=13414
chmod 644 /data/local/tmp/rec-verify.bin
md5sum /data/local/tmp/ctrl-vendor-slot2.img /data/local/tmp/rec-verify.bin
echo DONE
