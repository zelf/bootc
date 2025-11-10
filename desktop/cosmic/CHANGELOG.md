# Changelog

All notable changes to the COSMIC Desktop bootc image will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Comprehensive validation framework with 24 automated tests
- Justfile for build automation with 20+ commands
- COSMIC-specific post-processing and customization
- Security scanning with Trivy in CI/CD
- SBOM (Software Bill of Materials) generation
- Automated release workflow with changelog generation
- Build summaries and PR comments in GitHub Actions
- Systemd preset files for declarative service management
- Proper repository definition for COSMIC Copr
- Design documentation (DESIGN.md)

### Changed
- Enhanced GitHub Actions workflow with comprehensive testing
- Improved documentation with justfile commands
- Updated README with testing and validation sections
- Reorganized install.sh with clear section headers and inline comments
- Build process now has 4 phases (added COSMIC customization phase)

### Fixed
- None

## Release Process

To create a new release:

1. **Update CHANGELOG.md** with changes since last release
2. **Create and push a tag**:
   ```bash
   git tag -a cosmic-v1.0.0 -m "Release COSMIC Desktop 1.0.0"
   git push origin cosmic-v1.0.0
   ```
3. **GitHub Actions will automatically**:
   - Build the image
   - Run all validation tests
   - Perform security scanning
   - Generate SBOM
   - Push to registry with version tag
   - Sign the image
   - Create GitHub Release with changelog
   - Attach SBOM and security scan results

## Version Naming

- Tag format: `cosmic-vX.Y.Z` or `vX.Y.Z-cosmic`
- Example: `cosmic-v1.0.0`
- Semantic versioning:
  - MAJOR: Breaking changes or major updates
  - MINOR: New features, significant package updates
  - PATCH: Bug fixes, minor updates

---

## Historical Changes

Changes will be documented here once releases are created.
