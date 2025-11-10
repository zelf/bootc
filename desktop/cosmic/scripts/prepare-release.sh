#!/usr/bin/env bash
# Purpose: Prepare a new release of COSMIC Desktop bootc image
# Usage: prepare-release.sh <version>
#
# This script helps prepare a new release by:
# - Validating version format
# - Checking for uncommitted changes
# - Updating CHANGELOG.md (interactive)
# - Creating and pushing a git tag
# - Providing post-release instructions

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

VERSION="${1:-}"

if [ -z "$VERSION" ]; then
    echo -e "${RED}Error: Version is required${NC}"
    echo "Usage: $0 <version>"
    echo "Example: $0 1.0.0"
    exit 1
fi

# Validate version format (semantic versioning)
if ! [[ "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo -e "${RED}Error: Invalid version format${NC}"
    echo "Version must follow semantic versioning: X.Y.Z"
    echo "Example: 1.0.0"
    exit 1
fi

TAG="cosmic-v${VERSION}"

echo -e "${BLUE}═══════════════════════════════════════════════${NC}"
echo -e "${BLUE}  COSMIC Desktop Release Preparation${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════${NC}"
echo ""
echo -e "Version: ${GREEN}${VERSION}${NC}"
echo -e "Tag: ${GREEN}${TAG}${NC}"
echo ""

# Check if we're in the right directory
if [ ! -f "Containerfile" ]; then
    echo -e "${RED}Error: Must be run from desktop/cosmic directory${NC}"
    exit 1
fi

# Check for uncommitted changes
if ! git diff-index --quiet HEAD --; then
    echo -e "${YELLOW}Warning: You have uncommitted changes${NC}"
    echo ""
    git status --short
    echo ""
    read -p "Continue anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Aborted."
        exit 1
    fi
fi

# Check if tag already exists
if git rev-parse "$TAG" >/dev/null 2>&1; then
    echo -e "${RED}Error: Tag $TAG already exists${NC}"
    echo "Use a different version or delete the existing tag:"
    echo "  git tag -d $TAG"
    echo "  git push origin :refs/tags/$TAG"
    exit 1
fi

# Get previous tag for changelog
PREV_TAG=$(git tag --sort=-version:refname | grep -E "^(cosmic-v|v.*-cosmic)" | head -n 1)

if [ -z "$PREV_TAG" ]; then
    echo "This will be the first release"
    PREV_TAG=$(git rev-list --max-parents=0 HEAD)
else
    echo "Previous release: $PREV_TAG"
fi

echo ""
echo -e "${BLUE}═══════════════════════════════════════════════${NC}"
echo -e "${BLUE}  Changes Since Last Release${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════${NC}"
echo ""

# Show changes
git log ${PREV_TAG}..HEAD --pretty=format:"- %s (%h)" --no-merges -- .

echo ""
echo ""

# Prompt to update CHANGELOG
echo -e "${YELLOW}═══════════════════════════════════════════════${NC}"
echo -e "${YELLOW}  Action Required: Update CHANGELOG.md${NC}"
echo -e "${YELLOW}═══════════════════════════════════════════════${NC}"
echo ""
echo "Please update CHANGELOG.md with the changes for version $VERSION"
echo ""
echo "1. Move items from [Unreleased] to [${VERSION}] - $(date +%Y-%m-%d)"
echo "2. Organize changes into Added/Changed/Fixed sections"
echo "3. Save and close the file"
echo ""

read -p "Press Enter to open CHANGELOG.md in editor..."

# Open CHANGELOG in editor
${EDITOR:-nano} CHANGELOG.md

echo ""
read -p "Have you updated CHANGELOG.md? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Please update CHANGELOG.md and run this script again"
    exit 1
fi

# Commit CHANGELOG if it was changed
if ! git diff --quiet CHANGELOG.md; then
    echo ""
    echo "Committing CHANGELOG.md..."
    git add CHANGELOG.md
    git commit -m "docs: Update CHANGELOG for version ${VERSION}"
fi

# Create and push tag
echo ""
echo -e "${BLUE}═══════════════════════════════════════════════${NC}"
echo -e "${BLUE}  Creating Release Tag${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════${NC}"
echo ""

echo "Creating tag: $TAG"
git tag -a "$TAG" -m "Release COSMIC Desktop ${VERSION}"

echo ""
echo -e "${GREEN}✓ Tag created successfully!${NC}"
echo ""

# Ask to push
read -p "Push tag to GitHub to trigger release? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Pushing tag to origin..."
    git push origin "$TAG"

    echo ""
    echo -e "${GREEN}✓ Release tag pushed!${NC}"
    echo ""
    echo -e "${BLUE}═══════════════════════════════════════════════${NC}"
    echo -e "${BLUE}  Next Steps${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════${NC}"
    echo ""
    echo "1. GitHub Actions will now:"
    echo "   - Build the COSMIC Desktop image"
    echo "   - Run validation tests"
    echo "   - Perform security scanning"
    echo "   - Generate SBOM"
    echo "   - Push to ghcr.io/zelf/cosmic:${VERSION}"
    echo "   - Sign the image with Sigstore"
    echo "   - Create GitHub Release with changelog"
    echo ""
    echo "2. Monitor the release workflow:"
    echo "   https://github.com/zelf/bootc/actions"
    echo ""
    echo "3. Once complete, the release will be available at:"
    echo "   https://github.com/zelf/bootc/releases/tag/${TAG}"
    echo ""
    echo "4. Pull the released image:"
    echo "   podman pull ghcr.io/zelf/cosmic:${VERSION}"
    echo ""
else
    echo ""
    echo "Tag created but not pushed."
    echo "To push manually later:"
    echo "  git push origin $TAG"
    echo ""
    echo "To delete the tag if needed:"
    echo "  git tag -d $TAG"
fi

echo ""
echo -e "${GREEN}Release preparation complete!${NC}"
