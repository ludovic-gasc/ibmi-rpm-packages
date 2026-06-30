#!/QOpenSys/pkgs/bin/bash
# build-qpdf-ibmi7.4.sh — Build QPDF 12.3.2 RPM packages for IBM i 7.4
# Usage: bash build-qpdf-ibmi7.4.sh

set -e

export PATH=/QOpenSys/pkgs/bin:/QOpenSys/usr/bin:/QOpenSys/usr/ccs/bin:/usr/bin:$PATH

RPMBUILD_DIR="$HOME/rpmbuild"
SPEC="$RPMBUILD_DIR/SPECS/qpdf.spec"
LOG="$RPMBUILD_DIR/qpdf-build.log"

echo "=== QPDF 12.3.2 RPM build for IBM i 7.4 ==="
echo "Log: $LOG"
echo ""

# Setup rpmbuild tree
mkdir -p "$RPMBUILD_DIR"/{SPECS,SOURCES,BUILD,RPMS/ppc64,RPMS/noarch,SRPMS,BUILDROOT}

# Check required sources
for f in qpdf-12.3.2.tar.gz qpdf-12.3.2-doc.zip; do
    if [ ! -f "$RPMBUILD_DIR/SOURCES/$f" ]; then
        echo "ERROR: missing $RPMBUILD_DIR/SOURCES/$f"
        exit 1
    fi
done

# Check build tools
for tool in gcc-12 g++-12 cmake ninja pkg-config; do
    if ! which $tool >/dev/null 2>&1; then
        echo "ERROR: $tool not found in PATH"
        exit 1
    fi
done

echo "--- Environment ---"
gcc-12 --version | head -1
cmake --version | head -1
ninja --version
pkg-config --modversion openssl zlib libjpeg 2>/dev/null || true
echo ""

# Clean previous build
rm -rf "$RPMBUILD_DIR/BUILD/qpdf-12.3.2"
rm -f "$RPMBUILD_DIR/RPMS/ppc64/qpdf-"*".ibmi7.4.ppc64.rpm"
rm -f "$RPMBUILD_DIR/RPMS/noarch/qpdf-doc-"*".ibmi7.4.noarch.rpm"

echo "--- Starting rpmbuild ---"
rpmbuild -ba "$SPEC" \
    --nodeps \
    --define "_buildshell /QOpenSys/pkgs/bin/bash" \
    > "$LOG" 2>&1

EXIT_CODE=$?

echo ""
if [ $EXIT_CODE -eq 0 ]; then
    echo "=== BUILD SUCCESS ==="
    echo ""
    echo "Generated RPMs:"
    ls -lh "$RPMBUILD_DIR/RPMS/ppc64/"qpdf*ibmi7.4* \
            "$RPMBUILD_DIR/RPMS/noarch/"qpdf*ibmi7.4* 2>/dev/null
    echo ""
    echo "SRPM:"
    ls -lh "$RPMBUILD_DIR/SRPMS/"qpdf*ibmi7.4* 2>/dev/null
else
    echo "=== BUILD FAILED (exit $EXIT_CODE) ==="
    echo ""
    echo "Last 30 lines of log:"
    tail -30 "$LOG"
    exit $EXIT_CODE
fi
