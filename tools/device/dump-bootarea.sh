#!/system/bin/sh
# Read both eMMC boot areas.  mboot keeps its environment somewhere in here
# (that is where the earlier E_LX_MEM_ADR hunt pointed), and nothing about the
# boot path is documented anywhere else.  Read only: force_ro is released just
# long enough to open the node for reading and then put straight back.
set -x
echo 0 > /sys/block/mmcblk0boot0/force_ro
echo 0 > /sys/block/mmcblk0boot1/force_ro
dd if=/dev/block/mmcblk0boot0 of=/data/local/tmp/boot0.bin bs=512 count=4096
dd if=/dev/block/mmcblk0boot1 of=/data/local/tmp/boot1.bin bs=512 count=4096
echo 1 > /sys/block/mmcblk0boot0/force_ro
echo 1 > /sys/block/mmcblk0boot1/force_ro
chmod 644 /data/local/tmp/boot0.bin /data/local/tmp/boot1.bin
md5sum /data/local/tmp/boot0.bin /data/local/tmp/boot1.bin
echo DONE
