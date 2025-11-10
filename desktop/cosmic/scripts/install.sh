#!/usr/bin/env bash
# Purpose: Install COSMIC Desktop and all required packages
# Phase: 1 of 3 (Package Installation)
# Platform: AMD x86_64 only
# Commit: Creates ostree commit after completion
#
# This script installs:
# - COSMIC Desktop environment
# - Multimedia support with hardware acceleration
# - AMD ROCm GPU computing stack
# - Development and virtualization tools
# - System utilities

set -euo pipefail

# ============================================================================
# COSMIC Desktop Environment
# ============================================================================
# Note: COSMIC Copr repository is pre-configured via /etc/yum.repos.d/cosmic-epoch.repo

# Install COSMIC desktop
dnf5 -y install cosmic-desktop

# ============================================================================
# Third-Party Repositories
# ============================================================================

# Install RPM Fusion repositories (free and nonfree)
dnf5 -y install https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm
dnf5 -y install https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm

# ============================================================================
# Multimedia Support
# ============================================================================

# Install FFmpeg with full codec support
dnf5 -y install --allowerasing ffmpeg

# Install multimedia group packages (GStreamer plugins, codecs, etc.)
dnf5 -y group install multimedia --setopt="install_weak_deps=False" --exclude=PackageKit-gstreamer-plugin

# Install sound and video applications
dnf5 -y group install sound-and-video

# Enable OpenH264 codec for H.264 video support
dnf5 -y swap noopenh264 openh264
dnf5 -y install mozilla-openh264

# Swap to RPM Fusion freeworld drivers for hardware-accelerated video
# These provide support for patented codecs (H.264, H.265, VC-1, etc.)
dnf5 -y swap mesa-va-drivers mesa-va-drivers-freeworld      # VA-API (Intel/AMD)
dnf5 -y swap mesa-vdpau-drivers mesa-vdpau-drivers-freeworld # VDPAU (AMD/NVIDIA)

# ============================================================================
# System Utilities and CLI Tools
# ============================================================================

# Install common utilities and tools
dnf5 -y install \
  android-tools \        # Android device utilities (adb, fastboot)
  vim \                  # Text editor
  bat \                  # Syntax-highlighted cat replacement
  btop \                 # Resource monitor
  pv \                   # Pipe viewer with progress
  fzf \                  # Fuzzy finder
  zstd \                 # Compression utility
  nmap-ncat \            # Networking tools
  distrobox \            # Container-based development environments
  just \                 # Command runner (like make)
  tailscale \            # VPN/mesh networking
  lm_sensors \           # Hardware monitoring
  podman-compose \       # Docker-compose compatibility for Podman
  webkit2gtk3 \          # Web rendering library
  libusb \               # USB device access library
  steam-devices \        # Udev rules for game controllers
  osbuild-selinux \      # SELinux policies for image building
  tuned                  # Power management and performance tuning

# Swap default editor from nano to vim
dnf5 -y swap nano-default-editor vim-default-editor

# ============================================================================
# AMD GPU Computing (ROCm Stack)
# ============================================================================
# AMD ROCm provides OpenCL and HIP support for GPU computing
# Platform: AMD x86_64 GPUs only (will fail on other architectures)

dnf5 -y swap OpenCL-ICD-Loader ocl-icd
dnf5 -y install \
  rocminfo \         # ROCm system information utility
  rocm-opencl \      # OpenCL runtime for AMD GPUs
  rocm-clinfo \      # OpenCL device information
  rocm-smi \         # System management interface for AMD GPUs
  rocm-hip \         # HIP runtime for GPU programming
  --allowerasing

# ============================================================================
# Virtualization Stack
# ============================================================================

# Install complete virtualization group (libvirt, virt-manager, QEMU, etc.)
dnf5 -y group install virtualization

# ============================================================================
# Package Cleanup
# ============================================================================

# Remove Firefox RPM package (user will install Flatpak version)
rpm -e firefox firefox-langpacks

# Remove unneeded packages
# Note: Currently doesn't reduce space significantly due to ostree deduplication,
# but reduces package count and potential update surface
dnf5 -y autoremove

# Clean package manager caches
dnf5 -y clean all
rm -rf /var/cache/dnf /var/lib/dnf

# Clear log files to reduce image size
find /var/log -type f -delete
