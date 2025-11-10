#!/usr/bin/env bash
# Purpose: COSMIC Desktop specific post-processing and customizations
# Phase: Post-installation configuration
# Commit: Creates ostree commit after completion
#
# This script performs COSMIC-specific customizations:
# - Sets default applications
# - Configures system settings
# - Prepares user environment defaults

set -euo pipefail

# ============================================================================
# COSMIC Desktop Defaults
# ============================================================================

# Create directory for COSMIC default settings
mkdir -p /etc/skel/.config/cosmic

# Note: COSMIC stores its configuration in ~/.config/cosmic/
# These settings will be copied to new user home directories

# Create a README for users about COSMIC configuration
cat > /etc/skel/.config/cosmic/README.txt <<'EOF'
COSMIC Desktop Configuration
============================

This directory contains COSMIC Desktop settings and configuration.

COSMIC is a new desktop environment written in Rust by System76.
It uses a modern configuration system stored in this directory.

Configuration files will be automatically created when you use COSMIC
and adjust settings through the COSMIC Settings application.

For more information:
- COSMIC GitHub: https://github.com/pop-os/cosmic-epoch
- System76 Blog: https://blog.system76.com/

This is a preview/development version of COSMIC running on Fedora 42.
EOF

# ============================================================================
# Default Applications
# ============================================================================

# Set default terminal (if cosmic-term is available)
# COSMIC uses its own terminal emulator
if rpm -q cosmic-term &>/dev/null; then
    mkdir -p /etc/skel/.local/share/applications

    # Note: This will be overridden by COSMIC's own defaults
    # But provides a fallback for XDG_TERMINAL_EXEC
    cat > /etc/skel/.local/share/applications/cosmic-term.desktop <<'EOF'
[Desktop Entry]
Name=COSMIC Terminal
Comment=Terminal emulator for COSMIC
Exec=cosmic-term
Icon=cosmic-term
Type=Application
Terminal=false
Categories=System;TerminalEmulator;
Keywords=terminal;shell;console;
EOF
fi

# ============================================================================
# System Integration
# ============================================================================

# Configure display manager to show COSMIC session
# COSMIC typically uses its own greeter, but we ensure compatibility
mkdir -p /usr/share/wayland-sessions

# COSMIC should provide its own session file, but we verify it exists
if [ ! -f /usr/share/wayland-sessions/cosmic.desktop ]; then
    echo "Warning: COSMIC Wayland session file not found"
    echo "This may be provided by the cosmic-session package"
fi

# ============================================================================
# Performance Optimizations for COSMIC
# ============================================================================

# COSMIC is written in Rust and uses modern rendering
# Ensure optimal performance settings

# Create a profile.d script for COSMIC-specific environment variables
cat > /etc/profile.d/cosmic-env.sh <<'EOF'
# COSMIC Desktop environment variables

# Enable Wayland backend for various applications
export MOZ_ENABLE_WAYLAND=1
export QT_QPA_PLATFORM=wayland
export SDL_VIDEODRIVER=wayland
export _JAVA_AWT_WM_NONREPARENTING=1

# COSMIC-specific settings
# Force Wayland for COSMIC applications
export COSMIC_SESSION=1

# Performance: Use hardware acceleration when available
export LIBVA_DRIVER_NAME=radeonsi  # For AMD GPUs
EOF

# ============================================================================
# Documentation and User Information
# ============================================================================

# Create a welcome message for COSMIC users
cat > /etc/motd.d/cosmic-welcome.txt <<'EOF'
╔══════════════════════════════════════════════════════════════╗
║                  COSMIC Desktop on Fedora 42                 ║
╚══════════════════════════════════════════════════════════════╝

Welcome to COSMIC Desktop! This is a custom bootc image with:

 • COSMIC Desktop Environment (Rust-based, modern design)
 • AMD ROCm GPU computing support
 • Full multimedia codec support
 • Development tools (distrobox, podman, virtualization)
 • Performance optimizations (ZRAM, tuned)

Quick Start:
 • COSMIC Settings: Launch from application menu
 • Terminal: cosmic-term
 • Documentation: /etc/skel/.config/cosmic/README.txt

For issues or feedback:
 • COSMIC: https://github.com/pop-os/cosmic-epoch
 • This image: https://github.com/zelf/bootc

Note: COSMIC is under active development. Some features may be
incomplete or experimental.

EOF

# ============================================================================
# Flatpak Integration
# ============================================================================

# Ensure Flatpak is configured for COSMIC
# COSMIC should work well with Flatpak applications

if command -v flatpak &>/dev/null; then
    # Add Flathub repository (if not already added)
    # This is typically done by the user, but we can prepare it
    mkdir -p /etc/flatpak/remotes.d

    echo "Flatpak is available for application installation"
    echo "Users can add Flathub with: flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo"
fi

# ============================================================================
# Cleanup and Final Setup
# ============================================================================

# Ensure proper permissions on skeleton files
chmod -R 755 /etc/skel/.config 2>/dev/null || true
chmod 644 /etc/skel/.config/cosmic/README.txt 2>/dev/null || true

echo "COSMIC Desktop post-processing complete"
