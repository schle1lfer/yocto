#!/usr/bin/env bash
#
# build-x86_64.sh - Completely build the x86_64 (amd64) target.
#
# Machine    : genericx86-64
# Bootloader : GRUB (grub-efi)
#
# Usage:
#   ./scripts/build-x86_64.sh            # build the default image
#   IMAGE=core-image-full-cmdline ./scripts/build-x86_64.sh
#
# The script is self-contained: it will initialize the workspace (clone the
# layers) automatically if that has not been done yet.
# ---------------------------------------------------------------------------
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"

PLATFORM="x86_64"
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
_log "Building GRUB bootloader for ${PLATFORM}..."
bitbake grub-efi

_log "Building image '${IMAGE}' for ${PLATFORM} (this can take a while)..."
bitbake "${IMAGE}"

# --- Report -----------------------------------------------------------------
DEPLOY_DIR="${BUILDDIR_TARGET}/tmp/deploy/images/genericx86-64"
_log "x86_64 build complete."
_log "Artifacts in: ${DEPLOY_DIR}"
if [ -d "${DEPLOY_DIR}" ]; then
    ls -lh "${DEPLOY_DIR}"/*.wic 2>/dev/null || true
fi
