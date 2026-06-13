# ---------------------------------------------------------------------------
# arm64 (aarch64) target configuration
#
# MACHINE genericarm64 is the reference 64-bit Arm machine shipped in
# meta-yocto-bsp. On Arm the typical boot flow is:
#
#     ROM -> U-Boot (first stage, provides a UEFI environment)
#         -> GRUB  (UEFI bootloader)
#         -> Linux kernel
#
# so this target builds and ships BOTH bootloaders: U-Boot and GRUB.
# ---------------------------------------------------------------------------
MACHINE = "genericarm64"

# Use the GRUB EFI bootloader as the UEFI-stage loader.
EFI_PROVIDER = "grub-efi"

# Build U-Boot as the first-stage bootloader. genericarm64 already defines
# UBOOT_MACHINE (qemu_arm64_defconfig) so U-Boot is built for the machine;
# make U-Boot the virtual/bootloader provider explicitly for clarity.
PREFERRED_PROVIDER_virtual/bootloader = "u-boot"

# Produce a ready-to-flash disk image (.wic) plus a block map, and a rootfs
# tarball. The .wic image contains the bootloader(s) and an EFI System
# Partition with GRUB, placed there by the EFI/wic machinery. U-Boot and the
# GRUB EFI binaries are also emitted into the deploy directory.
IMAGE_FSTYPES = "wic wic.bmap tar.bz2"
