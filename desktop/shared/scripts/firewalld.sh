#!/usr/bin/env bash
set -euo pipefail

if ! command -v firewall-offline-cmd &>/dev/null; then
  echo "WARNING: firewall-offline-cmd not found, skipping firewall configuration" >&2
  exit 0
fi

echo "firewalld.sh: removing ssh service from default zone"
firewall-offline-cmd --remove-service ssh 2>&1 || {
  echo "WARNING: failed to remove ssh service (exit $?), continuing" >&2
}
echo "firewalld.sh: done"
