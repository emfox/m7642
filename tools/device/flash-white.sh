#!/system/bin/sh
# Flash probe-white.img into the recovery partition and verify it landed.
#
# Layout, verified by reading the image back on the host:
#   +0x000000  code0 = 4d 5a 00 91, code1 = b +0x600000
#   +0x600000  entry2's verbatim 132-byte blob, only its trailing wfe turned
#              into b primary_entry (lands on +0x429038)
#   +0xFA0000  entry2's second blob, unreachable with the rewritten code1
#
# Colours, in the order they appear if the kernel keeps going:
#   magenta 0x00ff00ff  blob only, the branch did not reach primary_entry
#   white   0x00ffffff  primary_entry entry, before record_mmu_state
#   red     0x000000ff  record_mmu_state + preserve_boot_args done
#   green   0x0000ff00  init idmap + cache maintenance done
#   blue    0x00ff0000  init_kernel_el (el2_setup) done
#   yellow  0x0000ffff  __cpu_setup done, MMU about to be enabled
#
# Image is 24111104 bytes = 11773 * 2048.
set -x
dd if=/data/local/tmp/probe-white.img of=/dev/block/mmcblk0p7 bs=2048
sync
dd if=/dev/block/mmcblk0p7 of=/data/local/tmp/rec-verify.bin bs=2048 count=11773
chmod 644 /data/local/tmp/rec-verify.bin
md5sum /data/local/tmp/probe-white.img /data/local/tmp/rec-verify.bin
echo DONE
