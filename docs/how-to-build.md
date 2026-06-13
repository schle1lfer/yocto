# How to build the targets

This guide explains how to build each platform image and where the output
lands. Make sure you have completed [how-to-setup.md](how-to-setup.md) first
(or just run a build script — it will initialize the workspace for you).

## Build a single target

### x86_64 (amd64) — boots with GRUB

```bash
./scripts/build-x86_64.sh
```

What it does, in order:

1. Runs `init.sh` if the layers are missing.
2. Sources `oe-init-build-env` to create/enter `build/x86_64/`.
3. Configures `conf/local.conf` (machine `genericx86-64`, `EFI_PROVIDER = "grub-efi"`)
   and adds the `meta-openembedded` layers.
4. Builds the **GRUB** bootloader (`bitbake grub-efi`).
5. Builds the image (`bitbake core-image-base` by default).

### arm64 (aarch64) — boots with U-Boot + GRUB

```bash
./scripts/build-arm64.sh
```

Same flow, but uses machine `genericarm64` and builds **both** bootloaders
(`bitbake u-boot grub-efi`) before the image.

## Build both targets at once

```bash
./scripts/build-all.sh
```

This initializes the workspace and builds x86_64 then arm64. Because both
builds share a download cache (`sources/downloads`) and shared-state cache
(`sources/sstate-cache`), the second build reuses everything the first
produced and finishes much faster.

## Choosing which image to build

The default image recipe is `core-image-base`. Override it with the `IMAGE`
environment variable:

```bash
IMAGE=core-image-minimal       ./scripts/build-x86_64.sh
IMAGE=core-image-full-cmdline  ./scripts/build-arm64.sh
IMAGE=core-image-weston        ./scripts/build-arm64.sh   # graphical
```

## Where the output goes

After a successful build, flashable artifacts are in the deploy directory:

| Target  | Deploy directory                                  |
| ------- | ------------------------------------------------- |
| x86_64  | `build/x86_64/tmp/deploy/images/genericx86-64/`   |
| arm64   | `build/arm64/tmp/deploy/images/genericarm64/`     |

The key file is the `*.wic` disk image (with a matching `*.wic.bmap`). See
[how-to-flash-and-run.md](how-to-flash-and-run.md) to use it.

## First build expectations

A first build downloads several GB of source and compiles a full toolchain +
distro from scratch, so it can take **1–3+ hours** depending on CPU and
network. Subsequent builds are incremental and far quicker thanks to the
shared sstate cache.

## Useful tuning knobs

All overridable via environment variables (see `scripts/lib/common.sh`):

| Variable             | Default               | Purpose                          |
| -------------------- | --------------------- | -------------------------------- |
| `IMAGE`              | `core-image-base`     | Image recipe to build            |
| `BASE_UTILS`         | `busybox`             | Base utilities: `busybox` or `full` GNU |
| `YOCTO_RELEASE`      | `wrynose`             | Yocto branch/codename to track   |
| `SOURCES_DIR`        | `./sources`           | Where layers + caches live       |
| `BUILD_ROOT`         | `./build`             | Where build output is written    |
| `BB_NUMBER_THREADS`  | host CPU count        | Parallel bitbake tasks           |
| `PARALLEL_MAKE_JOBS` | host CPU count        | Parallel `make` jobs per recipe  |

Example:

```bash
BB_NUMBER_THREADS=8 PARALLEL_MAKE_JOBS=8 ./scripts/build-x86_64.sh
```
