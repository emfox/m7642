#!/system/bin/sh
# Dump the m7642 USB block map: EHCI caps + UTMI head for all four ports.
# Base = mstar_pm_base + 0x200000 (VA 0xffffff800a200000).
# Offsets come from disassembling ehci_hcd_mstar_drv_probe on the live kernel.
OUT=/data/local/tmp/usbmap.txt
rm -f $OUT
dumpreg() {
  sh /data/local/tmp/rung.sh "addr=$1 len=64" >> $OUT 2>&1
}
# EHCI register set
dumpreg 0xffffff800a204800   # port1 ehc  USB+0x04800  (bus2)
dumpreg 0xffffff800a201a00   # port2 ehc  USB+0x01a00  (bus1)
dumpreg 0xffffff800a022600   # port3 ehc  USB+0x02600  (bus3, MT7663)
dumpreg 0xffffff800a6e2800   # port4 ehc  USB+0x4e2800 (bus4)
# UTMI / PHY head
dumpreg 0xffffff800a207500   # port1 utmi USB+0x07500
dumpreg 0xffffff800a207400   # port2 utmi USB+0x07400
dumpreg 0xffffff800a022900   # port3 utmi USB+0x02900
dumpreg 0xffffff800a6e2400   # port4 utmi USB+0x4e2400
chmod 644 $OUT
echo RUNDONE
