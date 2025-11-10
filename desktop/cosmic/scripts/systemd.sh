#!/usr/bin/env bash
set -euo pipefail

systemctl enable tailscaled.service

# Power management with tuned
systemctl enable tuned

systemctl enable podman-auto-update.service podman-auto-update.timer

# Restrict permissions on quadlet directory
chmod 700 /etc/containers/systemd
