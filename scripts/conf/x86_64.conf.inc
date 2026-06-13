# ---------------------------------------------------------------------------
# x86_64 (amd64) target configuration
#
# MACHINE genericx86-64 is the reference 64-bit PC machine shipped in
# meta-yocto-bsp. It boots via UEFI; we pin the EFI bootloader to GRUB.
# ---------------------------------------------------------------------------
MACHINE = "genericx86-64"

# Use the GRUB EFI bootloader (instead of systemd-boot, the other option).
EFI_PROVIDER = "grub-efi"

# Produce a ready-to-flash disk image (.wic) plus a block map for fast
# flashing with bmaptool, alongside a compressed tarball of the rootfs.
# The .wic image already contains an EFI System Partition with the GRUB
# bootloader installed by the EFI machinery selected above.
IMAGE_FSTYPES = "wic wic.bmap tar.bz2"
