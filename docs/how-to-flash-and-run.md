# How to flash and run an image

After [building](how-to-build.md) you have a `*.wic` disk image in the deploy
directory. This guide shows how to test it in an emulator and write it to real
hardware.

## Test in QEMU (no hardware needed)

Both generic machines can boot under QEMU. From the repo root:

```bash
# x86_64
source sources/poky/oe-init-build-env build/x86_64
runqemu genericx86-64 nographic

# arm64
source sources/poky/oe-init-build-env build/arm64
runqemu genericarm64 nographic
```

- `nographic` runs in the terminal; drop it for a graphical window.
- Exit a `nographic` session with `Ctrl-A` then `X`.
- Log in as `root` (no password — the `debug-tweaks` feature is enabled by
  default; remove it for production, see
  [how-to-customize.md](how-to-customize.md)).

## Flash to real hardware

> **Warning:** flashing overwrites the entire target device. Double-check the
> device node (`/dev/sdX`, `/dev/mmcblkN`, …) with `lsblk` before running any
> command — picking the wrong device will destroy data.

### Recommended: bmaptool (fast, skips empty blocks)

```bash
cd build/<target>/tmp/deploy/images/<machine>/
sudo bmaptool copy <image>.wic /dev/sdX
```

`bmaptool` automatically uses the generated `<image>.wic.bmap` for speed and
integrity checking.

### Fallback: dd

```bash
cd build/<target>/tmp/deploy/images/<machine>/
sudo dd if=<image>.wic of=/dev/sdX bs=4M conv=fsync status=progress
sync
```

Replace `<target>`/`<machine>` with:

| Target  | `<target>` | `<machine>`      |
| ------- | ---------- | ---------------- |
| x86_64  | `x86_64`   | `genericx86-64`  |
| arm64   | `arm64`    | `genericarm64`   |

## Booting on the target

- **x86_64:** the `.wic` contains a GPT with an EFI System Partition holding
  GRUB. Boot the device in UEFI mode; GRUB loads the kernel.
- **arm64:** U-Boot runs first (from board firmware/storage), provides a UEFI
  environment, and chainloads GRUB, which boots the kernel. The U-Boot binary
  is also emitted to the deploy directory for boards that flash it separately.
