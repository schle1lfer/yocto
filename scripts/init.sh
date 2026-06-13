#!/usr/bin/env bash
#
# init.sh - Initialize the Yocto workspace.
#
# Clones (or updates) all of the layers required to build the x86_64 and
# arm64 targets onto the Yocto "Wrynose" (6.0 LTS) branch.
#
# Usage:
#   ./scripts/init.sh
#
# Optional environment overrides:
#   YOCTO_RELEASE   Yocto branch/codename to track (default: wrynose)
#   SOURCES_DIR     Where layers are cloned (default: <repo>/sources)
# ---------------------------------------------------------------------------
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"

_log "Initializing Yocto workspace for release: ${YOCTO_RELEASE}"

# --- Host tooling sanity check ---------------------------------------------
missing=()
for tool in git tar gcc g++ make python3 chrpath diffstat wget cpio; do
    command -v "${tool}" >/dev/null 2>&1 || missing+=("${tool}")
done
if [ "${#missing[@]}" -gt 0 ]; then
    _warn "Missing host build tools: ${missing[*]}"
    _warn "On Debian/Ubuntu install them with:"
    _warn "  sudo apt install gawk wget git diffstat unzip texinfo gcc build-essential \\"
    _warn "       chrpath socat cpio python3 python3-pip python3-pexpect xz-utils \\"
    _warn "       debianutils iputils-ping python3-git python3-jinja2 python3-subunit \\"
    _warn "       zstd liblz4-tool file locales libacl1"
    _warn "See: https://docs.yoctoproject.org/ref-manual/system-requirements.html"
fi

mkdir -p "${SOURCES_DIR}"

# --- Clone / update the layers ---------------------------------------------
# poky = oe-core (meta) + meta-poky + meta-yocto-bsp (genericx86-64 / genericarm64)
git_clone_or_update "${POKY_URL}"    "${YOCTO_RELEASE}" "${SOURCES_DIR}/poky"
# meta-openembedded = extra packages (meta-oe, meta-python, meta-networking, ...)
git_clone_or_update "${META_OE_URL}" "${YOCTO_RELEASE}" "${SOURCES_DIR}/meta-openembedded"

_log "Workspace ready."
_log "Layers cloned under: ${SOURCES_DIR}"
echo
_log "Next steps:"
_log "  ./scripts/build-x86_64.sh    # build the x86_64 (amd64) image"
_log "  ./scripts/build-arm64.sh     # build the arm64 image"
