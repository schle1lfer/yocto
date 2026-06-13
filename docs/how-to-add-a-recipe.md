# How to add or customize a package / recipe

The [how-to-customize.md](how-to-customize.md) guide covers *selecting* which
existing packages go into an image. This guide covers the next step: creating a
**new** recipe or **modifying an existing** one. In Yocto a package is produced
by a *recipe* (a `.bb` file); you customize an upstream recipe with a
*`.bbappend`*.

Everything below lives in your **own layer** so upstream layers
(`poky`, `meta-openembedded`) stay pristine and updatable.

## 1. Create a project layer (once)

Create a layer to hold your recipes, next to the other layers:

```bash
source sources/poky/oe-init-build-env build/x86_64
bitbake-layers create-layer ../../sources/meta-project
```

Then make the build scripts add it automatically: in
`scripts/lib/common.sh`, inside `configure_build()`, add it alongside the other
`add_layer` calls:

```bash
add_layer "${SOURCES_DIR}/meta-project"
```

Now `meta-project` is part of every build. Put recipes under
`sources/meta-project/recipes-<category>/<name>/`.

## 2. Add a brand-new recipe

Example: package a small program built from source.

`sources/meta-project/recipes-example/hello/hello_1.0.bb`:

```bash
SUMMARY = "Minimal example program"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://LICENSE;md5=<checksum>"

SRC_URI = "git://example.com/hello.git;branch=main;protocol=https"
SRCREV = "<commit-sha>"

S = "${WORKDIR}/git"

# Pick the build style that matches the project:
inherit cmake        # or: autotools, meson, setuptools3, etc.
```

Build just this recipe to test it:

```bash
source sources/poky/oe-init-build-env build/x86_64
bitbake hello
```

Then add it to an image so it ships — see
[how-to-customize.md](how-to-customize.md) (`IMAGE_INSTALL:append = " hello"`).

> Tip: don't hand-write recipes from scratch when you can avoid it. Use
> `devtool` (section 4) to generate a working recipe, then move it into
> `meta-project`.

## 3. Customize an existing recipe with a `.bbappend`

To change a recipe that already exists upstream (e.g. add a config flag, patch,
or extra file), create a `.bbappend` with the **same name** under your layer.
The append is layered on top of the original — you don't copy it.

Example — add a patch and turn on a feature for `openssh`:

`sources/meta-project/recipes-connectivity/openssh/openssh_%.bbappend`:

```bash
# '%' matches any version, so the append survives version bumps.
FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI += "file://0001-my-change.patch"

# Example: add a build/config option
PACKAGECONFIG:append = " some-feature"
```

Put the patch at
`sources/meta-project/recipes-connectivity/openssh/files/0001-my-change.patch`.

Common things a `.bbappend` does:

| Goal                                   | What to add                                  |
| -------------------------------------- | -------------------------------------------- |
| Apply a patch                          | `SRC_URI += "file://xxx.patch"`              |
| Ship an extra config file              | `SRC_URI += "file://my.conf"` + a `do_install:append` |
| Enable/disable a build option          | `PACKAGECONFIG:append = " feature"`          |
| Override a kernel/defconfig fragment   | `SRC_URI += "file://my.cfg"`                 |
| Pin a different source revision        | `SRCREV = "<sha>"`                           |

Rebuild the affected recipe and the image:

```bash
bitbake openssh
./scripts/build-x86_64.sh
```

## 4. Fast iteration with devtool (recommended)

`devtool` is the easiest way to create or modify recipes. From a build env:

```bash
source sources/poky/oe-init-build-env build/x86_64

# Generate a recipe for new upstream source:
devtool add hello https://example.com/hello.git

# ...or extract an existing recipe to hack on it:
devtool modify openssh
```

`devtool` drops the source into `build/x86_64/workspace/sources/<name>/` where
you can edit and rebuild quickly:

```bash
devtool build hello
devtool deploy-target hello root@<target-ip>   # test on a running device
```

When you're happy, fold the result into your layer:

```bash
# Turn local git changes into a patch-based bbappend in meta-project:
devtool finish hello ../../sources/meta-project
```

This produces the recipe (or `.bbappend` + patches) in `meta-project` so the
change is reproducible in every build.

## 5. Verify it landed

```bash
bitbake -e <recipe> | grep ^SRC_URI=     # confirm your sources/patches
oe-pkgdata-util list-pkg-files <recipe>  # see what files the package ships
```

## Layout recap

```
sources/meta-project/
├── conf/layer.conf
├── recipes-example/
│   └── hello/
│       └── hello_1.0.bb
└── recipes-connectivity/
    └── openssh/
        ├── openssh_%.bbappend
        └── files/
            └── 0001-my-change.patch
```
