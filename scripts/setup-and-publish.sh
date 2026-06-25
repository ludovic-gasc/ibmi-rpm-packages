#!/usr/bin/env bash
# =============================================================================
# setup-and-publish.sh — Full initialisation script for WSL2
# =============================================================================
# Run ONCE to:
#   1. Generate a dedicated GPG signing key
#   2. Build repository metadata
#   3. Sign repomd.xml
#   4. Initialise the git repository and push to GitHub
#
# Prerequisites:
#   sudo apt install rpm gnupg2 createrepo-c git
#
# Usage:
#   cd /path/to/ibmi-rpm-packages
#   chmod +x scripts/setup-and-publish.sh
#   ./scripts/setup-and-publish.sh
# =============================================================================
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GITHUB_REPO="git@github.com:ludovic-gasc/ibmi-rpm-packages.git"
GPG_EMAIL="ludovic.gasc@be.ibm.com"
GPG_NAME="Ludovic Gasc"
GPG_COMMENT="IBM i RPM Repository Signing Key"

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'
info()    { echo -e "${GREEN}[INFO]${NC}  $*"; }
section() { echo -e "\n${CYAN}══════════════════════════════════════════${NC}"; echo -e "${CYAN}  $*${NC}"; echo -e "${CYAN}══════════════════════════════════════════${NC}"; }

cd "${REPO_ROOT}"

# ── STEP 1: GPG signing key ──────────────────────────────────────────────────
section "Step 1 — GPG signing key"

# Look for an existing key for this email
EXISTING_KEY=$(gpg --list-secret-keys --keyid-format=long "${GPG_EMAIL}" 2>/dev/null \
  | grep "^sec" | awk '{print $2}' | cut -d'/' -f2 | head -1 || true)

if [[ -z "${EXISTING_KEY}" ]]; then
  info "No GPG key found for ${GPG_EMAIL} — generating a new RSA 4096 key..."

  cat > /tmp/gpg-batch.conf <<-GPGEOF
    %no-protection
    Key-Type: RSA
    Key-Length: 4096
    Subkey-Type: RSA
    Subkey-Length: 4096
    Name-Real: ${GPG_NAME}
    Name-Comment: ${GPG_COMMENT}
    Name-Email: ${GPG_EMAIL}
    Expire-Date: 2y
    %commit
GPGEOF

  gpg --batch --gen-key /tmp/gpg-batch.conf
  rm -f /tmp/gpg-batch.conf
  info "GPG key generated."
else
  info "Existing GPG key detected (${EXISTING_KEY}) — reusing it."
fi

# Retrieve the KEY_ID (short fingerprint = 16 hex chars after the /)
export GPG_KEY_ID=$(gpg --list-secret-keys --keyid-format=long "${GPG_EMAIL}" 2>/dev/null \
  | grep "^sec" | awk '{print $2}' | cut -d'/' -f2 | head -1)

info "GPG_KEY_ID = ${GPG_KEY_ID}"

# Export the public key into the repository
gpg --armor --export "${GPG_KEY_ID}" > "${REPO_ROOT}/RPM-GPG-KEY-ibmi"
info "Public key exported: RPM-GPG-KEY-ibmi"

# ── STEP 2: Build repository metadata + sign ─────────────────────────────────
section "Step 2 — Build metadata + sign"
bash "${REPO_ROOT}/scripts/build-repo.sh" --sign

# ── STEP 3: Git init + push ──────────────────────────────────────────────────
section "Step 3 — Git initialisation and first push"

if [[ ! -d "${REPO_ROOT}/.git" ]]; then
  info "Initialising git repository..."
  git -C "${REPO_ROOT}" init -b main
  git -C "${REPO_ROOT}" remote add origin "${GITHUB_REPO}"
else
  info "Git repository already initialised."
  git -C "${REPO_ROOT}" remote set-url origin "${GITHUB_REPO}" 2>/dev/null || \
    git -C "${REPO_ROOT}" remote add origin "${GITHUB_REPO}"
fi

git -C "${REPO_ROOT}" config user.name  "${GPG_NAME}"
git -C "${REPO_ROOT}" config user.email "${GPG_EMAIL}"

git -C "${REPO_ROOT}" add -A
git -C "${REPO_ROOT}" commit -m "Initial commit: IBM i RPM repository with qpdf 12.3.2" || \
  info "Nothing to commit (already up to date)."

info "Pushing to GitHub..."
git -C "${REPO_ROOT}" push -u origin main

# ── STEP 4: Export private key for GitHub Secrets ────────────────────────────
section "Step 4 — GitHub Actions secrets"

echo ""
echo -e "${YELLOW}┌─────────────────────────────────────────────────────────────────┐${NC}"
echo -e "${YELLOW}│  Copy the block below into:                                     │${NC}"
echo -e "${YELLOW}│  GitHub → Settings → Secrets → Actions → GPG_PRIVATE_KEY       │${NC}"
echo -e "${YELLOW}└─────────────────────────────────────────────────────────────────┘${NC}"
echo ""
gpg --armor --export-secret-key "${GPG_KEY_ID}"
echo ""
echo -e "${YELLOW}┌─────────────────────────────────────────────────────────────────┐${NC}"
echo -e "${YELLOW}│  Copy the value below into:                                     │${NC}"
echo -e "${YELLOW}│  GitHub → Settings → Secrets → Actions → GPG_KEY_ID            │${NC}"
echo -e "${YELLOW}└─────────────────────────────────────────────────────────────────┘${NC}"
echo ""
echo "  ${GPG_KEY_ID}"
echo ""
info "Setup complete!"
echo ""
echo "Next steps:"
echo "  1. Create the GitHub repository (if not done yet):"
echo "       https://github.com/new  →  ibmi-rpm-packages  (public)"
echo "  2. Add both secrets (GPG_PRIVATE_KEY + GPG_KEY_ID):"
echo "       https://github.com/ludovic-gasc/ibmi-rpm-packages/settings/secrets/actions"
echo "  3. Enable GitHub Pages:"
echo "       Settings → Pages → Source: GitHub Actions"
echo "  4. Every push to main will automatically rebuild and publish."
