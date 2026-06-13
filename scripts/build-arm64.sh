#!/usr/bin/env bash
#
# build-arm64.sh - Completely build the arm64 (aarch64) target.
#
# Machine    : genericarm64
# Bootloader : U-Boot (first stage) + GRUB (grub-efi, UEFI stage)
#
# Usage:
#   ./scripts/build-arm64.sh             # build the default image
#   IMAGE=core-image-full-cmdline ./scripts/build-arm64.sh
#
# The script is self-contained: it will initialize the workspace (clone the
# layers) automatically if that has not been done yet.
# ---------------------------------------------------------------------------
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"

PLATFORM="arm64"
FRAGMENT="${SCRIPT_DIR}/conf/${PLATFORM}.conf.inc"
BUILDDIR_TARGET="${BUILD_ROOT}/${PLATFORM}"

# --- Ensure the layers are present -----------------------------------------
if [ ! -f "${SOURCES_DIR}/poky/oe-init-build-env" ]; then
    _log "Sources missing; running init.sh first."
    "${SCRIPT_DIR}/init.sh"
fi

# --- Enter / create the build directory ------------------------------------
_log "Setting up build directory: ${BUILDDIR_TARGET}"
# shellcheck disable=SC1091
source "${SOURCES_DIR}/poky/oe-init-build-env" "${BUILDDIR_TARGET}" >/dev/null

# --- Configure layers + local.conf for this target -------------------------
configure_build "${FRAGMENT}"

# --- Build ------------------------------------------------------------------
_log "Building U-Boot + GRUB bootloaders for ${PLATFORM}..."
bitbake u-boot grub-efi

_log "Building image '${IMAGE}' for ${PLATFORM} (this can take a while)..."
bitbake "${IMAGE}"

# --- Report -----------------------------------------------------------------
DEPLOY_DIR="${BUILDDIR_TARGET}/tmp/deploy/images/genericarm64"
_log "arm64 build complete."
_log "Artifacts in: ${DEPLOY_DIR}"
if [ -d "${DEPLOY_DIR}" ]; then
    ls -lh "${DEPLOY_DIR}"/*.wic 2>/dev/null || true
fi
