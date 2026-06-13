# How to set up the workspace

This guide explains how to prepare a host machine and initialize the Yocto
workspace from a fresh checkout.

## 1. Check your host meets the requirements

You need a Linux host (native or VM/WSL2) with ~50 GB free disk and the Yocto
build dependencies installed.

### On Debian / Ubuntu

```bash
sudo apt update
sudo apt install gawk wget git diffstat unzip texinfo gcc build-essential \
     chrpath socat cpio python3 python3-pip python3-pexpect xz-utils \
     debianutils iputils-ping python3-git python3-jinja2 python3-subunit \
     zstd liblz4-tool file locales libacl1
```

### On Fedora

```bash
sudo dnf install gawk make wget tar bzip2 gzip python3 unzip perl patch \
     diffutils diffstat git cpp gcc gcc-c++ glibc-devel texinfo chrpath \
     ccache perl-Data-Dumper perl-Text-ParseWords perl-Thread-Queue \
     perl-bignum socat python3-pexpect findutils which file cpio python3-pip \
     xz python3-GitPython python3-jinja2 rpcgen zstd lz4
```

> `init.sh` will warn you about any core tools it can't find, but it does not
> install them for you.

For the authoritative list, see the
[Yocto system requirements](https://docs.yoctoproject.org/ref-manual/system-requirements.html).

## 2. Initialize the workspace

From the repository root, run:

```bash
./scripts/init.sh
```

This clones (or updates) the required layers onto the Yocto **6.0 "Wrynose"**
LTS branch:

| Layer              | Provides                                              |
| ------------------ | ---------------------------------------------------- |
| `poky`             | OE-core, the `genericx86-64` and `genericarm64` BSPs |
| `meta-openembedded`| Extra packages (meta-oe, meta-python, meta-networking)|

The layers land in `sources/` (git-ignored). You only need to run this once;
the build scripts also run it automatically if `sources/` is missing.

## 3. Verify

After it completes you should see:

```
sources/
├── poky/
└── meta-openembedded/
```

You are now ready to build — continue with
[how-to-build.md](how-to-build.md).

## Tracking a different Yocto release

The default is the `wrynose` LTS branch. To track another release, export
`YOCTO_RELEASE` before running any script:

```bash
YOCTO_RELEASE=scarthgap ./scripts/init.sh
```
