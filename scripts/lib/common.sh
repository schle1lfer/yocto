# shellcheck shell=bash
#
# common.sh - Shared configuration and helper functions for the Yocto build
#             scripts in this repository.
#
# This file is meant to be *sourced*, not executed directly.
# ---------------------------------------------------------------------------

# ----------------------------------------------------------------------------
# Yocto release
# ----------------------------------------------------------------------------
# Yocto 6.0 "Wrynose" is the current Long Term Support (LTS) release
# (released May 2026, based on Linux 6.18 LTS, supported until ~April 2030).
# Every layer below is checked out on the matching branch so they stay
# compatible with one another.
: "${YOCTO_RELEASE:=wrynose}"

# ----------------------------------------------------------------------------
# Repository layout
# ----------------------------------------------------------------------------
# Resolve the absolute path of the repository root regardless of where the
# calling script lives or from which directory it was invoked.
COMMON_SH_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${COMMON_SH_DIR}/../.." && pwd)"

# Where the upstream layers are cloned to, and where build artifacts land.
: "${SOURCES_DIR:=${REPO_ROOT}/sources}"
: "${BUILD_ROOT:=${REPO_ROOT}/build}"

# Default image to assemble. Override by exporting IMAGE before invoking a
# build script, e.g.  IMAGE=core-image-full-cmdline ./scripts/build-arm64.sh
: "${IMAGE:=core-image-base}"

# Number of bitbake worker threads / make jobs. Defaults to the host CPU count.
: "${BB_NUMBER_THREADS:=$(nproc 2>/dev/null || echo 4)}"
: "${PARALLEL_MAKE_JOBS:=${BB_NUMBER_THREADS}}"

# ----------------------------------------------------------------------------
# Layers to clone (name | git url | subdir-to-add-as-layer ...)
# ----------------------------------------------------------------------------
# poky bundles oe-core (meta), meta-poky and meta-yocto-bsp. meta-yocto-bsp
# provides the genericx86-64 and genericarm64 machines used by this project.
# meta-openembedded provides a large set of extra packages.
POKY_URL="https://git.yoctoproject.org/poky"
META_OE_URL="https://git.openembedded.org/meta-openembedded"

# ----------------------------------------------------------------------------
# Pretty logging helpers
# ----------------------------------------------------------------------------
_log()  { printf '\033[1;34m[%s]\033[0m %s\n' "$(date +%H:%M:%S)" "$*"; }
_warn() { printf '\033[1;33m[%s] WARN:\033[0m %s\n' "$(date +%H:%M:%S)" "$*" >&2; }
_err()  { printf '\033[1;31m[%s] ERROR:\033[0m %s\n' "$(date +%H:%M:%S)" "$*" >&2; }
_die()  { _err "$*"; exit 1; }

# ----------------------------------------------------------------------------
# git_clone_or_update <url> <branch> <dest>
#   Clone a repo at a branch if missing, otherwise fetch + checkout the branch.
#   Network operations are retried with exponential backoff.
# ----------------------------------------------------------------------------
git_retry() {
    local attempt=1 max=5 delay=2
    while true; do
        if git "$@"; then
            return 0
        fi
        if [ "${attempt}" -ge "${max}" ]; then
            _die "git $* failed after ${max} attempts"
        fi
        _warn "git $* failed (attempt ${attempt}/${max}); retrying in ${delay}s..."
        sleep "${delay}"
        delay=$(( delay * 2 ))
        attempt=$(( attempt + 1 ))
    done
}

git_clone_or_update() {
    local url="$1" branch="$2" dest="$3"
    if [ -d "${dest}/.git" ]; then
        _log "Updating $(basename "${dest}") (branch ${branch})"
        git_retry -C "${dest}" fetch --depth 1 origin "${branch}"
        git -C "${dest}" checkout -B "${branch}" "origin/${branch}"
    else
        _log "Cloning $(basename "${dest}") (branch ${branch})"
        git_retry clone --depth 1 --branch "${branch}" "${url}" "${dest}"
    fi
}

# ----------------------------------------------------------------------------
# require_sources
#   Abort with a helpful message if the layers have not been cloned yet.
# ----------------------------------------------------------------------------
require_sources() {
    if [ ! -f "${SOURCES_DIR}/poky/oe-init-build-env" ]; then
        _die "Sources not found. Run ./scripts/init.sh first."
    fi
}

# ----------------------------------------------------------------------------
# apply_managed_block <conf-file> <marker> <payload-file>
#   Idempotently insert the contents of <payload-file> into <conf-file>,
#   delimited by sentinel comments so re-running a setup script replaces the
#   previous block instead of appending duplicates.
# ----------------------------------------------------------------------------
apply_managed_block() {
    local conf="$1" marker="$2" payload="$3"
    local begin="# >>> ${marker} (managed - do not edit) >>>"
    local end="# <<< ${marker} (managed) <<<"

    touch "${conf}"
    # Strip any previously-managed block.
    if grep -qF "${begin}" "${conf}"; then
        sed -i "/^${begin}\$/,/^${end}\$/d" "${conf}"
    fi
    {
        printf '%s\n' "${begin}"
        cat "${payload}"
        printf '%s\n' "${end}"
    } >> "${conf}"
}

# ----------------------------------------------------------------------------
# add_layer <layer-path>
#   Add a layer to the current build's bblayers.conf if not already present.
#   Must be called after sourcing oe-init-build-env (needs bitbake-layers).
# ----------------------------------------------------------------------------
add_layer() {
    local layer="$1"
    [ -d "${layer}" ] || _die "Layer not found: ${layer}"
    if bitbake-layers show-layers 2>/dev/null | grep -qF "${layer}"; then
        return 0
    fi
    _log "Adding layer: ${layer}"
    bitbake-layers add-layer "${layer}"
}

# ----------------------------------------------------------------------------
# configure_build <platform-fragment>
#   Configure the *current* build directory (must already be inside it via
#   oe-init-build-env). Adds the required layers and writes the managed
#   local.conf blocks: a shared performance/cache block, the common package
#   block, and the per-platform fragment passed as $1.
# ----------------------------------------------------------------------------
configure_build() {
    local platform_fragment="$1"
    local conf="${BUILDDIR:?BUILDDIR not set - source oe-init-build-env first}/conf/local.conf"

    # --- Layers --------------------------------------------------------------
    # meta-yocto-bsp (inside poky) provides the generic machines; meta-oe and
    # friends provide the extra packages referenced in common.conf.inc.
    add_layer "${SOURCES_DIR}/meta-openembedded/meta-oe"
    add_layer "${SOURCES_DIR}/meta-openembedded/meta-python"
    add_layer "${SOURCES_DIR}/meta-openembedded/meta-networking"

    # --- Shared performance / cache block (dynamic) --------------------------
    # A single shared download + sstate cache speeds up the second target's
    # build dramatically by reusing already-built artifacts.
    local perf_block
    perf_block="$(mktemp)"
    cat > "${perf_block}" <<EOF
BB_NUMBER_THREADS = "${BB_NUMBER_THREADS}"
PARALLEL_MAKE = "-j ${PARALLEL_MAKE_JOBS}"

# Shared caches across both targets (relative to this build dir).
DL_DIR = "${SOURCES_DIR}/downloads"
SSTATE_DIR = "${SOURCES_DIR}/sstate-cache"

# Keep the build tidy; remove the work directory of successfully built
# recipes to save disk space. Comment out if you need to debug recipes.
INHERIT += "rm_work"
EOF

    apply_managed_block "${conf}" "project-perf"     "${perf_block}"
    apply_managed_block "${conf}" "project-common"   "${REPO_ROOT}/scripts/conf/common.conf.inc"
    apply_managed_block "${conf}" "project-platform" "${platform_fragment}"
    rm -f "${perf_block}"

    _log "Configured $(basename "${BUILDDIR}"): $(grep -m1 '^MACHINE' "${conf}")"
}
