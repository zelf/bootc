#!/usr/bin/env bash
set -euo pipefail

# Remove unwanted packages from the base image (only those actually present)
UNWANTED=(firefox firefox-langpacks toolbox waybar mako)
TO_REMOVE=()
for pkg in "${UNWANTED[@]}"; do
  if rpm -q "$pkg" &>/dev/null; then
    TO_REMOVE+=("$pkg")
  fi
done
if [[ ${#TO_REMOVE[@]} -gt 0 ]]; then
  dnf5 -y remove "${TO_REMOVE[@]}"
fi
