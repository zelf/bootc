# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Personal bootable OCI container images for immutable Fedora desktops. Builds custom images for COSMIC, GNOME, and Niri desktop environments, plus a Fedora development toolbox. All images are published to `ghcr.io/zelf/*` and signed with Cosign.

## Building Images Locally

```bash
# Desktop images (requires podman or buildah)
podman build -f desktop/cosmic/Containerfile -t cosmic .
podman build -f desktop/gnome/Containerfile -t gnome .
podman build -f desktop/niri/Containerfile -t niri .

# Toolbox image
podman build -f toolbox/Containerfile.fedora -t fedora-toolbox .
```

Build context must be the repo root (Containerfiles COPY from `desktop/` and `toolbox/` paths).

There are no traditional build tools (no Makefile, Cargo.toml, or justfile). The only validation is `bootc container lint` which runs inside the Containerfile during build.

## Architecture

Four independent image variants, each with its own Containerfile and CI workflow:

| Variant | Base Image | Registry | Workflow Schedule |
|---------|-----------|----------|-------------------|
| `desktop/cosmic/` | `quay.io/fedora-ostree-desktops/cosmic-atomic:43` | `ghcr.io/zelf/cosmic` | Wed 08:05 UTC |
| `desktop/gnome/` | `quay.io/fedora-ostree-desktops/silverblue:43` | `ghcr.io/zelf/gnome` | Tue 08:05 UTC |
| `desktop/niri/` | `quay.io/fedora-ostree-desktops/sway-atomic:43` | `ghcr.io/zelf/niri` | Thu 08:05 UTC |
| `toolbox/` | `registry.fedoraproject.org/fedora-toolbox:43` | `ghcr.io/zelf/fedora-toolbox` | Mon 22:20 UTC |

### Desktop Image Structure

Shared config lives in `desktop/shared/` and is copied first; variant-specific overrides follow:

```
desktop/shared/
├── etc/                   # Config files shared by all desktop variants
├── usr/                   # Shared /usr files (kargs, etc.)
└── scripts/
    └── firewalld.sh       # Firewall rules (shared)

desktop/{variant}/
├── Containerfile          # Build definition
├── etc/                   # Variant-specific config overrides (gnome, niri)
├── scripts/               # Variant-specific build scripts
│   ├── cleanup.sh         # (cosmic/niri) Remove unwanted base packages
│   ├── install.sh         # Package installation (RPM Fusion, codecs, tools)
│   └── systemd.sh         # Service enablement, group setup
└── usr/                   # Variant-specific /usr files (gnome only)
```

Gnome-only files: `etc/containers/storage.conf`, `usr/lib/ostree/prepare-root.conf`, `usr/libexec/zelf-groups`. Niri has `etc/niri/config.kdl` (system-wide default niri config for Noctalia Shell).

### Containerfile Build Pattern

Desktop images COPY shared configs first, then variant-specific overrides, and chain scripts with `ostree container commit` between steps:

```dockerfile
COPY desktop/shared/etc /etc
COPY desktop/shared/usr /usr
COPY desktop/{variant}/etc /etc       # variant overrides (gnome, niri)
COPY desktop/{variant}/usr /usr       # variant overrides (gnome only)
COPY desktop/shared/scripts/*.sh /usr/local/bin/
COPY desktop/{variant}/scripts/*.sh /usr/local/bin/
RUN bash /usr/local/bin/install.sh && ostree container commit && \
    bash /usr/local/bin/systemd.sh && \
    bash /usr/local/bin/firewalld.sh && ostree container commit
RUN bootc container lint
```

Required bootc labels and init config:
```dockerfile
LABEL containers.bootc="1" ostree.bootable="1"
STOPSIGNAL SIGRTMIN+3
CMD ["/sbin/init"]
```

### Toolbox Image

Simpler structure: single Containerfile with a `packages.fedora` file listing packages (comments with `#`, blank lines ignored). Uses `dnf` (not `dnf5`). Includes distrobox host-exec symlinks.

## Conventions

- Shell scripts use `#!/usr/bin/env bash` and `set -euo pipefail`
- Desktop images use `dnf5`; the toolbox uses `dnf`
- Config file naming uses numeric prefixes for ordering (e.g., `20-high-swappiness.conf`)
- RPM Fusion is installed in all variants for freeworld codec/driver support
- `install_weak_deps=False` is set to minimize image size
- Image tags: `latest`, `43` (Fedora version), and `YYYYMMDD` (timestamp)

## CI/CD

GitHub Actions workflows in `.github/workflows/`. All workflows:
- Use `redhat-actions/buildah-build` for OCI builds
- Sign images with Cosign using `SIGNING_SECRET` repository secret
- Use `Wandalen/wretry.action` for retries on flaky network operations
- Tag with `latest`, Fedora version, and date stamp
- The toolbox workflow also runs on PRs (build-only, no push/sign)
