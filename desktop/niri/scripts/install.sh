#!/usr/bin/env bash
set -euo pipefail

# RPM Fusion for freeworld codecs/drivers
dnf5 -y install https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm
dnf5 -y install https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm

# Multimedia codecs
dnf5 -y install --allowerasing ffmpeg
dnf5 -y group install multimedia --setopt="install_weak_deps=False"
dnf5 -y group install sound-and-video
dnf5 -y swap noopenh264 openh264
dnf5 -y swap mesa-va-drivers mesa-va-drivers-freeworld
dnf5 -y swap mesa-vdpau-drivers mesa-vdpau-drivers-freeworld

# Noctalia Shell (unified panel, launcher, notifications, lock screen, wallpaper)
dnf5 -y copr enable zhangyi6324/noctalia-shell
dnf5 -y install noctalia-shell

# GTK/Qt theming for noctalia color scheme integration
dnf5 -y install \
  adw-gtk3-theme \
  gnome-tweaks \
  qt6ct

# Niri and Wayland session tools (swaybg/swayidle/swaylock already in base image)
dnf5 -y install \
  niri \
  alacritty \
  xwayland-satellite \
  xdg-desktop-portal-gtk \
  xdg-desktop-portal-gnome \
  gnome-keyring \
  system-config-printer

# Common tools (same as cosmic/gnome)
dnf5 -y install \
  android-tools \
  fuse \
  fuse-overlayfs \
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
  steam-devices \
  osbuild-selinux

# AMD ROCm
dnf5 -y swap OpenCL-ICD-Loader ocl-icd
dnf5 -y install \
  rocminfo \
  rocm-opencl \
  rocm-clinfo \
  rocm-smi \
  rocm-hip \
  --allowerasing

dnf5 -y swap nano-default-editor vim-default-editor

# Virtualization
dnf5 -y group install virtualization

# Cleanup
dnf5 -y autoremove
dnf5 -y clean all
rm -rf /var/cache/dnf /var/lib/dnf
find /var/log -type f -delete 2>/dev/null || true
