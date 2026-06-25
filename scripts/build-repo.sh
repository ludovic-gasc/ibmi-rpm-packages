#!/usr/bin/env bash
# =============================================================================
# build-repo.sh — Build the IBM i RPM repository metadata
# =============================================================================
# Prerequisites (Debian-based):
#   sudo apt install rpm createrepo-c
#
# Usage:
#   ./scripts/build-repo.sh
# =============================================================================
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PACKAGES_DIR="${REPO_ROOT}/packages"
REPODATA_DIR="${REPO_ROOT}/repodata"

# ── Colours ──────────────────────────────────────────────────────────────────
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
info()  { echo -e "${GREEN}[INFO]${NC}  $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC}  $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*" >&2; exit 1; }

# ── Dependency check ─────────────────────────────────────────────────────────
command -v createrepo_c &>/dev/null || error "Missing dependency: createrepo_c  (run: sudo apt install createrepo-c)"

info "Repository root : ${REPO_ROOT}"
info "Packages dir    : ${PACKAGES_DIR}"

# ── Validate package directory ───────────────────────────────────────────────
[[ -d "${PACKAGES_DIR}" ]] || error "packages/ directory not found."

RPM_COUNT=$(find "${PACKAGES_DIR}" -name "*.rpm" | wc -l)
info "Found ${RPM_COUNT} RPM file(s)."
(( RPM_COUNT > 0 )) || warn "No RPM files found — the repository will be empty."

# ── Clean previous repodata ──────────────────────────────────────────────────
info "Cleaning old repodata..."
rm -rf "${REPODATA_DIR}"

# ── Generate repository metadata ─────────────────────────────────────────────
info "Running createrepo_c..."
createrepo_c \
  --workers 4 \
  --checksum sha256 \
  --database \
  --update \
  "${REPO_ROOT}"

info "createrepo_c completed. Metadata written to ${REPODATA_DIR}/"

# ── Summary ──────────────────────────────────────────────────────────────────
info "Done! Repository metadata is ready."
echo ""
echo "  Packages : ${RPM_COUNT}"
echo "  Repodata : ${REPODATA_DIR}/"
echo ""
echo "Next steps:"
echo "  git add -A && git commit -m 'Update repository metadata'"
echo "  git push origin main"
echo "  → GitHub Pages will publish to https://ludovic-gasc.github.io/ibmi-rpm-packages/"
