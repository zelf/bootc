#!/usr/bin/env bash
# Purpose: Validate COSMIC Desktop bootc image
# Usage: validate.sh [image-name]
#
# This script validates:
# - Image exists and is accessible
# - Bootc container structure is valid
# - Required packages are installed
# - Services are properly configured
# - Configuration files are in place
# - Container signature verification setup

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Default image name
IMAGE="${1:-ghcr.io/zelf/cosmic:latest}"

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Test result tracking
print_test() {
    local test_name="$1"
    echo -e "\n${YELLOW}[TEST]${NC} $test_name"
    TESTS_RUN=$((TESTS_RUN + 1))
}

pass() {
    echo -e "${GREEN}✓ PASS${NC}"
    TESTS_PASSED=$((TESTS_PASSED + 1))
}

fail() {
    local reason="$1"
    echo -e "${RED}✗ FAIL${NC}: $reason"
    TESTS_FAILED=$((TESTS_FAILED + 1))
}

# Helper to run command in container
run_in_container() {
    podman run --rm "$IMAGE" "$@"
}

# Helper to check if file exists in container
file_exists() {
    local file="$1"
    run_in_container test -f "$file" 2>/dev/null
}

# Helper to check if package is installed
package_installed() {
    local package="$1"
    run_in_container rpm -q "$package" &>/dev/null
}

# Helper to check if service is enabled
service_enabled() {
    local service="$1"
    run_in_container systemctl is-enabled "$service" &>/dev/null
}

echo "========================================"
echo "COSMIC Desktop Bootc Image Validation"
echo "========================================"
echo "Image: $IMAGE"
echo ""

# Test 1: Image exists locally
print_test "Image exists locally"
if podman image exists "$IMAGE"; then
    pass
else
    fail "Image not found locally"
fi

# Test 2: Image has bootc labels
print_test "Image has required bootc labels"
if podman inspect "$IMAGE" | jq -e '.[0].Config.Labels["containers.bootc"] == "1"' &>/dev/null; then
    pass
else
    fail "Missing containers.bootc label"
fi

# Test 3: Image has ostree.bootable label
print_test "Image has ostree.bootable label"
if podman inspect "$IMAGE" | jq -e '.[0].Config.Labels["ostree.bootable"] == "1"' &>/dev/null; then
    pass
else
    fail "Missing ostree.bootable label"
fi

# Test 4: COSMIC Desktop package is installed
print_test "COSMIC Desktop package installed"
if package_installed "cosmic-desktop"; then
    pass
else
    fail "cosmic-desktop package not found"
fi

# Test 5: ROCm packages installed (AMD GPU support)
print_test "ROCm packages installed (AMD GPU support)"
if package_installed "rocminfo" && package_installed "rocm-opencl"; then
    pass
else
    fail "ROCm packages not found"
fi

# Test 6: Multimedia support packages
print_test "Multimedia packages installed"
if package_installed "ffmpeg" && package_installed "mesa-va-drivers-freeworld"; then
    pass
else
    fail "Multimedia packages not complete"
fi

# Test 7: Development tools installed
print_test "Development tools installed"
if package_installed "distrobox" && package_installed "vim" && package_installed "just"; then
    pass
else
    fail "Development tools not complete"
fi

# Test 8: Virtualization packages installed
print_test "Virtualization packages installed"
if package_installed "libvirt" && package_installed "virt-manager"; then
    pass
else
    fail "Virtualization packages not complete"
fi

# Test 9: Container signature verification configured
print_test "Container signature verification configured"
if file_exists "/etc/containers/policy.json" && file_exists "/etc/pki/containers/zelf.pub"; then
    pass
else
    fail "Container signature verification files missing"
fi

# Test 10: Quadlet configuration exists
print_test "Distrobox Quadlet configuration exists"
if file_exists "/etc/containers/systemd/users/1000/fedora-distrobox-quadlet.container"; then
    pass
else
    fail "Distrobox Quadlet configuration missing"
fi

# Test 11: ZRAM configuration exists
print_test "ZRAM configuration exists"
if file_exists "/etc/systemd/zram-generator.conf"; then
    pass
else
    fail "ZRAM configuration missing"
fi

# Test 12: Systemd preset file exists
print_test "Systemd preset file exists"
if file_exists "/etc/systemd/system-preset/80-cosmic-desktop.preset"; then
    pass
else
    fail "Systemd preset file missing"
fi

# Test 13: COSMIC Copr repository configured
print_test "COSMIC Copr repository configured"
if file_exists "/etc/yum.repos.d/cosmic-epoch.repo"; then
    pass
else
    fail "COSMIC Copr repository file missing"
fi

# Test 14: Tailscale service is enabled
print_test "Tailscale service enabled"
if service_enabled "tailscaled.service"; then
    pass
else
    fail "Tailscale service not enabled"
fi

# Test 15: Tuned service is enabled
print_test "Tuned service enabled"
if service_enabled "tuned.service"; then
    pass
else
    fail "Tuned service not enabled"
fi

# Test 16: Podman auto-update timer enabled
print_test "Podman auto-update timer enabled"
if service_enabled "podman-auto-update.timer"; then
    pass
else
    fail "Podman auto-update timer not enabled"
fi

# Test 17: DNF configured to not install weak deps
print_test "DNF configured for minimal installations"
if file_exists "/etc/dnf/dnf.conf" && run_in_container grep -q "install_weak_deps=False" /etc/dnf/dnf.conf; then
    pass
else
    fail "DNF weak deps not disabled"
fi

# Test 18: Firefox RPM removed (for Flatpak)
print_test "Firefox RPM removed (using Flatpak)"
if ! package_installed "firefox"; then
    pass
else
    fail "Firefox RPM still installed"
fi

# Test 19: Polkit rules for libvirt exist
print_test "Polkit rules for libvirt configured"
if file_exists "/etc/polkit-1/rules.d/80-libvirt-manage.rules"; then
    pass
else
    fail "Libvirt polkit rules missing"
fi

# Test 20: ZSA keyboard udev rules exist
print_test "ZSA keyboard udev rules configured"
if file_exists "/etc/udev/rules.d/50-zsa.rules"; then
    pass
else
    fail "ZSA keyboard rules missing"
fi

# Test 21: Bat configured as manpager
print_test "Bat configured as manpager"
if file_exists "/etc/profile.d/bat-manpager.sh"; then
    pass
else
    fail "Bat manpager configuration missing"
fi

# Test 22: Sysctl tuning for ZRAM
print_test "Sysctl tuning configured"
if file_exists "/etc/sysctl.d/20-high-swappines.conf" && file_exists "/etc/sysctl.d/20-no-page-cluster.conf"; then
    pass
else
    fail "Sysctl tuning files missing"
fi

# Test 23: Check image size is reasonable
print_test "Image size is reasonable (< 10GB)"
SIZE=$(podman image inspect "$IMAGE" --format '{{.Size}}')
SIZE_GB=$((SIZE / 1024 / 1024 / 1024))
if [ "$SIZE_GB" -lt 10 ]; then
    echo "  Image size: ${SIZE_GB}GB"
    pass
else
    fail "Image too large: ${SIZE_GB}GB"
fi

# Test 24: Bootc container lint passes
print_test "Bootc container lint validation"
if run_in_container bootc container lint &>/dev/null; then
    pass
else
    fail "Bootc container lint failed"
fi

# Summary
echo ""
echo "========================================"
echo "Validation Summary"
echo "========================================"
echo "Tests run:    $TESTS_RUN"
echo -e "Tests passed: ${GREEN}$TESTS_PASSED${NC}"
echo -e "Tests failed: ${RED}$TESTS_FAILED${NC}"
echo ""

if [ "$TESTS_FAILED" -eq 0 ]; then
    echo -e "${GREEN}✓ All tests passed!${NC}"
    exit 0
else
    echo -e "${RED}✗ Some tests failed${NC}"
    exit 1
fi
