#!/usr/bin/env bash
set -euo pipefail

dnf5 -y install https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm
dnf5 -y install https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
dnf5 -y install --allowerasing ffmpeg
dnf5 -y group install multimedia --setopt="install_weak_deps=False" --exclude=PackageKit-gstreamer-plugin
dnf5 -y group install sound-and-video
dnf5 -y swap noopenh264 openh264
dnf5 -y install mozilla-openh264
dnf5 -y swap mesa-va-drivers mesa-va-drivers-freeworld
dnf5 -y swap mesa-vdpau-drivers mesa-vdpau-drivers-freeworld
dnf5 -y install \
  android-tools \
  vim \
  bat \
  btop \
  pv \
  fzf \
  zstd \
  nmap-ncat \
  distrobox \
  just \
  tailscale \
  lm_sensors \
  podman-compose \
  webkit2gtk3 \
  libusb \
  steam-devices \
  osbuild-selinux \
  tlp \
  tlp-rdw

# Failed to resolve the transaction:
# Problem: conflicting requests
#   - package rocm-opencl-6.2.1-2.fc41.x86_64 from updates-archive requires ocl-icd(x86-64), but none of the providers can be installed
dnf5 -y swap OpenCL-ICD-Loader ocl-icd
dnf5 -y install \
  rocminfo \
  rocm-opencl \
  rocm-clinfo \
  rocm-smi \
  rocm-hip \
  --allowerasing

dnf5 -y swap nano-default-editor vim-default-editor
# Install virtualization tools
dnf5 -y group install virtualization

# Remove Firefox rpm (superseded by flatpak Firefox)
rpm -e firefox firefox-langpacks

# Remove unneeded packages (currently doesn't actually reduce space, but reduces clutter)
dnf5 -y autoremove
dnf5 -y clean all

rm -rf /var/cache/dnf /var/lib/dnf /var/log/*
