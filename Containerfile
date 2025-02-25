FROM quay.io/fedora-ostree-desktops/sway-atomic:41

# dnf configuration has to be in effect during build
COPY etc/dnf /etc/dnf

# Add rpmfusion repositories
RUN dnf5 -y install https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
# Install ffmpeg (removing all the -free replacements is required)
RUN dnf5 -y install --allowerasing ffmpeg

# Install openh264
RUN dnf5 -y swap noopenh264 openh264 && dnf5 -y install mozilla-openh264

# Bulk of layered packages
RUN dnf5 -y install \
      vim \
      bat \
      btop \
      pv \
      zstd \
      nmap-ncat \
      distrobox \
      just \
      tailscale \
      lm_sensors \
      podman-compose \
      webkit2gtk3 \
      libusb \
      steam-devices

# Set vim as default editor
RUN dnf5 -y swap nano-default-editor vim-default-editor

# Install virtualization tools
RUN dnf5 -y install libvirt libvirt-daemon-kvm virt-manager

# Remove Firefox rpm (superseded by flatpak Firefox)
RUN rpm -e firefox firefox-langpacks

# Remove unneeded packages (currently doesn't actually reduce space, but reduces clutter)
RUN dnf5 -y autoremove

# Apply configuration
COPY etc /etc
COPY usr /usr

# Apply hardened firewall configuration
# RUN firewall-offline-cmd --set-default-zone public
RUN firewall-offline-cmd --remove-service ssh

RUN systemctl enable tailscaled.service

# Restrict permissions on quadlet directory
RUN chmod 700 /etc/containers/systemd

# https://github.com/ostreedev/ostree-rs-ext/issues/159
RUN ostree container commit
