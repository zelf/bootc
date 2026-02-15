#!/usr/bin/env bash
set -euo pipefail

systemctl enable tailscaled.service

systemctl mask systemd-rfkill.service systemd-rfkill.socket

systemctl enable podman-auto-update.service podman-auto-update.timer

# Restrict permissions on quadlet directory
chmod 700 /etc/containers/systemd

systemctl disable NetworkManager-wait-online.service

# Create plugdev group and add all wheel users for ZSA keyboard support
groupadd -f plugdev
readarray -t wheelarray < <(getent group wheel | cut -d ":" -f 4 | tr ',' '\n')
for user in "${wheelarray[@]}"; do
  [[ -n "$user" ]] && usermod -aG plugdev "$user"
done
