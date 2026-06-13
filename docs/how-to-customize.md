# How to customize the builds

This guide covers the common changes you'll want to make: adding packages,
changing the image, and adjusting bootloader/feature settings. To create a new
recipe or modify an existing one (`.bb` / `.bbappend` / `devtool`), see
[how-to-add-a-recipe.md](how-to-add-a-recipe.md). All
configuration lives in `scripts/conf/` and is applied to each build's
`conf/local.conf` as an idempotent, re-generated block — so edit the fragments
here, **not** the generated `build/*/conf/local.conf` (your edits there would
be overwritten on the next run).

## Where settings live

| File                          | Scope                                   |
| ----------------------------- | --------------------------------------- |
| `scripts/conf/common.conf.inc`| Applied to **every** target             |
| `scripts/conf/x86_64.conf.inc`| Only the x86_64 target                  |
| `scripts/conf/arm64.conf.inc` | Only the arm64 target                   |
| `scripts/lib/common.sh`       | Defaults: release, image, threads, URLs |

## Add packages to every image

Edit `scripts/conf/common.conf.inc` and extend `IMAGE_INSTALL`:

```bash
IMAGE_INSTALL:append = " \
    openssh \
    ...existing... \
    tmux \
    python3 \
    i2c-tools \
"
```

Rebuild — only the affected steps re-run thanks to the sstate cache:

```bash
./scripts/build-arm64.sh
```

## Add a package to only one target

Add the `IMAGE_INSTALL:append` line to the platform fragment
(`x86_64.conf.inc` or `arm64.conf.inc`) instead of the common one.

## Change the default image

Either override per-invocation:

```bash
IMAGE=core-image-full-cmdline ./scripts/build-x86_64.sh
```

...or change the default in `scripts/lib/common.sh`:

```bash
: "${IMAGE:=core-image-base}"     # <- change the recipe name here
```

## Adjust image features

`scripts/conf/common.conf.inc` sets `EXTRA_IMAGE_FEATURES`. For a production
image, **remove `debug-tweaks`** (it allows an empty root password):

```bash
EXTRA_IMAGE_FEATURES ?= "ssh-server-openssh package-management"
```

Then set a real password / user via your own recipe or `extrausers`.

## BusyBox vs. full GNU utilities

By default the core utilities (the shell and applets like `ls`, `cat`, `mount`,
`vi`, …) are provided by **BusyBox** — Yocto's compact default. A few full
tools (`vim`, `nano`, full `wget`/`curl`/`util-linux`, …) are layered on top via
`common.conf.inc`. This is identical on both the x86_64 and arm64 targets.

Switch the whole base userspace to **full GNU coreutils/util-linux** (and remove
BusyBox) with the `BASE_UTILS` env var — no file edits needed:

```bash
BASE_UTILS=full ./scripts/build-x86_64.sh     # full GNU utilities
BASE_UTILS=full ./scripts/build-arm64.sh
./scripts/build-arm64.sh                        # default: busybox
```

Under the hood (`scripts/lib/common.sh`), `BASE_UTILS=full` writes:

```bash
VIRTUAL-RUNTIME_base-utils = "packagegroup-core-base-utils"
VIRTUAL-RUNTIME_base-utils-hwclock = "util-linux-hwclock"
PACKAGE_EXCLUDE += "busybox"
```

To make `full` the permanent default, change the default in
`scripts/lib/common.sh`: `: "${BASE_UTILS:=busybox}"`.

## Bootloader settings

The per-target fragments control booting:

- **x86_64** (`x86_64.conf.inc`): `EFI_PROVIDER = "grub-efi"` selects GRUB over
  systemd-boot.
- **arm64** (`arm64.conf.inc`): `EFI_PROVIDER = "grub-efi"` plus
  `PREFERRED_PROVIDER_virtual/bootloader = "u-boot"` gives the U-Boot → GRUB
  chain.

See [bootloaders.md](bootloaders.md) for the full explanation.

## Add another layer

1. Clone it under `sources/` (add it to `init.sh` so it's reproducible).
2. Register it in `configure_build()` in `scripts/lib/common.sh`:

   ```bash
   add_layer "${SOURCES_DIR}/meta-your-layer"
   ```

`add_layer` is idempotent — it skips layers already present in
`bblayers.conf`.

## Free up disk vs. keep build trees

`configure_build()` enables `INHERIT += "rm_work"`, which deletes each recipe's
work directory after it builds successfully (saves lots of disk). If you need
to debug a recipe's `${WORKDIR}`, remove that line from the `perf_block`
heredoc in `scripts/lib/common.sh`.
