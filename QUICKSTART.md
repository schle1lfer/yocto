# Quickstart

Short instructions to initialize the workspace and build each target.

## 1. Initialize (once)

```bash
./scripts/init.sh
```

Clones the Yocto layers into `sources/`.

## 2. Build x86_64 (amd64) — GRUB

```bash
./scripts/build-x86_64.sh
```

Output: `build/x86_64/tmp/deploy/images/genericx86-64/*.wic`

## 3. Build arm64 (aarch64) — U-Boot + GRUB

```bash
./scripts/build-arm64.sh
```

Output: `build/arm64/tmp/deploy/images/genericarm64/*.wic`

## Build both at once

```bash
./scripts/build-all.sh
```

---

- The build scripts auto-run `init.sh` if needed, so step 1 is optional.
- Default image is `core-image-base`; change it with `IMAGE=...`, e.g.
  `IMAGE=core-image-minimal ./scripts/build-arm64.sh`.
- More detail: [docs/how-to-build.md](docs/how-to-build.md).
