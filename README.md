# Bootc

Custom bootable Fedora container images. Available variants:
- **COSMIC** (`ghcr.io/zelf/cosmic:latest`) — COSMIC desktop environment
- **GNOME** (`ghcr.io/zelf/gnome:latest`) — GNOME (Silverblue-based)

## Initial Setup

Fedora does not ship with bootc by default. First, load the unsigned image (our signing key isn't on the system yet):

```bash
rpm-ostree rebase ostree-unverified-registry:ghcr.io/zelf/gnome:latest
systemctl reboot
```

Now the custom image is loaded with our signing key. Switch to the signed version:

```bash
rpm-ostree rebase ostree-image-signed:docker://ghcr.io/zelf/gnome:latest
systemctl reboot
```

Move to bootc for future updates:

```bash
sudo bootc switch --enforce-container-sigpolicy ghcr.io/zelf/gnome:latest
```

## Updating

```bash
sudo bootc update
```

Replace `gnome` with `cosmic` in all commands above if using the COSMIC variant.
