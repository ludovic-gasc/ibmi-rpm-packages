#!/usr/bin/env bash
# =============================================================================
# add-package.sh — Add one or more RPM files to the repository
# =============================================================================
# Usage:
#   ./scripts/add-package.sh path/to/package-1.0.0.ppc64.rpm [another.rpm ...]
#
# The script detects the architecture from the RPM filename and places the
# file in the correct packages/<arch>/ subdirectory, then rebuilds the repo.
# =============================================================================
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PACKAGES_DIR="${REPO_ROOT}/packages"
SCRIPTS_DIR="${REPO_ROOT}/scripts"

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
info()  { echo -e "${GREEN}[INFO]${NC}  $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC}  $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*" >&2; exit 1; }

(( $# >= 1 )) || error "Usage: $0 <package.rpm> [package2.rpm ...]"

for RPM_FILE in "$@"; do
  [[ -f "${RPM_FILE}" ]] || error "File not found: ${RPM_FILE}"
  [[ "${RPM_FILE}" == *.rpm ]] || error "Not an RPM file: ${RPM_FILE}"

  # Detect architecture from filename  (e.g. foo-1.0.ppc64.rpm → ppc64)
  BASENAME="$(basename "${RPM_FILE}")"
  ARCH="${BASENAME##*.}" # remove everything before last dot → rpm
  ARCH="${BASENAME%.*}"  # strip .rpm
  ARCH="${ARCH##*.}"     # strip everything before last remaining dot → arch

  # Normalise known architectures
  case "${ARCH}" in
    noarch|ppc64|ppc64le|x86_64|i686|aarch64) ;;
    *)
      warn "Unknown architecture '${ARCH}' for ${BASENAME}, defaulting to noarch."
      ARCH="noarch"
      ;;
  esac

  DEST_DIR="${PACKAGES_DIR}/${ARCH}"
  mkdir -p "${DEST_DIR}"

  # Refuse to silently overwrite a different file
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

# Rebuild repo metadata (without signing — call build-repo.sh --sign manually if needed)
info "Rebuilding repository metadata..."
bash "${SCRIPTS_DIR}/build-repo.sh"
