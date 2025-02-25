# Bootc

Fedora by default does not have bootc. So we need to use rpm-ostree first to load our custom image.
First we allow the unsigned image because our key is not stored on our system yet. 
```bash
rpm-ostree rebase ostree-unverified-registry:ghcr.io/zelf/sway:latest
```

```bash
systemctl reboot
```

Now the custom image is loaded, we can use the signed version:
```bash
rpm-ostree rebase ostree-image-signed:docker://ghcr.io/zelf/sway:latest
```

```bash
systemctl reboot
```

And now we move to bootc:

```bash
sudo bootc switch ghcr.io/zelf/sway:latest
```

Now to update, use:

```bash
sudo bootc update
```
