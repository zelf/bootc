#!/usr/bin/env bash
set -euo pipefail

systemctl enable tailscaled.service

# Power management
systemctl enable tlp
systemctl mask systemd-rfkill.service systemd-rfkill.socket

systemctl enable podman-auto-update.service podman-auto-update.timer

# Restrict permissions on quadlet directory
chmod 700 /etc/containers/systemd
ostree container commit
