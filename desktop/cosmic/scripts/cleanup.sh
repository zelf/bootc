#!/usr/bin/env bash
set -euo pipefail

# Remove unwanted packages from the base image
dnf5 -y remove \
    firefox \
    firefox-langpacks \
    htop \
    nvtop \
    toolbox

dnf5 -y autoremove
