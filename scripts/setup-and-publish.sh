#!/usr/bin/env bash
# =============================================================================
# setup-and-publish.sh — Full initialisation script for WSL2
# =============================================================================
# Run ONCE to:
#   1. Build repository metadata
#   2. Initialise the git repository and push to GitHub
#
# Prerequisites:
#   sudo apt install rpm createrepo-c git
#
# Usage:
#   cd /path/to/ibmi-rpm-packages
#   chmod +x scripts/setup-and-publish.sh
#   ./scripts/setup-and-publish.sh
# =============================================================================
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GITHUB_REPO="git@github.com:ludovic-gasc/ibmi-rpm-packages.git"
GIT_NAME="Ludovic Gasc"
GIT_EMAIL="ludovic.gasc@be.ibm.com"

GREEN='\033[0;32m'; CYAN='\033[0;36m'; NC='\033[0m'
info()    { echo -e "${GREEN}[INFO]${NC}  $*"; }
section() { echo -e "\n${CYAN}══════════════════════════════════════════${NC}"; echo -e "${CYAN}  $*${NC}"; echo -e "${CYAN}══════════════════════════════════════════${NC}"; }

cd "${REPO_ROOT}"

# ── STEP 1: Build repository metadata ────────────────────────────────────────
section "Step 1 — Build metadata"
bash "${REPO_ROOT}/scripts/build-repo.sh"

# ── STEP 2: Git init + push ──────────────────────────────────────────────────
section "Step 2 — Git initialisation and first push"

if [[ ! -d "${REPO_ROOT}/.git" ]]; then
  info "Initialising git repository..."
  git -C "${REPO_ROOT}" init -b main
  git -C "${REPO_ROOT}" remote add origin "${GITHUB_REPO}"
else
  info "Git repository already initialised."
  git -C "${REPO_ROOT}" remote set-url origin "${GITHUB_REPO}" 2>/dev/null || \
    git -C "${REPO_ROOT}" remote add origin "${GITHUB_REPO}"
fi

git -C "${REPO_ROOT}" config user.name  "${GIT_NAME}"
git -C "${REPO_ROOT}" config user.email "${GIT_EMAIL}"

git -C "${REPO_ROOT}" add -A
git -C "${REPO_ROOT}" commit -m "Initial commit: IBM i RPM repository with qpdf 12.3.2" || \
  info "Nothing to commit (already up to date)."

info "Pushing to GitHub..."
git -C "${REPO_ROOT}" push -u origin main

info "Setup complete!"
echo ""
echo "Next steps:"
echo "  1. Create the GitHub repository (if not done yet):"
echo "       https://github.com/new  →  ibmi-rpm-packages  (public)"
echo "  2. Enable GitHub Pages:"
echo "       Settings → Pages → Source: GitHub Actions"
echo "  3. Every push to main will automatically rebuild and publish."
