#!/usr/bin/env bash
# =============================================================================
# build-repo.sh — Build the IBM i RPM repository metadata for all OS versions
# =============================================================================
# Prerequisites (Debian-based / WSL2 Ubuntu):
#   sudo apt install createrepo-c
#
# Usage:
#   ./scripts/build-repo.sh              # rebuild all versions
#   ./scripts/build-repo.sh 7.4          # rebuild only ibmi/7.4
#   ./scripts/build-repo.sh 7.6          # rebuild only ibmi/7.6
# =============================================================================
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
IBMI_ROOT="${REPO_ROOT}/ibmi"

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
info()    { echo -e "${GREEN}[INFO]${NC}  $*"; }
warn()    { echo -e "${YELLOW}[WARN]${NC}  $*"; }
error()   { echo -e "${RED}[ERROR]${NC} $*" >&2; exit 1; }
section() { echo -e "\n${GREEN}── $* ──${NC}"; }

# ── Dependency check ─────────────────────────────────────────────────────────
command -v createrepo_c &>/dev/null \
  || error "Missing dependency: createrepo_c  (run: sudo apt install createrepo-c)"

# ── Determine which versions to build ────────────────────────────────────────
if [[ $# -ge 1 ]]; then
  VERSIONS=("$@")
else
  # Auto-detect: any subdirectory of ibmi/ that contains a packages/ dir
  mapfile -t VERSIONS < <(
    find "${IBMI_ROOT}" -mindepth 1 -maxdepth 1 -type d \
      | while read -r d; do
          [[ -d "${d}/packages" ]] && basename "${d}"
        done \
      | sort -V
  )
fi

[[ ${#VERSIONS[@]} -gt 0 ]] || error "No IBM i version directories found under ibmi/"

TOTAL_RPMS=0

for VER in "${VERSIONS[@]}"; do
  SUBDIR="${IBMI_ROOT}/${VER}"
  PACKAGES_DIR="${SUBDIR}/packages"
  REPODATA_DIR="${SUBDIR}/repodata"

  [[ -d "${SUBDIR}" ]]   || { warn "Directory not found: ${SUBDIR} — skipping."; continue; }
  [[ -d "${PACKAGES_DIR}" ]] || { warn "No packages/ dir in ${SUBDIR} — skipping."; continue; }

  section "IBM i ${VER}"
  info "Packages dir : ${PACKAGES_DIR}"

  RPM_COUNT=$(find "${PACKAGES_DIR}" -name "*.rpm" | wc -l)
  info "Found ${RPM_COUNT} RPM file(s)."
  (( RPM_COUNT > 0 )) || warn "No RPM files — the repository for ${VER} will be empty."
  TOTAL_RPMS=$(( TOTAL_RPMS + RPM_COUNT ))

  info "Cleaning old repodata..."
  rm -rf "${REPODATA_DIR}"

  info "Running createrepo_c..."
  createrepo_c \
    --workers 4 \
    --checksum sha256 \
    --database \
    --update \
    "${SUBDIR}"

  info "Metadata written to ${REPODATA_DIR}/"
done

echo ""
info "All done — ${TOTAL_RPMS} RPM(s) across ${#VERSIONS[@]} version(s)."
echo ""
echo "Next steps:"
echo "  git add -A && git commit -m 'Update repository metadata'"
echo "  git push origin main"
echo "  → GitHub Pages publishes:"
for VER in "${VERSIONS[@]}"; do
  echo "      https://ludovic-gasc.github.io/ibmi-rpm-packages/ibmi/${VER}/"
done
