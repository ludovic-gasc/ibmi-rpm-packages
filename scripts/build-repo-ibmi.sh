#!/QOpenSys/pkgs/bin/bash
# =============================================================================
# build-repo-ibmi.sh — Build the IBM i RPM repository metadata on IBM i PASE
# =============================================================================
# To run on IBM i PASE (createrepo is installed via yum, not createrepo_c)
#
# Prerequisites on IBM i:
#   yum install createrepo
#
# Usage:
#   bash build-repo-ibmi.sh <repo_root_dir> [ibmi_version]
#
# Example (called from ~/ibmi-rpm-packages/ cloned on IBM i):
#   bash scripts/build-repo-ibmi.sh ~/ibmi-rpm-packages 7.4
#
# Or with a local RPM staging directory:
#   bash scripts/build-repo-ibmi.sh ~/ibmi-rpm-packages 7.4
# =============================================================================
set -e

export PATH=/QOpenSys/pkgs/bin:/QOpenSys/usr/bin:/usr/bin:$PATH

# ── Arguments ─────────────────────────────────────────────────────────────────
REPO_ROOT="${1:-$(cd "$(dirname "$0")/.." && pwd)}"
VERSION="${2:-7.4}"

IBMI_ROOT="${REPO_ROOT}/ibmi"
SUBDIR="${IBMI_ROOT}/${VERSION}"
PACKAGES_DIR="${SUBDIR}/packages"
REPODATA_DIR="${SUBDIR}/repodata"

echo "=== IBM i RPM Repository Builder (IBM i PASE) ==="
echo "Repo root  : ${REPO_ROOT}"
echo "OS version : ${VERSION}"
echo "Packages   : ${PACKAGES_DIR}"
echo "Repodata   : ${REPODATA_DIR}"
echo ""

# ── Dependency check ──────────────────────────────────────────────────────────
if ! command -v createrepo >/dev/null 2>&1; then
    echo "ERROR: createrepo not found."
    echo "Install it with:  yum install createrepo"
    exit 1
fi
echo "createrepo  : $(createrepo --version 2>&1 | head -1)"
echo ""

# ── Validate directories ──────────────────────────────────────────────────────
if [ ! -d "${SUBDIR}" ]; then
    echo "ERROR: Directory not found: ${SUBDIR}"
    exit 1
fi

if [ ! -d "${PACKAGES_DIR}" ]; then
    echo "ERROR: No packages/ dir in ${SUBDIR}"
    exit 1
fi

# ── Count RPMs ────────────────────────────────────────────────────────────────
RPM_COUNT=$(find "${PACKAGES_DIR}" -name "*.rpm" | wc -l | tr -d ' ')
echo "Found ${RPM_COUNT} RPM file(s):"
find "${PACKAGES_DIR}" -name "*.rpm" | sort
echo ""

if [ "$RPM_COUNT" -eq 0 ]; then
    echo "WARNING: No RPM files found — repository will be empty."
fi

# ── Clean old repodata ────────────────────────────────────────────────────────
echo "Cleaning old repodata..."
rm -rf "${REPODATA_DIR}"

# ── Run createrepo ────────────────────────────────────────────────────────────
echo "Running createrepo on ${SUBDIR} ..."
createrepo \
    --checksum sha256 \
    --database \
    --update \
    "${SUBDIR}"

echo ""
echo "=== Repository metadata generated ==="
echo "Contents of ${REPODATA_DIR}:"
ls -lh "${REPODATA_DIR}/"

echo ""
echo "=== Done ==="
echo ""
echo "Next steps (on your workstation):"
echo "  scp -r ${REPODATA_DIR} <local>/ibmi-rpm-packages/ibmi/${VERSION}/repodata"
echo "  cd <local>/ibmi-rpm-packages"
echo "  git add -A && git commit -m 'Regenerate repodata for IBM i ${VERSION}'"
echo "  git push origin main"
