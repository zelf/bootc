#!/usr/bin/env bash

set -xeuo pipefail
firewall-offline-cmd --remove-service ssh
ostree container commit
