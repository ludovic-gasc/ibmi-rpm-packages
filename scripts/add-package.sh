#!/usr/bin/env bash
# =============================================================================
# add-package.sh — Add one or more RPM files to the correct version repository
# =============================================================================
# Usage:
#   ./scripts/add-package.sh --version 7.6 path/to/package.ppc64.rpm [...]
#   ./scripts/add-package.sh --version 7.4 path/to/package.ppc64.rpm [...]
#
# The script detects the architecture from the RPM filename, places the file
# in ibmi/<version>/packages/<arch>/, rebuilds the repodata for that version,
# commits and pushes to GitHub.
# =============================================================================
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPTS_DIR="${REPO_ROOT}/scripts"

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
info()  { echo -e "${GREEN}[INFO]${NC}  $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC}  $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*" >&2; exit 1; }

# ── Parse --version ───────────────────────────────────────────────────────────
IBM_VERSION=""
RPM_FILES=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --version|-v)
      [[ $# -ge 2 ]] || error "--version requires an argument (e.g. 7.4 or 7.6)"
      IBM_VERSION="$2"
      shift 2
      ;;
    *.rpm)
      RPM_FILES+=("$1")
      shift
      ;;
    *)
      error "Unknown argument: $1"
      ;;
  esac
done

[[ -n "${IBM_VERSION}" ]] || error "Missing --version argument. Usage: $0 --version 7.6 package.rpm"
[[ ${#RPM_FILES[@]} -ge 1 ]] || error "No RPM files specified."

PACKAGES_DIR="${REPO_ROOT}/ibmi/${IBM_VERSION}/packages"
[[ -d "${REPO_ROOT}/ibmi/${IBM_VERSION}" ]] \
  || error "IBM i version directory not found: ibmi/${IBM_VERSION}/"

for RPM_FILE in "${RPM_FILES[@]}"; do
  [[ -f "${RPM_FILE}" ]] || error "File not found: ${RPM_FILE}"
  [[ "${RPM_FILE}" == *.rpm ]] || error "Not an RPM file: ${RPM_FILE}"

  # Detect architecture from filename (e.g. foo-1.0.ppc64.rpm → ppc64)
  BASENAME="$(basename "${RPM_FILE}")"
  ARCH="${BASENAME%.*}"   # strip .rpm
  ARCH="${ARCH##*.}"      # keep last component → arch

  case "${ARCH}" in
    noarch|ppc64|ppc64le|x86_64|i686|aarch64) ;;
    *)
      warn "Unknown architecture '${ARCH}' for ${BASENAME}, defaulting to noarch."
      ARCH="noarch"
      ;;
  esac

  DEST_DIR="${PACKAGES_DIR}/${ARCH}"
  mkdir -p "${DEST_DIR}"

  DEST="${DEST_DIR}/${BASENAME}"
  if [[ -f "${DEST}" ]]; then
    if cmp -s "${RPM_FILE}" "${DEST}"; then
      warn "Identical file already present: ${DEST} — skipping."
      continue
    else
      warn "Overwriting existing file: ${DEST}"
    fi
  fi

  cp "${RPM_FILE}" "${DEST}"
  info "Added: ${DEST}"
done

# ── Rebuild repo metadata for this version only ───────────────────────────────
info "Rebuilding repository metadata for IBM i ${IBM_VERSION}..."
bash "${SCRIPTS_DIR}/build-repo.sh" "${IBM_VERSION}"

# ── Commit and push ───────────────────────────────────────────────────────────
info "Staging changes for git..."
git -C "${REPO_ROOT}" add "ibmi/${IBM_VERSION}/" 2>/dev/null || true

if git -C "${REPO_ROOT}" diff --cached --quiet; then
  info "Nothing new to commit."
else
  ADDED_FILES=$(git -C "${REPO_ROOT}" diff --cached --name-only \
    | grep "^ibmi/${IBM_VERSION}/packages/" \
    | xargs -I{} basename {} \
    | paste -sd ", ")
  git -C "${REPO_ROOT}" commit -m "Add package(s) for IBM i ${IBM_VERSION}: ${ADDED_FILES}"
  info "Pushing to GitHub..."
  git -C "${REPO_ROOT}" push origin main
  info "Done — GitHub Actions will publish the updated site to GitHub Pages."
fi
