# Yocto Multi-Target Build

Build scripts for a Yocto-based Linux system targeting two architectures, using
the current Yocto **6.0 "Wrynose"** LTS release (Linux 6.18, supported to ~2030).

| Target          | MACHINE          | Bootloader(s)              |
| --------------- | ---------------- | -------------------------- |
| x86_64 (amd64)  | `genericx86-64`  | **GRUB** (grub-efi)        |
| arm64 (aarch64) | `genericarm64`   | **U-Boot** + **GRUB**      |

On Arm, U-Boot runs as the first-stage bootloader and provides a UEFI
environment that loads GRUB, which in turn boots the kernel — so the arm64
target builds and ships both bootloaders.

## Documentation

Step-by-step how-to guides live in [`docs/`](docs/):

| Guide | What it covers |
| ----- | -------------- |
| [how-to-setup.md](docs/how-to-setup.md) | Install host dependencies and initialize the workspace |
| [how-to-build.md](docs/how-to-build.md) | Build each target, pick an image, tune the build |
| [how-to-flash-and-run.md](docs/how-to-flash-and-run.md) | Run in QEMU and flash images to hardware |
| [how-to-customize.md](docs/how-to-customize.md) | Add packages, change images, adjust features/layers |
| [how-to-add-a-recipe.md](docs/how-to-add-a-recipe.md) | Create a new recipe or customize an existing one (.bbappend, devtool) |
| [bootloaders.md](docs/bootloaders.md) | Why x86_64 uses GRUB and arm64 uses U-Boot + GRUB |

## Layout

```
scripts/
├── init.sh              # Clone/update the Yocto layers (poky, meta-openembedded)
├── build-x86_64.sh      # Fully build the x86_64 (amd64) target  -> GRUB
├── build-arm64.sh       # Fully build the arm64 target           -> U-Boot + GRUB
├── build-all.sh         # init + build both targets sequentially
├── lib/common.sh        # Shared config + helper functions
└── conf/
    ├── common.conf.inc  # Packages/features added to every image
    ├── x86_64.conf.inc  # x86_64 machine + GRUB settings
    └── arm64.conf.inc   # arm64 machine + U-Boot/GRUB settings
docs/                    # How-to guides (see Documentation above)
```

Cloned layers land in `sources/`, build output in `build/<target>/`. Both are
git-ignored. The two builds share `sources/downloads` and
`sources/sstate-cache` so the second target reuses the first's artifacts.

## Prerequisites

A Linux host with the Yocto build dependencies. On Debian/Ubuntu:

```bash
sudo apt install gawk wget git diffstat unzip texinfo gcc build-essential \
     chrpath socat cpio python3 python3-pip python3-pexpect xz-utils \
     debianutils iputils-ping python3-git python3-jinja2 python3-subunit \
     zstd liblz4-tool file locales libacl1
```

`init.sh` warns about any missing core tools it detects. See the
[Yocto system requirements](https://docs.yoctoproject.org/ref-manual/system-requirements.html).

## Usage

```bash
# One-time: clone the layers (also runs automatically on first build)
./scripts/init.sh

# Build a single target
./scripts/build-x86_64.sh
./scripts/build-arm64.sh

# ...or build everything
./scripts/build-all.sh
```

### Choosing the image

The default image is `core-image-base`. Override with the `IMAGE` env var:

```bash
IMAGE=core-image-full-cmdline ./scripts/build-arm64.sh
IMAGE=core-image-minimal      ./scripts/build-x86_64.sh
```

Other useful overrides (see `scripts/lib/common.sh`):

| Variable        | Default          | Purpose                          |
| --------------- | ---------------- | -------------------------------- |
| `YOCTO_RELEASE` | `wrynose`        | Yocto branch/codename to track   |
| `IMAGE`         | `core-image-base`| Image recipe to build            |
| `BASE_UTILS`    | `busybox`        | Base utilities: `busybox` or `full` GNU |
| `SOURCES_DIR`   | `./sources`      | Where layers are cloned          |
| `BUILD_ROOT`    | `./build`        | Where build output is written    |

## Output

After a successful build, flashable artifacts are in:

```
build/x86_64/tmp/deploy/images/genericx86-64/
build/arm64/tmp/deploy/images/genericarm64/
```

Look for the `*.wic` disk image (and `*.wic.bmap`). Flash with `bmaptool`:

```bash
sudo bmaptool copy <image>.wic /dev/sdX
```

### Quick test under QEMU

Both generic machines can be booted in QEMU without real hardware:

```bash
# from within a build dir's environment
source sources/poky/oe-init-build-env build/arm64
runqemu genericarm64 nographic
```
