#!/usr/bin/env bash
set -euo pipefail

# Remove Sway and unwanted packages from the base image (only those actually present)
UNWANTED=(sway swaybg swaybar swayidle swaylock firefox firefox-langpacks foot toolbox)
TO_REMOVE=()
for pkg in "${UNWANTED[@]}"; do
  if rpm -q "$pkg" &>/dev/null; then
    TO_REMOVE+=("$pkg")
  fi
done
if [[ ${#TO_REMOVE[@]} -gt 0 ]]; then
  dnf5 -y remove "${TO_REMOVE[@]}"
fi
