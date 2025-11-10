#!/usr/bin/env bash
# Purpose: Configure firewall for security hardening
# Phase: 3 of 3 (Firewall Configuration)
# Commit: Creates ostree commit after completion
#
# This script:
# - Removes SSH service from firewall (disables remote SSH access)
#
# Rationale: This is a desktop image, not a server. SSH access is disabled
# by default for security. Users can re-enable if needed with:
#   sudo firewall-cmd --permanent --add-service=ssh
#   sudo firewall-cmd --reload

set -euo pipefail

# ============================================================================
# Firewall Hardening
# ============================================================================

# Remove SSH service from firewall to block remote SSH connections
# This prevents unauthorized remote access on a desktop system
firewall-offline-cmd --remove-service ssh
