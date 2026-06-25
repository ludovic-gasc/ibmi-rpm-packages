# IBM i RPM Packages

Community RPM repository for IBM i / IBM Power, hosted on **GitHub Pages**.

| Repository URL | `https://ludovic-gasc.github.io/ibmi-rpm-packages/` |
|---|---|
| Architecture | `ppc64`, `noarch` |

---

## Quick install on IBM i

```bash
# 1. Download the .repo file
curl -o /QOpenSys/etc/yum/repos.d/ludovic-gasc-ibmi-rpm-packages.repo \
     https://ludovic-gasc.github.io/ibmi-rpm-packages/ludovic-gasc-ibmi-rpm-packages.repo

# 2. Refresh cache and install
yum makecache
yum install qpdf
```

---

## Available packages

| Package | Version | Architecture | Description | Spec file |
|---|---|---|---|---|
| `qpdf` | 12.3.2 | ppc64 | PDF manipulation tool | [`specs/qpdf-ibmi.spec`](specs/qpdf-ibmi.spec) |
| `qpdf-libs` | 12.3.2 | ppc64 | QPDF shared libraries | [`specs/qpdf-ibmi.spec`](specs/qpdf-ibmi.spec) |
| `qpdf-devel` | 12.3.2 | ppc64 | QPDF development headers | [`specs/qpdf-ibmi.spec`](specs/qpdf-ibmi.spec) |
| `qpdf-doc` | 12.3.2 | noarch | QPDF documentation | [`specs/qpdf-ibmi.spec`](specs/qpdf-ibmi.spec) |

---

## Contributing / Adding a package

### Locally

**Prerequisites** (Ubuntu/Debian):
```bash
sudo apt install rpm createrepo-c git
```

**Add one or more RPMs** (commits and pushes automatically):
```bash
./scripts/add-package.sh path/to/my-package.ppc64.rpm
```

The script will:
1. Copy the RPM to `packages/<arch>/`
2. Rebuild `repodata/` with `createrepo_c`
3. Commit and push to `main`
4. GitHub Actions deploys the updated site to GitHub Pages

**Manually rebuild without pushing**:
```bash
./scripts/build-repo.sh
```

---

## Repository structure

```
ibmi-rpm-packages/
├── packages/
│   ├── noarch/          ← Architecture-independent RPMs
│   └── ppc64/           ← IBM Power (IBM i) RPMs
├── repodata/            ← Generated metadata (repomd.xml, etc.)
├── specs/               ← RPM spec files (build recipes)
│   └── qpdf-ibmi.spec
├── scripts/
│   ├── build-repo.sh        ← Generate repodata
│   ├── add-package.sh       ← Add an RPM to the correct subdirectory
│   └── setup-and-publish.sh ← One-shot full initialisation
├── .github/
│   └── workflows/
│       └── publish.yml  ← GitHub Actions CI/CD
├── ludovic-gasc-ibmi-rpm-packages.repo  ← .repo file for yum/dnf on IBM i
└── README.md
```

---

## License

Apache 2.0 — © Ludovic Gasc
