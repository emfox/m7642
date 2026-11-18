#!/system/bin/sh
# Flash probe-entry2.img into the recovery partition and verify it landed.
#
# Two-way entry probe: one inline blob at +0x600000 (reached only if the
# bootloader starts the image at +0) paints magenta, another at +0xFA0000
# (where the vendor image keeps its chip-check stub) paints white.  Both park in
# wfe, so whichever colour appears names the entry point.
#
# Image is 24111104 bytes = 11773 * 2048.
set -x
dd if=/data/local/tmp/probe-entry2.img of=/dev/block/mmcblk0p7 bs=2048
sync
dd if=/dev/block/mmcblk0p7 of=/data/local/tmp/rec-verify.bin bs=2048 count=11773
chmod 644 /data/local/tmp/rec-verify.bin
md5sum /data/local/tmp/probe-entry2.img /data/local/tmp/rec-verify.bin
echo DONE
