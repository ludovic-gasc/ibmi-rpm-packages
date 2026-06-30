# IBM i RPM Packages

Community RPM repository for IBM i / IBM Power, hosted on **GitHub Pages**.  
Two separate repositories are provided — one per IBM i OS version — because binaries are **not** cross-compatible between versions.

| | IBM i 7.6 | IBM i 7.4 |
|---|---|---|
| **Base URL** | `https://ludovic-gasc.github.io/ibmi-rpm-packages/ibmi/7.6/` | `https://ludovic-gasc.github.io/ibmi-rpm-packages/ibmi/7.4/` |
| **Architecture** | `ppc64` (Power9), `noarch` | `ppc64` (Power8), `noarch` |
| **.repo file** | `ludovic-gasc-ibmi-rpm-packages-76.repo` | `ludovic-gasc-ibmi-rpm-packages-74.repo` |

---

## Quick install on IBM i

### IBM i 7.6

```bash
# 1. Download the .repo file
curl -o /QOpenSys/etc/yum/repos.d/ludovic-gasc-ibmi-rpm-packages-76.repo \
     https://ludovic-gasc.github.io/ibmi-rpm-packages/ibmi/7.6/ludovic-gasc-ibmi-rpm-packages-76.repo

# 2. Refresh cache and install
yum makecache
yum install qpdf
```

### IBM i 7.4

```bash
# 1. Download the .repo file
curl -o /QOpenSys/etc/yum/repos.d/ludovic-gasc-ibmi-rpm-packages-74.repo \
     https://ludovic-gasc.github.io/ibmi-rpm-packages/ibmi/7.4/ludovic-gasc-ibmi-rpm-packages-74.repo

# 2. Refresh cache and install
yum makecache
yum install qpdf
```

---

## Available packages

### IBM i 7.6 (ppc64 / Power9)

| Package | Version | Architecture | Description | Spec file |
|---|---|---|---|---|
| `qpdf` | 12.3.2 | ppc64 | PDF manipulation tool | [`specs/qpdf-ibmi7.6.spec`](specs/qpdf-ibmi7.6.spec) |
| `qpdf-libs` | 12.3.2 | ppc64 | QPDF shared libraries | [`specs/qpdf-ibmi7.6.spec`](specs/qpdf-ibmi7.6.spec) |
| `qpdf-devel` | 12.3.2 | ppc64 | QPDF development headers | [`specs/qpdf-ibmi7.6.spec`](specs/qpdf-ibmi7.6.spec) |
| `qpdf-doc` | 12.3.2 | noarch | QPDF documentation | [`specs/qpdf-ibmi7.6.spec`](specs/qpdf-ibmi7.6.spec) |

### IBM i 7.4 (ppc64 / Power8)

| Package | Version | Architecture | Description | Spec file |
|---|---|---|---|---|
| `qpdf` | 12.3.2 | ppc64 | PDF manipulation tool | [`specs/qpdf-ibmi7.4.spec`](specs/qpdf-ibmi7.4.spec) |
| `qpdf-libs` | 12.3.2 | ppc64 | QPDF shared libraries | [`specs/qpdf-ibmi7.4.spec`](specs/qpdf-ibmi7.4.spec) |
| `qpdf-devel` | 12.3.2 | ppc64 | QPDF development headers | [`specs/qpdf-ibmi7.4.spec`](specs/qpdf-ibmi7.4.spec) |
| `qpdf-doc` | 12.3.2 | noarch | QPDF documentation | [`specs/qpdf-ibmi7.4.spec`](specs/qpdf-ibmi7.4.spec) |

---

## Contributing / Adding a package

### Prerequisites (WSL2 Ubuntu / Debian)

```bash
sudo apt install createrepo-c git
```

### Add RPMs to a specific version

```bash
# IBM i 7.6
./scripts/add-package.sh --version 7.6 path/to/my-package.ppc64.rpm

# IBM i 7.4
./scripts/add-package.sh --version 7.4 path/to/my-package.ppc64.rpm
```

The script will:
1. Copy the RPM to `ibmi/<version>/packages/<arch>/`
2. Rebuild `ibmi/<version>/repodata/` with `createrepo_c`
3. Commit and push to `main`
4. GitHub Actions deploys the updated site to GitHub Pages

### Rebuild metadata without pushing

```bash
./scripts/build-repo.sh          # rebuild all versions
./scripts/build-repo.sh 7.6      # rebuild only 7.6
./scripts/build-repo.sh 7.4      # rebuild only 7.4
```

---

## Repository structure

```
ibmi-rpm-packages/
├── ibmi/
│   ├── 7.6/
│   │   ├── packages/
│   │   │   ├── noarch/          ← Architecture-independent RPMs (IBM i 7.6)
│   │   │   └── ppc64/           ← IBM Power9 RPMs (IBM i 7.6)
│   │   ├── repodata/            ← Generated metadata (repomd.xml, etc.)
│   │   └── ludovic-gasc-ibmi-rpm-packages-76.repo
│   └── 7.4/
│       ├── packages/
│       │   ├── noarch/          ← Architecture-independent RPMs (IBM i 7.4)
│       │   └── ppc64/           ← IBM Power8 RPMs (IBM i 7.4)
│       ├── repodata/            ← Generated metadata (repomd.xml, etc.)
│       └── ludovic-gasc-ibmi-rpm-packages-74.repo
├── specs/
│   ├── qpdf-ibmi7.6.spec        ← Build recipe for IBM i 7.6
│   └── qpdf-ibmi7.4.spec        ← Build recipe for IBM i 7.4
├── scripts/
│   ├── build-repo.sh            ← Generate repodata (all or specific version)
│   ├── add-package.sh           ← Add an RPM to the correct version subdirectory
│   └── setup-and-publish.sh     ← One-shot full initialisation
├── .github/
│   └── workflows/
│       └── publish.yml          ← GitHub Actions CI/CD
└── index.html                   ← Public landing page
```

---

## License

Apache 2.0 — © Ludovic Gasc
