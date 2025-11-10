# COSMIC Desktop Bootc Image - Design Decisions

## Architecture and Structure

### Containerfile vs. Modular YAML Manifests

**Decision**: Use Containerfile-based approach rather than modular YAML manifests (rpm-ostree compose tree style)

**Rationale**:

1. **Single Variant, Single Architecture**
   - This image targets only COSMIC Desktop on AMD x86_64
   - No need to share configuration across multiple desktop variants
   - No need for architecture-specific package splits
   - YAML manifest structure is designed for managing multiple variants (Silverblue, Kinoite, Sway, etc.)

2. **Bootc Container-First Approach**
   - Bootc uses OCI container images as the primary artifact
   - Containerfile is the natural, native format for container images
   - More familiar to developers working with containers
   - Better integration with container build tools (Podman, Docker, BuildKit)

3. **Simpler Build Pipeline**
   - Direct container build with `podman build`
   - No need for `rpm-ostree compose tree` tooling
   - Easier local development and testing
   - Faster iteration cycles

4. **Clear Separation of Concerns**
   - Scripts handle package installation and configuration
   - `/etc` overlay provides static configuration files
   - Containerfile orchestrates the build process
   - Each component has a single, clear purpose

5. **Maintainability**
   - Easier to understand for single-maintainer project
   - Bash scripts are straightforward to read and modify
   - No need to learn rpm-ostree manifest YAML syntax
   - Standard container image tooling

**When YAML Manifests Make Sense**:
- Multiple desktop variants sharing common base
- Multi-architecture builds with different package sets
- Official distribution images requiring comps synchronization
- Large teams needing structured configuration management
- Automated package list generation from comps

**Our Structure Provides**:
- ✅ Organized scripts with clear sections
- ✅ Proper repository definitions
- ✅ Systemd preset files
- ✅ Build automation via justfile
- ✅ Validation and testing framework
- ✅ Comprehensive documentation

This gives us the benefits of Fedora Atomic Desktop standards without the overhead of multi-variant manifest management.

## Build Process

### Four-Phase Build with Ostree Commits

The build process uses four phases, each creating an ostree commit:

1. **Package Installation** (`install.sh`)
   - Installs all packages
   - Configures repositories
   - Handles cleanup

2. **Service Configuration** (`systemd.sh`)
   - Enables system services
   - Configures service permissions

3. **Firewall Hardening** (`firewalld.sh`)
   - Removes SSH from firewall
   - Security hardening

4. **COSMIC Customization** (`cosmic-setup.sh`)
   - Desktop-specific post-processing
   - Default settings and configurations
   - User environment setup

Each phase creates an ostree commit, providing:
- Atomic updates between phases
- Ability to track changes per phase
- Better debugging if a phase fails
- Cleaner git-like history of the image

## Package Management Philosophy

### Minimalist Approach

- Weak dependencies disabled (`install_weak_deps=False`)
- Recommended packages disabled (`Recommends=false`)
- Firefox RPM removed (Flatpak preferred)
- Explicit package selection over groups where possible

**Rationale**: Smaller image size, faster updates, explicit control over what's installed

### Package Organization

Packages are organized into logical sections in `install.sh`:
- COSMIC Desktop Environment
- Third-Party Repositories
- Multimedia Support
- System Utilities and CLI Tools
- AMD GPU Computing (ROCm)
- Virtualization Stack
- Package Cleanup

Each package has inline documentation explaining its purpose.

## Security Model

### Container Signature Verification

Default policy: **REJECT** all unsigned containers

Exception: `ghcr.io/zelf` registry with Sigstore verification

**Files**:
- `/etc/containers/policy.json` - Signature policy
- `/etc/pki/containers/zelf.pub` - Public verification key
- `/etc/containers/registries.d/zelf.yaml` - Sigstore configuration

This enforces strict security while allowing personal registry usage.

### Firewall Configuration

SSH service removed from firewall by default:
- This is a desktop, not a server
- Remote SSH access disabled for security
- Users can re-enable if needed

### Quadlet Permissions

`/etc/containers/systemd` restricted to 700 permissions:
- Quadlet configs can run privileged containers
- Prevents unauthorized container configuration
- Protects against local privilege escalation

## Performance Optimizations

### ZRAM Configuration

Aggressive ZRAM setup optimized for desktop use:
- Size: 2x physical RAM
- Compression: zstd
- Swappiness: 180 (high, optimized for compressed swap)
- Page cluster: 0 (disable readahead for ZRAM/SSD)

**Rationale**: ZRAM provides excellent performance for desktop workloads with modern CPUs that can handle compression overhead.

### Tuned Integration

Enables tuned service for:
- Automatic power profile switching
- Performance optimization based on workload
- Battery life improvements on laptops

## Development Workflow

### Distrobox Integration

Pre-configured Fedora toolbox via Quadlet:
- Automatic start on user login
- Full host integration
- Signature-verified image
- Auto-updates from registry

**Rationale**: Keep development tools out of the host system, maintain clean base image

### Virtualization Support

Full libvirt stack with PolicyKit rules:
- Wheel group can manage VMs without password
- Complete QEMU/KVM support
- Virt-manager GUI included

## Hardware Support

### AMD-Specific

This image is explicitly AMD x86_64 focused:
- ROCm stack for GPU computing
- Mesa freeworld drivers for video acceleration
- Optimized for AMD graphics

Not attempting multi-architecture support reduces complexity.

### ZSA Keyboards

Udev rules for programmable keyboards:
- Moonlander, Ergodox EZ, Planck EZ, Voyager
- Web flashing and firmware updates

## Future Considerations

### What We're Not Doing (And Why)

1. **Multi-Architecture Builds**
   - Not needed: This is an AMD x86_64 focused image
   - Complexity: Would require conditional package installation
   - Maintenance: Would need testing on multiple platforms

2. **Comps Synchronization**
   - Not needed: Single variant with explicit package selection
   - Overhead: Requires Python tooling and Fedora comps data
   - Flexibility: Manual selection gives more control

3. **YAML Manifest Structure**
   - Not needed: See "Containerfile vs. Modular YAML Manifests" above
   - Overhead: Additional abstraction layer
   - Learning curve: rpm-ostree compose tree syntax

### Possible Future Enhancements

1. **Automatic Testing on PRs**
   - Already have validation script
   - Could add automated testing in CI

2. **Kernel Tuning**
   - Custom kernel parameters for COSMIC
   - Performance tuning for AMD GPUs

3. **COSMIC-Specific Defaults**
   - Theme customization
   - Keybinding presets
   - Panel configuration
   - (Waiting for COSMIC to stabilize)

4. **Development Container Variants**
   - Different toolbox images for different languages
   - Pre-configured development environments

## References

- [Fedora Bootc](https://github.com/containers/bootc)
- [COSMIC Desktop](https://github.com/pop-os/cosmic-epoch)
- [Workstation OSTree Config](https://pagure.io/workstation-ostree-config) - Inspiration for standards
- [OCI Image Spec](https://github.com/opencontainers/image-spec)
- [Podman Build Documentation](https://docs.podman.io/en/latest/markdown/podman-build.1.html)
