# COSMIC Desktop Bootc Image

A custom bootc-based COSMIC Desktop image for Fedora 42, optimized for AMD x86_64 systems with developer tooling, multimedia support, and container-first workflows.

## Overview

This image provides:
- **COSMIC Desktop** - System76's Rust-based desktop environment (via ryanabx/cosmic-epoch Copr)
- **AMD GPU Support** - Complete ROCm stack for GPU computing (OpenCL, HIP runtime)
- **Full Multimedia** - Hardware-accelerated codecs, FFmpeg, RPM Fusion repositories
- **Developer Tools** - Distrobox, Podman, virtualization, development utilities
- **Container Security** - Sigstore signature verification for personal registry
- **Performance Tuning** - ZRAM swap with aggressive memory optimization

## Architecture

**Target Platform**: AMD x86_64 only

This image is specifically designed and tested for AMD x86_64 systems. The ROCm GPU computing stack and certain optimizations are AMD/x86_64-specific.

## Building

### Prerequisites
- Podman or Docker
- AMD x86_64 system (for local testing)
- `just` command runner (optional, but recommended)

### Quick Start with Justfile

The easiest way to build and test:

```bash
cd /home/zelf/projects/bootc/desktop/cosmic

# Build the image
just build

# Build and run all validation tests
just validate

# See all available commands
just --list
```

### Manual Build Command

```bash
cd /home/zelf/projects/bootc
podman build -t ghcr.io/zelf/cosmic:latest -f desktop/cosmic/Containerfile .
```

### Build Process

The build follows a four-phase approach with ostree commits after each phase:

1. **Package Installation** (`install.sh`)
   - Installs COSMIC Desktop from Copr repository
   - Installs desktop environment, multimedia, and development tools
   - Configures AMD ROCm GPU support
   - Adds RPM Fusion repositories

2. **Service Configuration** (`systemd.sh`)
   - Enables system services (Tailscale, tuned, podman-auto-update)
   - Secures container systemd directories

3. **Firewall Hardening** (`firewalld.sh`)
   - Removes SSH from firewall (security hardening)

4. **COSMIC Customization** (`cosmic-setup.sh`)
   - Sets up COSMIC-specific defaults
   - Configures environment variables for Wayland
   - Creates welcome message and documentation

## Features

### Container Security

This image enforces strict container signature verification:
- **Default policy**: REJECT all unsigned containers
- **Exception**: `ghcr.io/zelf` registry with Sigstore verification
- **Public key**: `/etc/pki/containers/zelf.pub` (ECDSA P-256)

See `etc/containers/policy.json` for details.

### Distrobox Integration

Includes pre-configured Fedora toolbox via Quadlet:
- **Image**: `ghcr.io/zelf/fedora-toolbox:latest`
- **Auto-update**: Enabled from registry
- **Integration**: Full host filesystem access, user namespace mapping
- **Location**: `etc/containers/systemd/users/1000/fedora-distrobox-quadlet.container`

### Memory Optimization

Aggressive ZRAM configuration for improved performance:
- **ZRAM size**: 2x physical RAM
- **Compression**: zstd
- **Swappiness**: 180 (optimized for compressed swap)
- **Page cluster**: 0 (disabled readahead for ZRAM/SSD)

See `etc/systemd/zram-generator.conf` and `etc/sysctl.d/`.

### Hardware Support

- **ZSA Keyboards**: USB rules for Moonlander, Ergodox EZ, Planck EZ, Voyager
- **AMD GPUs**: Full ROCm stack with OpenCL and HIP support
- **Virtualization**: Complete libvirt stack with PolicyKit rules for wheel group

## Directory Structure

```
desktop/cosmic/
├── Containerfile                    # Main build definition
├── justfile                         # Build automation commands
├── README.md                        # This file
├── DESIGN.md                        # Design decisions and rationale
├── todo.md                          # Implementation tracking and roadmap
├── scripts/                         # Build-time installation scripts
│   ├── install.sh                  # Package installation (phase 1)
│   ├── systemd.sh                  # Service configuration (phase 2)
│   ├── firewalld.sh                # Firewall hardening (phase 3)
│   ├── cosmic-setup.sh             # COSMIC customization (phase 4)
│   └── validate.sh                 # Image validation tests
├── etc/                            # System configuration overlay
│   ├── containers/                 # Container security and Quadlet configs
│   ├── dnf/                        # Package manager configuration
│   ├── sysctl.d/                   # Kernel parameter tuning
│   ├── systemd/                    # ZRAM and service configs
│   │   └── system-preset/         # Systemd preset files
│   ├── yum.repos.d/                # Repository definitions
│   ├── polkit-1/                   # PolicyKit rules
│   ├── profile.d/                  # Shell environment
│   └── udev/                       # Hardware rules
└── usr/                            # (Reserved for future use)
```

## Configuration

### DNF/RPM-OSTree

Package manager is configured for minimal installations:
- Weak dependencies disabled (`install_weak_deps=False`)
- Recommended packages disabled (`Recommends=false`)

See `etc/dnf/dnf.conf` and `etc/rpm-ostreed.conf`.

### Firewall

SSH service is removed from the firewall by default for security. To re-enable:

```bash
sudo firewall-cmd --permanent --add-service=ssh
sudo firewall-cmd --reload
```

### Virtualization

Members of the `wheel` group can manage libvirt without password prompts for local, active sessions. See `etc/polkit-1/rules.d/80-libvirt-manage.rules`.

## Installed Software

### Desktop Environment
- COSMIC Desktop (from Copr)
- Display managers and session components

### Multimedia
- FFmpeg with full codec support
- Hardware-accelerated video drivers (Mesa VA/VDPAU freeworld)
- OpenH264 codec
- Sound and video applications

### Development Tools
- android-tools, vim, just
- btop, lm_sensors (monitoring)
- nmap-ncat, tailscale (networking)
- distrobox, podman-compose (containers)
- bat, fzf, pv (CLI utilities)
- zstd (compression)

### AMD GPU Computing
- rocminfo, rocm-opencl, rocm-clinfo
- rocm-smi, rocm-hip
- ocl-icd (OpenCL ICD loader)

### Virtualization
- Complete virtualization group (libvirt, virt-manager, QEMU, etc.)

## Customization

### Adding Packages

Edit `scripts/install.sh` and rebuild the image. Packages are organized into logical sections with comments.

### Modifying Services

Edit `scripts/systemd.sh` or add systemd preset files to `etc/systemd/system-preset/`.

### User Configuration

User-specific configurations can be added to:
- `etc/profile.d/` - Shell environment
- `etc/containers/systemd/users/1000/` - Per-user Quadlet containers

## Testing

### Automated Validation

The image includes comprehensive validation tests:

```bash
# Run all validation tests (24 automated checks)
just test

# Or run directly
./scripts/validate.sh ghcr.io/zelf/cosmic:latest
```

The validation script checks:
- Image structure and bootc labels
- Package installation (COSMIC, ROCm, multimedia, etc.)
- Service configuration
- Security setup (signature verification, firewall)
- Configuration files presence
- Image size and performance

### Manual Testing

```bash
# Run bootc container lint
just lint
# or: podman run --rm ghcr.io/zelf/cosmic:latest bootc container lint

# Interactive shell in the image
just shell
# or: podman run --rm -it ghcr.io/zelf/cosmic:latest /bin/bash

# Check ostree commits
podman run --rm ghcr.io/zelf/cosmic:latest ostree log fedora/stable/x86_64/cosmic

# Inspect image metadata
just inspect
```

## Deployment

### Install to Physical System

```bash
# Boot from Fedora live media, then:
sudo bootc install --image cosmic-desktop:latest
```

### Update Existing System

```bash
# On a system running this image:
sudo bootc upgrade
sudo systemctl reboot
```

## Notes

- **Firefox**: The RPM version is removed in favor of the Flatpak version
- **Tuned**: Enabled for automatic power management and performance tuning
- **Podman Auto-Update**: Containers with `AutoUpdate=registry` will update daily
- **Man Pages**: Rendered with syntax highlighting via `bat`

## Maintenance

### Updating COSMIC Desktop

The COSMIC Desktop packages come from the ryanabx/cosmic-epoch Copr repository. Updates are pulled during image rebuilds.

### Updating Base Image

The base image is `quay.io/fedora/fedora-bootc:42`. Rebuild regularly to pull updates:

```bash
# Using justfile (recommended)
just rebuild

# Or manually
podman pull quay.io/fedora/fedora-bootc:42
cd /home/zelf/projects/bootc
podman build --no-cache -t ghcr.io/zelf/cosmic:latest -f desktop/cosmic/Containerfile .
```

### Check for Updates

```bash
# Check if base image has updates
just check-updates
```

## Troubleshooting

### ROCm Not Working

Verify you have an AMD GPU and the correct drivers:

```bash
rocminfo
rocm-smi
```

### Distrobox Won't Start

Check the quadlet unit status:

```bash
systemctl --user status fedora-distrobox-quadlet.service
journalctl --user -u fedora-distrobox-quadlet.service
```

### Container Signature Verification Failing

Ensure the public key is valid and matches your signing key:

```bash
cat /etc/pki/containers/zelf.pub
```

## Project Documentation

- **[README.md](README.md)** (this file) - Overview, building, and usage
- **[DESIGN.md](DESIGN.md)** - Design decisions and architecture rationale
- **[todo.md](todo.md)** - Implementation tracking, completed features, and roadmap
- **[justfile](justfile)** - Build automation commands (run `just --list` to see all)

## License

This configuration is provided as-is. Individual components have their own licenses.

## References

- [Fedora Bootc](https://github.com/containers/bootc)
- [COSMIC Desktop](https://github.com/pop-os/cosmic-epoch)
- [Workstation OSTree Config](https://pagure.io/workstation-ostree-config)
- [ROCm Documentation](https://rocm.docs.amd.com/)
- [Just Command Runner](https://github.com/casey/just)
