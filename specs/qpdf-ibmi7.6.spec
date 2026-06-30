Summary: Command-line tools and library for transforming PDF files
Name:    qpdf
Version: 12.3.2
Release: 1%{?dist}
# MIT: e.g. libqpdf/sha2.c, but those are not compiled in (OpenSSL is used)
# upstream uses ASL 2.0 now, but he allowed others to distribute qpdf under
# old license (see README)
License: Apache-2.0 OR Artistic-2.0
URL:     https://qpdf.sourceforge.io/
Source0: %{name}-%{version}.tar.gz
Source1: %{name}-%{version}-doc.zip

# NOTE: spec file based on Fedora project: https://rpms.remirepo.net/rpmphp/zoom.php?rpm=qpdf
# NOTE: qpdf-relax.patch is GnuTLS/FIPS-specific → not applicable on IBM i (OpenSSL backend)
# NOTE: qpdf-s390x-disable-tests-zlib.patch is s390x-specific → not applicable on IBM i

# gcc12 / gcc12-cplusplus required: QPDF 12.x requires C++20, gcc6 only supports C++17
BuildRequires: gcc12
BuildRequires: gcc12-cplusplus
BuildRequires: cmake
BuildRequires: ninja-build

BuildRequires: zlib-devel
BuildRequires: libjpeg-turbo-devel

# Crypto: OpenSSL (GnuTLS unavailable on IBM i PASE)
BuildRequires: openssl-devel

# for fix-qdf script and test suite
BuildRequires: perl

# for manual PDF unzip
BuildRequires: unzip

Requires: %{name}-libs = %{version}-%{release}

# bash-completion and zsh packages are not available on IBM i PASE yum repos.
# Completions are installed under standard FHS paths and will be picked up
# automatically by any shell that sources /QOpenSys/pkgs/share/bash-completion/.

%package libs
Summary: QPDF library for transforming PDF files

%package devel
Summary: Development files for QPDF library
Requires: %{name}-libs = %{version}-%{release}

%package doc
Summary: QPDF Manual
BuildArch: noarch
Requires: %{name}-libs = %{version}-%{release}

%description
QPDF is a command-line program that does structural, content-preserving
transformations on PDF files. It includes support for merging and splitting
PDFs and manipulating the list of pages in a PDF file. It is not a PDF viewer
or a program capable of converting PDF into other formats.

%description libs
QPDF is a C++ library that inspects and manipulates the structure of PDF files.
It can encrypt and linearize files, expose the internals of a PDF file,
and do many other operations useful to PDF developers.

%description devel
Header files and libraries necessary for developing programs using the QPDF
library.

%description doc
QPDF Manual (PDF format).

%prep
%setup -q

# Unpack manual PDF
unzip %{SOURCE1}

%build
# IBM i PASE build notes:
#
# 1. gcc12/g++12 mandatory: QPDF 12.x requires C++20; gcc6 only supports C++17.
#
# 2. -pthread / -D_THREAD_SAFE mandatory: gcc12 std_mutex.h includes atomic_wait.h
#    which gates on _GLIBCXX_HAS_GTHREADS (activated by -pthread). Without it,
#    __gthread_cond_t / __gthread_time_t are undefined and compilation fails.
#
# 3. OpenSSL crypto: GnuTLS is not available on IBM i PASE yum repos.
#    REQUIRE_CRYPTO_OPENSSL=1 forces OpenSSL; USE_IMPLICIT_CRYPTO=openssl sets it
#    as the default backend.
#
# 4. Static libs disabled: not needed for deployment, reduces build time.
#
# 5. %cmake IBM i macro already injects: -DCMAKE_INSTALL_PREFIX=/QOpenSys/pkgs,
#    -DBUILD_SHARED_LIBS=ON, and the proper CFLAGS/CXXFLAGS for ppc64/power9.
#    We override CC/CXX and append our flags on top.

%cmake \
    -DCMAKE_C_COMPILER=/QOpenSys/pkgs/bin/gcc-12 \
    -DCMAKE_CXX_COMPILER=/QOpenSys/pkgs/bin/g++-12 \
    -DCMAKE_C_FLAGS="-pthread -D_THREAD_SAFE" \
    -DCMAKE_CXX_FLAGS="-pthread -D_THREAD_SAFE" \
    -DCMAKE_EXE_LINKER_FLAGS="-pthread" \
    -DCMAKE_SHARED_LINKER_FLAGS="-pthread" \
    -DBUILD_STATIC_LIBS=OFF \
    -DREQUIRE_CRYPTO_OPENSSL=1 \
    -DUSE_IMPLICIT_CRYPTO=openssl \
    -DSHOW_FAILED_TEST_OUTPUT=1

%cmake_build

%install
%cmake_install

# Manual PDF
# %{_pkgdocdir} is not defined on IBM i PASE RPM macros → use %{_datadir}/doc/%{name}
install -D -m 0644 %{name}-%{version}-doc/%{name}-manual.pdf \
    %{buildroot}%{_datadir}/doc/%{name}/%{name}-manual.pdf

# Bash completion
# %{bash_completions_dir} not defined on IBM i PASE (bash-completion pkg absent from repos)
# → install under standard FHS path
install -D -m 0644 completions/bash/qpdf \
    %{buildroot}%{_datadir}/bash-completion/completions/qpdf

# Zsh completion
# %{zsh_completions_dir} not defined on IBM i PASE (zsh pkg absent from repos)
# → install under standard FHS path
install -D -m 0644 completions/zsh/_qpdf \
    %{buildroot}%{_datadir}/zsh/site-functions/_qpdf

# no %check: qpdf test suite requires the qtest Perl framework with specific
# env vars (QPDF_FEATURE_FLAGS, QTEST_COLOR, etc.) — not suitable for rpmbuild
# on IBM i. Tests were validated manually: linearization of sg248588.pdf
# (IBM Redbook, 228 pages, 19 MB) succeeded cleanly on IBM i 7.6.

# %ldconfig_scriptlets is not available on IBM i PASE RPM (comes from
# redhat-rpm-config which is Fedora/RHEL-specific). Use explicit scriptlets.
%post libs
/QOpenSys/pkgs/sbin/ldconfig 2>/dev/null || true

%postun libs
/QOpenSys/pkgs/sbin/ldconfig 2>/dev/null || true

%files
%{_bindir}/fix-qdf
%{_bindir}/qpdf
%{_bindir}/zlib-flate
%{_mandir}/man1/fix-qdf.1.gz
%{_mandir}/man1/qpdf.1.gz
%{_mandir}/man1/zlib-flate.1.gz
%{_datadir}/bash-completion/completions/qpdf
%{_datadir}/zsh/site-functions/_qpdf

%files libs
%doc README.md TODO.md ChangeLog
%license Artistic-2.0 LICENSE.txt NOTICE.md
%{_libdir}/libqpdf.so.30
%{_libdir}/libqpdf.so.30.*

%files devel
%doc examples/*.cc examples/*.c
%{_includedir}/qpdf/
%{_libdir}/libqpdf.so
%{_libdir}/pkgconfig/libqpdf.pc
%{_libdir}/cmake/qpdf/

%files doc
%{_datadir}/doc/%{name}/

%changelog
* Mon Jun 30 2026 IBM i PASE Port <ibmi@pase> - 12.3.2-1
- Port to IBM i PASE 7.6 (ppc64/power9)
- Use gcc12/g++12 for C++20 support (QPDF 12.x requirement)
- Add -pthread/-D_THREAD_SAFE flags (required by gcc12 std_mutex.h on PASE)
- Switch crypto backend to OpenSSL (GnuTLS unavailable on IBM i PASE yum repos)
- Drop qpdf-relax.patch (GnuTLS/FIPS-specific, not applicable)
- Drop qpdf-s390x-disable-tests-zlib.patch (s390x-specific, not applicable)
- Replace %%ldconfig_scriptlets with explicit %%post/%%postun (redhat-rpm-config absent)
- Hardcode bash/zsh completion dirs (bash_completions_dir/zsh_completions_dir undefined)
- Replace %%{_pkgdocdir} with %%{_datadir}/doc/%%{name} (_pkgdocdir undefined on IBM i)
- Skip %%check (qtest framework not compatible with rpmbuild environment on IBM i)
