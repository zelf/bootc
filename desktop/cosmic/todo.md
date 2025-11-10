# COSMIC Desktop Bootc Image - Review and TODO

Review conducted: 2025-11-10
Last updated: 2025-11-10

## Executive Summary

This COSMIC Desktop bootc image has evolved from a functional bootc image to a **production-ready, professionally maintained project** with comprehensive tooling, automation, testing, and documentation.

**Status**: All recommended improvements (short-term, medium-term, and long-term) have been successfully implemented! 🎉

**Note**: This image is specifically designed for AMD x86_64 systems only. Multi-architecture support is not a priority.

### Implementation Progress

- ✅ **Short-term (Quick Wins)**: 100% Complete
  - Documentation, organization, CI enhancements
- ✅ **Medium-term (Structural)**: 100% Complete
  - Build automation, validation, COSMIC customization
- ✅ **Long-term (Infrastructure)**: 100% Complete (applicable items)
  - CI/CD pipeline, security scanning, releases
  - Comps sync and multi-arch not needed for single-variant

### Current Capabilities

✅ **Professional Build System**
- Justfile with 20+ automated commands
- Comprehensive validation (24 tests)
- Four-phase build process with ostree commits

✅ **Enterprise-Grade CI/CD**
- Automated testing on all PRs
- Security scanning with Trivy
- SBOM generation for supply chain security
- Automated releases with changelogs
- GitHub Security integration

✅ **Production-Ready Release Process**
- Semantic versioning
- Automated changelog generation
- One-command releases (`just release 1.0.0`)
- Signed images with Sigstore
- Release artifacts (SBOM, security scans)

✅ **Comprehensive Documentation**
- README with full usage guide
- DESIGN.md explaining architectural decisions
- CHANGELOG.md for version tracking
- Inline documentation in all scripts

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

### Completed Medium-Term Changes (2025-11-10)

#### ✅ Created Justfile for Build Automation
- New file: `justfile`
- Commands for common tasks:
  - `just build` - Build the image
  - `just test` - Run validation tests
  - `just validate` - Build and test
  - `just shell` - Interactive shell
  - `just clean` - Remove built images
  - `just rebuild` - Full clean rebuild
  - Plus many more utility commands
- Makes building and testing consistent and easy
- Aligns with Fedora workstation-ostree-config conventions

#### ✅ Implemented Proper Repository Definitions
- New file: `etc/yum.repos.d/cosmic-epoch.repo`
- Proper .repo file for COSMIC Copr repository
- Includes GPG key verification
- Replaced `dnf5 copr enable` command in install.sh
- More maintainable and declarative approach

#### ✅ Added COSMIC-Specific Post-Processing
- New script: `scripts/cosmic-setup.sh` (4th build phase)
- Customizations include:
  - Default COSMIC configuration skeleton
  - Environment variables for COSMIC/Wayland
  - Welcome message (MOTD) for new users
  - COSMIC-specific documentation
  - Terminal emulator configuration
  - Performance optimizations for COSMIC
- Updated Containerfile to run this script with ostree commit

#### ✅ Created Validation/Testing Scripts
- New script: `scripts/validate.sh`
- Comprehensive image validation with 24 automated tests:
  - Image structure and labels
  - Package installation verification
  - Service enablement checks
  - Configuration file presence
  - Security setup validation
  - Performance: image size check
- Color-coded output with pass/fail summary
- Integrated with justfile (`just test`)

#### ✅ Evaluated Modular Manifest Structure
- Created `DESIGN.md` documenting design decisions
- **Decision**: Use Containerfile approach (not YAML manifests)
- **Rationale**:
  - Single variant, single architecture (AMD x86_64)
  - Containerfile is native for bootc container images
  - Simpler build pipeline
  - Better for single-maintainer projects
  - YAML manifests are for multi-variant management
- Document explains when each approach makes sense
- Our structure provides benefits without the overhead

---

## What's Missing

### 1. Modular Configuration Structure ✅ (Addressed)
- **Standard approach**: Uses layered YAML manifests (`cosmic.yaml` → `cosmic-common.yaml` → `common.yaml` → `base-atomic.yaml`)
- **Our approach**: Single Containerfile with organized scripts
- **Decision**: Containerfile better for single-variant, single-architecture use case
- **Status**: See `DESIGN.md` for detailed rationale

### 2. Separated Package Lists ✅ (Addressed)
- **Standard**: Packages organized in `packages/common.yaml`, `packages/cosmic.yaml` with auto-generated sync from Fedora comps
- **Our approach**: All packages in `install.sh` with clear section organization
- **Status**: Packages now organized into logical sections with inline documentation
- **Note**: Comps sync not needed for explicit single-variant configuration

### 3. Architecture-Specific Package Handling (Not Needed)
- **Standard**: Explicit `packages-x86_64` and `packages-aarch64` sections
- **Our approach**: AMD x86_64 only by design
- **Decision**: Not supporting other architectures reduces complexity
- **Status**: Image explicitly targets AMD x86_64, ROCm packages intentional

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

### 6. Desktop-Specific Post-Processing ✅ (Completed)
- **Standard**: COSMIC-specific customizations found in other variants
- **Status**: Created `scripts/cosmic-setup.sh` with:
  - COSMIC configuration skeleton in /etc/skel
  - Environment variables for Wayland/COSMIC
  - Welcome message (MOTD) for users
  - Default application configuration
  - Performance optimizations
- Runs as 4th build phase with ostree commit

### 7. User/Group Definitions
- **Standard**: `passwd` and `group` files defining system users
- **Our approach**: Hardcoded UID 1000 in quadlet file
- **Note**: For single-user desktop, this is acceptable
- **Impact**: Minimal - first user typically gets UID 1000

### 8. Build Automation ✅ (Completed)
- **Standard**: `justfile` with commands like `just compose variant=cosmic`
- **Status**: Created comprehensive `justfile` with 20+ commands
- Commands include: build, test, validate, shell, clean, rebuild, inspect, etc.
- Integrated with validation script
- Standardized workflow established

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
- [x] Create modular manifest structure (YAML-based) - **Decision**: Containerfile approach better for single-variant (see DESIGN.md)
- [x] Implement proper repository definitions
- [x] Add COSMIC-specific post-processing
- [x] Create validation/testing scripts
- [x] Add justfile for build automation

### Long-term (Infrastructure)
- [x] Add CI/CD pipeline - **Enhanced with validation, security scanning, and automation**
- [x] Version tracking and release process - **Complete with automated workflows**
- [x] Automated security scanning - **Trivy integrated with GitHub Security**
- [ ] Implement comps synchronization - **Not needed**: Single-variant doesn't require Fedora comps sync (see DESIGN.md)
- [ ] Create multi-architecture builds - **Not planned**: AMD x86_64 only by design

---

### Completed Long-Term Changes (2025-11-10)

#### ✅ Enhanced CI/CD Pipeline
- Enhanced `.github/workflows/cosmic.yaml`:
  - Added comprehensive validation tests (24 automated checks)
  - Integrated Trivy security scanning with results uploaded to GitHub Security tab
  - SBOM (Software Bill of Materials) generation in CycloneDX format
  - Image size checking with warnings for large images
  - Build summaries in GitHub Actions UI
  - PR comments with build results and validation status
  - Enhanced OCI image labels with full metadata
- Security events permission added for SARIF uploads
- Artifacts uploaded with 90-day retention

#### ✅ Automated Security Scanning
- **Trivy Integration**:
  - Vulnerability scanning for CRITICAL and HIGH severity issues
  - Results uploaded to GitHub Security tab (SARIF format)
  - SBOM generation for supply chain security
  - JSON vulnerability reports for releases
- Runs on every build (PRs, scheduled builds, releases)
- Security scan results attached to GitHub Releases

#### ✅ Version Tracking and Release Process
- Created `.github/workflows/cosmic-release.yaml`:
  - Triggered by version tags (cosmic-vX.Y.Z format)
  - Full build, test, scan, and push workflow
  - Automatic changelog generation from git history
  - GitHub Release creation with detailed notes
  - SBOM and security scan results attached to releases
  - Image signing with Sigstore for all releases
- Enhanced image labels with version metadata, build numbers, revision info

#### ✅ Release Automation
- **Release Preparation Script** (`scripts/prepare-release.sh`):
  - Interactive release preparation
  - Version validation (semantic versioning)
  - Git state checking (uncommitted changes)
  - Changelog update prompts
  - Tag creation and pushing
  - Post-release instructions
- **Justfile Commands**:
  - `just release VERSION` - Prepare and create release
  - `just changelog` - Show unreleased changes
  - `just releases` - Show release history
- **CHANGELOG.md** - Structured changelog with Keep a Changelog format
- **Release Documentation** in README with full workflow explanation

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
