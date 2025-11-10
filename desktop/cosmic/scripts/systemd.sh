#!/usr/bin/env bash
# Purpose: Enable system services
# Phase: 2 of 3 (Service Configuration)
# Commit: Creates ostree commit after completion
#
# This script enables:
# - Tailscale VPN service
# - Tuned power management
# - Podman automatic container updates
# - Secures Quadlet container directories
#
# Note: Service list is also defined in /etc/systemd/system-preset/80-cosmic-desktop.preset
# for documentation and future systemd preset processing

set -euo pipefail

# ============================================================================
# Network Services
# ============================================================================

# Enable Tailscale VPN/mesh networking daemon
systemctl enable tailscaled.service

# ============================================================================
# Power Management
# ============================================================================

# Enable tuned for automatic performance and power profile management
systemctl enable tuned

# ============================================================================
# Container Management
# ============================================================================

# Enable automatic updates for containers with AutoUpdate=registry label
# Service runs daily via timer
systemctl enable podman-auto-update.service podman-auto-update.timer

# ============================================================================
# Security Hardening
# ============================================================================

# Restrict permissions on quadlet directory to prevent unauthorized access
# Quadlet configs can run privileged containers, so protect from other users
chmod 700 /etc/containers/systemd
