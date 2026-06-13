#!/usr/bin/env bash
#
# build-all.sh - Initialize the workspace and build BOTH targets sequentially.
#
#   1. x86_64 (amd64)  - GRUB
#   2. arm64  (aarch64)- U-Boot + GRUB
#
# The two builds share a download + sstate cache, so the second build reuses
# everything the first already produced.
# ---------------------------------------------------------------------------
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"

"${SCRIPT_DIR}/init.sh"

_log "=== Building x86_64 (amd64) target ==="
"${SCRIPT_DIR}/build-x86_64.sh"

_log "=== Building arm64 (aarch64) target ==="
"${SCRIPT_DIR}/build-arm64.sh"

_log "All targets built successfully."
