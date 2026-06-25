#!/usr/bin/env bash
# =============================================================================
# build-repo.sh — Build and sign the IBM i RPM repository
# =============================================================================
# Prerequisites (WSL2 / Debian-based):
#   sudo apt install rpm gnupg2 createrepo-c
#
# Usage:
#   ./scripts/build-repo.sh [--sign]        # --sign requires GPG_KEY_ID set
# =============================================================================
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PACKAGES_DIR="${REPO_ROOT}/packages"
REPODATA_DIR="${REPO_ROOT}/repodata"
GPG_KEY_ID="${GPG_KEY_ID:-}"
SIGN="${1:-}"

# ── Colours ──────────────────────────────────────────────────────────────────
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
info()  { echo -e "${GREEN}[INFO]${NC}  $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC}  $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*" >&2; exit 1; }

# ── Dependency check ─────────────────────────────────────────────────────────
for cmd in createrepo_c gpg; do
  command -v "$cmd" &>/dev/null || error "Missing dependency: $cmd  (run: sudo apt install createrepo-c gnupg2)"
done

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

# ── GPG signature ────────────────────────────────────────────────────────────
if [[ "${SIGN}" == "--sign" ]]; then
  [[ -n "${GPG_KEY_ID}" ]] || error "Set GPG_KEY_ID env var before signing (e.g. export GPG_KEY_ID=ABCD1234)."

  info "Signing repomd.xml with GPG key ${GPG_KEY_ID}..."
  gpg --default-key "${GPG_KEY_ID}" \
      --batch \
      --yes \
      --armor \
      --detach-sign \
      "${REPODATA_DIR}/repomd.xml"

  info "Signature written: ${REPODATA_DIR}/repomd.xml.asc"

  # Export public key for clients
  info "Exporting public key to RPM-GPG-KEY-ibmi..."
  gpg --armor --export "${GPG_KEY_ID}" > "${REPO_ROOT}/RPM-GPG-KEY-ibmi"
  info "Public key exported: RPM-GPG-KEY-ibmi"
else
  warn "Skipping GPG signature (pass --sign to enable, and set GPG_KEY_ID)."
fi

# ── Summary ──────────────────────────────────────────────────────────────────
info "Done! Repository metadata is ready."
echo ""
echo "  Packages : ${RPM_COUNT}"
echo "  Repodata : ${REPODATA_DIR}/"
if [[ -f "${REPODATA_DIR}/repomd.xml.asc" ]]; then
  echo "  Signature: ${REPODATA_DIR}/repomd.xml.asc"
fi
echo ""
echo "Next steps:"
echo "  git add -A && git commit -m 'Update repository metadata'"
echo "  git push origin main"
echo "  → GitHub Pages will publish to https://ludovic-gasc.github.io/ibmi-rpm-packages/"
