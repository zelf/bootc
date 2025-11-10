# COSMIC Desktop Bootc Image - Review and TODO

Review conducted: 2025-11-10
Last updated: 2025-11-10

## Executive Summary

This COSMIC Desktop bootc image has several strengths (excellent container security, modern tooling, performance tuning) but could benefit from adopting more Fedora Atomic Desktop standards from workstation-ostree-config to improve maintainability, modularity, and multi-architecture support.

**Note**: This image is specifically designed for AMD x86_64 systems only. Multi-architecture support is not a priority.

---

## Implementation Status

### Completed Quick Wins (2025-11-10)

#### ✅ Added README.md
- Comprehensive documentation of build process, features, and configuration
- Architecture notes (AMD x86_64 only)
- Directory structure overview
- Building, testing, and deployment instructions
- Troubleshooting section
- Location: `desktop/cosmic/README.md`

#### ✅ Added Inline Documentation to Scripts
- `scripts/install.sh`: Detailed comments for each package section
  - Header with purpose, phase, platform notes
  - Section separators for COSMIC, repositories, multimedia, utilities, ROCm, virtualization, cleanup
  - Inline comments for each package explaining its purpose
- `scripts/systemd.sh`: Documentation of service enables
  - Header with purpose and phase information
  - Section separators for network, power, containers, security
  - References to preset file
- `scripts/firewalld.sh`: Documentation of firewall hardening
  - Header with purpose and rationale
  - Instructions for re-enabling SSH if needed

#### ✅ Created Systemd Preset File
- New file: `etc/systemd/system-preset/80-cosmic-desktop.preset`
- Declarative service configuration for:
  - tailscaled.service (VPN)
  - tuned.service (power management)
  - podman-auto-update.service and .timer (container updates)
- Updated systemd.sh to reference preset file
- Note: Script keeps explicit enables for bootc image building

#### ✅ Reorganized install.sh with Logical Groups
- Clear section headers using comment dividers
- Organized into logical groups:
  1. COSMIC Desktop Environment
  2. Third-Party Repositories
  3. Multimedia Support
  4. System Utilities and CLI Tools
  5. AMD GPU Computing (ROCm Stack)
  6. Virtualization Stack
  7. Package Cleanup
- Each section has descriptive comments
- Inline comments for individual packages

#### ✅ Updated GitHub Actions CI
- Enhanced `.github/workflows/cosmic.yaml`:
  - Added pull_request trigger for validation (builds but doesn't push)
  - Added `bootc container lint` validation step after build
  - Updated image description to be more descriptive
  - Fixed README URL to point to cosmic-specific README
  - Made push and signing steps conditional (only on schedule/workflow_dispatch)
  - Added comments to document workflow triggers

---

## What's Missing

### 1. Modular Configuration Structure
- **Standard approach**: Uses layered YAML manifests (`cosmic.yaml` → `cosmic-common.yaml` → `common.yaml` → `base-atomic.yaml`)
- **Your approach**: Single Containerfile with inline scripts
- **Impact**: Harder to share configuration across variants or reuse base components

### 2. Separated Package Lists
- **Standard**: Packages organized in `packages/common.yaml`, `packages/cosmic.yaml` with auto-generated sync from Fedora comps
- **Your approach**: All packages mixed in `install.sh`
- **Impact**: Difficult to track what's desktop-specific vs. base system vs. development tools

### 3. Architecture-Specific Package Handling
- **Standard**: Explicit `packages-x86_64` and `packages-aarch64` sections
- **Your approach**: No architecture differentiation (AMD-specific ROCm packages will fail on ARM)
- **Impact**: Image won't build properly on non-AMD architectures

### 4. System Module Configurations
Missing several standard atomic desktop configurations:
- `bootupd` configuration (bootloader update management)
- `composefs` enablement (filesystem feature)
- `kernel-install` configuration
- `sysroot-ro` explicit read-only root setup

### 5. Systemd Presets ✅ (Completed)
- **Standard**: Uses systemd preset files (`.preset`) to enable/disable services declaratively
- **Previous approach**: Manual `systemctl enable` commands in script
- **Impact**: Less declarative, harder to audit enabled services
- **Status**: Now using `etc/systemd/system-preset/80-cosmic-desktop.preset`

### 6. Desktop-Specific Post-Processing
Missing COSMIC-specific customizations found in other variants:
- Initial setup configuration (skip certain pages)
- Default settings overrides
- Extension/plugin pre-configuration
- Vendor configuration files

### 7. User/Group Definitions
- **Standard**: `passwd` and `group` files defining system users
- **Your approach**: Hardcoded UID 1000 in quadlet file
- **Impact**: Brittle user assumptions

### 8. Build Automation
- **Standard**: `justfile` with commands like `just compose variant=cosmic`
- **Your approach**: Manual container build
- **Impact**: No standardized build/test/validate workflow

### 9. CI/CD Configuration ✅ (Completed)
- **Standard**: `.zuul.yaml`, GitLab CI for automated testing
- **Previous approach**: Basic GitHub Actions workflow
- **Impact**: Limited validation on changes
- **Status**: Enhanced `.github/workflows/cosmic.yaml` with PR validation and bootc lint

### 10. Documentation ✅ (Completed)
- **Standard**: Comprehensive README with build instructions, testing, maintenance
- **Previous approach**: None
- **Impact**: Hard for others (or future you) to understand structure
- **Status**: Created comprehensive `README.md` with full documentation

### 11. Version Metadata
- **Standard**: Includes edition year, version prefixes (timestamp-based)
- **Your approach**: No version tracking
- **Impact**: Difficult to track image generations

---

## What Could Be Improved

### 1. Package Organization (High Priority)
Split `install.sh` into logical categories:

```
packages/
├── base.yaml           # Core system packages
├── desktop.yaml        # COSMIC and display stack
├── multimedia.yaml     # FFmpeg, codecs, drivers
├── development.yaml    # Android tools, vim, just
├── virtualization.yaml # libvirt stack
├── amd-gpu.yaml        # ROCm stack (x86_64 only)
└── utilities.yaml      # btop, bat, fzf, etc.
```

### 2. Architecture Awareness
Add conditional package installation:

```bash
# Example improvement for install.sh
ARCH=$(uname -m)
if [ "$ARCH" = "x86_64" ]; then
    # Install AMD ROCm stack
    dnf install -y rocminfo rocm-opencl ...
fi
```

### 3. Service Management with Presets
Instead of `systemd.sh`, create `/usr/lib/systemd/system-preset/80-cosmic.preset`:

```ini
# Enable container updates
enable podman-auto-update.service
enable podman-auto-update.timer

# Enable VPN
enable tailscaled.service

# Enable tuned
enable tuned.service
```

### 4. COSMIC-Specific Configuration
Add desktop environment customizations:

```bash
# etc/cosmic/default-settings/
# - Keybindings
# - Theme preferences
# - Default applications
# - Panel configuration
```

### 5. Repository Management
Create proper repo definitions instead of Copr commands:

```bash
# etc/yum.repos.d/cosmic.repo
[cosmic-epoch]
name=COSMIC Desktop
baseurl=https://download.copr.fedorainfracloud.org/results/ryanabx/cosmic-epoch/fedora-$releasever-$basearch/
gpgcheck=1
enabled=1
```

### 6. Distrobox Integration Improvements
Your quadlet is good but could be enhanced:

```diff
+ [Unit]
+ Description=Fedora Development Toolbox
+ Documentation=https://github.com/zelf/fedora-toolbox
+
  [Container]
  Image=ghcr.io/zelf/fedora-toolbox:latest
  AutoUpdate=registry
+ Pull=newer
+
+ [Container]
+ # Add volume for persistent cargo/npm cache
+ Volume=%h/.cargo:/home/%u/.cargo:Z
+ Volume=%h/.npm:/home/%u/.npm:Z
```

### 7. Security Enhancements

**Add SELinux post-processing:**
```bash
# scripts/selinux.sh
# Set proper labels for custom paths
# Verify no policy violations
```

**Add user systemd service hardening:**
```ini
# etc/systemd/user.conf.d/hardening.conf
[Manager]
DefaultLimitNOFILE=524288
DefaultLimitNPROC=4096
```

### 8. Firmware Management
Add explicit firmware package handling:

```bash
# For better hardware support
dnf install -y \
    linux-firmware \
    firmware-manager \
    fwupd
```

### 9. Cleanup and Documentation
Add inline documentation to scripts:

```bash
#!/usr/bin/env bash
# Purpose: Install COSMIC Desktop and dependencies
# Phase: 1 of 3 (Package Installation)
# Commit: Creates ostree commit after completion

set -xeuo pipefail
```

### 10. Testing Framework
Add validation script:

```bash
# scripts/validate.sh
#!/usr/bin/env bash
# Verify:
# - COSMIC packages installed
# - Services enabled correctly
# - Container signature verification working
# - Distrobox can start
```

### 11. Initramfs Configuration
Add dracut configuration for COSMIC requirements:

```bash
# etc/dracut.conf.d/cosmic.conf
hostonly=no
compress="zstd -19"
add_dracutmodules+=" dm crypt plymouth "
```

### 12. Better ZRAM Configuration
Your ZRAM setup is aggressive; consider making it adaptive:

```ini
# etc/systemd/zram-generator.conf
[zram0]
compression-algorithm=zstd
zram-size=min(ram, 8192)  # Cap at 8GB
swap-priority=100
```

---

## Alignment Recommendations

### Short-term (Quick Wins)
- [x] Add README.md documenting build process
- [x] Split packages into logical groups in install.sh
- [x] Create systemd preset file
- [x] Add inline documentation to scripts
- [x] Improve GitHub Actions CI (added validation, PR triggers)
- [ ] Add architecture detection for ROCm (skipped - AMD x86_64 only by design)

### Medium-term (Structural)
- [ ] Create modular manifest structure (YAML-based)
- [ ] Implement proper repository definitions
- [ ] Add COSMIC-specific post-processing
- [ ] Create validation/testing scripts
- [ ] Add justfile for build automation

### Long-term (Infrastructure)
- [ ] Implement comps synchronization
- [ ] Add CI/CD pipeline
- [ ] Create multi-architecture builds
- [ ] Version tracking and release process
- [ ] Automated security scanning

---

## Strengths of Current Setup

Your configuration has several notable strengths:
- ✨ **Excellent container security**: Signature verification with Sigstore is exemplary
- ✨ **Modern tools**: Quadlet, distrobox integration is well done
- ✨ **Performance tuning**: ZRAM configuration shows attention to detail
- ✨ **Developer focus**: ROCm, virtualization, container tools well integrated
- ✨ **Hardware support**: ZSA keyboard rules show user-centric customization

---

## Reference

Based on comparison with Fedora workstation-ostree-config repository:
- Repository: https://pagure.io/workstation-ostree-config/tree/main
- Standard variants: Silverblue (GNOME), Kinoite (KDE), Sway Atomic, Budgie Atomic, COSMIC Atomic (in development)
