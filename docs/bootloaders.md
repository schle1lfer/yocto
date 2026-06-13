# Bootloaders explained

This project deliberately uses different bootloader setups per architecture.
This document explains what each target does and why.

## Summary

| Target          | MACHINE         | Boot chain                          |
| --------------- | --------------- | ----------------------------------- |
| x86_64 (amd64)  | `genericx86-64` | UEFI firmware → **GRUB** → kernel   |
| arm64 (aarch64) | `genericarm64`  | **U-Boot** → **GRUB** (UEFI) → kernel |

## x86_64: GRUB only

PCs implement the UEFI standard in firmware. The `.wic` disk image is laid out
with a GPT partition table containing an EFI System Partition (ESP). GRUB is
installed onto the ESP as the EFI bootloader.

This is selected in `scripts/conf/x86_64.conf.inc`:

```bash
EFI_PROVIDER = "grub-efi"
```

`genericx86-64` could otherwise default to systemd-boot; pinning
`EFI_PROVIDER` to `grub-efi` guarantees GRUB. The build step
`bitbake grub-efi` produces the EFI binary, and the wic image-creation step
copies it onto the ESP.

Boot flow:

```
UEFI firmware  ->  GRUB (grubx64.efi on the ESP)  ->  Linux kernel
```

## arm64: U-Boot + GRUB

Most Arm boards do **not** ship UEFI firmware. The common pattern is to use
U-Boot as the first-stage bootloader; modern U-Boot includes a UEFI
implementation, so it can then load a standard UEFI bootloader (GRUB), which
boots the kernel. This keeps the upper half of the boot chain identical to
x86_64.

Selected in `scripts/conf/arm64.conf.inc`:

```bash
EFI_PROVIDER = "grub-efi"
PREFERRED_PROVIDER_virtual/bootloader = "u-boot"
```

The arm64 build runs `bitbake u-boot grub-efi`, producing both. `genericarm64`
already defines `UBOOT_MACHINE` (e.g. `qemu_arm64_defconfig`), so U-Boot is
built for the machine and emitted to the deploy directory; GRUB is placed on
the image's ESP just like x86_64.

Boot flow:

```
Board ROM  ->  U-Boot (first stage, provides UEFI)  ->  GRUB  ->  Linux kernel
```

## Where the bootloader binaries end up

After a build, look in the deploy directory:

- x86_64: `build/x86_64/tmp/deploy/images/genericx86-64/`
  — the `.wic` image already contains GRUB on its ESP.
- arm64: `build/arm64/tmp/deploy/images/genericarm64/`
  — the `.wic` image contains GRUB; the standalone `u-boot*` binary is also
  present for boards that flash U-Boot to a separate location.

## Adapting to a specific board

`genericarm64`/`genericx86-64` are reference machines. For a particular SoC or
board you would typically add a vendor BSP layer and switch `MACHINE`, then set
the board's `UBOOT_MACHINE`/`UBOOT_CONFIG` (and possibly device tree) in that
target's fragment. The U-Boot → GRUB structure documented here stays the same.
