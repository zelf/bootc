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

### Build Command

```bash
cd /home/zelf/projects/bootc/desktop/cosmic
podman build -t cosmic-desktop:latest .
```

### Build Process

The build follows a three-phase approach with ostree commits after each phase:

1. **Package Installation** (`install.sh`)
   - Adds COSMIC Desktop repository
   - Installs desktop environment, multimedia, and development tools
   - Configures AMD ROCm GPU support
   - Adds RPM Fusion repositories

2. **Service Configuration** (`systemd.sh`)
   - Enables system services (Tailscale, tuned, podman-auto-update)
   - Secures container systemd directories

3. **Firewall Hardening** (`firewalld.sh`)
   - Removes SSH from firewall (security hardening)

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
├── scripts/                         # Build-time installation scripts
│   ├── install.sh                  # Package installation (phase 1)
│   ├── systemd.sh                  # Service configuration (phase 2)
│   └── firewalld.sh                # Firewall hardening (phase 3)
├── etc/                            # System configuration overlay
│   ├── containers/                 # Container security and Quadlet configs
│   ├── dnf/                        # Package manager configuration
│   ├── sysctl.d/                   # Kernel parameter tuning
│   ├── systemd/                    # ZRAM and service configs
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

After building, test the image:

```bash
# Run bootc container lint
podman run --rm cosmic-desktop:latest bootc container lint

# Inspect the image
podman run --rm -it cosmic-desktop:latest /bin/bash

# Check ostree commits
podman run --rm cosmic-desktop:latest ostree log fedora/stable/x86_64/cosmic
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
podman pull quay.io/fedora/fedora-bootc:42
podman build --no-cache -t cosmic-desktop:latest .
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

## License

This configuration is provided as-is. Individual components have their own licenses.

## References

- [Fedora Bootc](https://github.com/containers/bootc)
- [COSMIC Desktop](https://github.com/pop-os/cosmic-epoch)
- [Workstation OSTree Config](https://pagure.io/workstation-ostree-config)
- [ROCm Documentation](https://rocm.docs.amd.com/)
