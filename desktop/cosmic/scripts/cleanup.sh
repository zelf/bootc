#!/usr/bin/env bash
set -euo pipefail

# Remove unwanted packages from the base image (if present)
dnf5 -y remove \
    firefox \
    firefox-langpacks \
    htop \
    nvtop \
    toolbox \
    --skip-unavailable

dnf5 -y autoremove
