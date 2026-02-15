#!/usr/bin/env bash
set -euo pipefail

if ! command -v firewall-offline-cmd &>/dev/null; then
  echo "WARNING: firewall-offline-cmd not found, skipping firewall configuration" >&2
  exit 0
fi

if firewall-offline-cmd --list-services 2>/dev/null | grep -qw ssh; then
  firewall-offline-cmd --remove-service ssh
else
  echo "WARNING: ssh service not present in default zone, skipping removal" >&2
fi
