# Winston

Winston is a dotfiles + setup repo for SSH-based development.

## Quickstart

1. Configure Ubuntu VPS system settings with `scripts/configure-vps.sh`.
2. Install development tooling (Node, Rust, Neovim, etc.) on your host or VPS with `scripts/configure-dev.sh`.
3. Dotfiles are stowed automatically by `scripts/configure-dev.sh` (use `--skip-stow` to skip).

## Script Args Reference

### `scripts/configure-vps.sh`

- `--all`: Run core setup (`--disable-root-login`, `--upgrade`, `--configure-grub`, `--install-tailscale`, `--configure-ufw`).
- `--disable-root-login`: Set `PermitRootLogin no` and restart SSH.
- `--upgrade`: Run `apt update && apt upgrade -y`.
- `--configure-grub`: Set GRUB defaults and run `update-grub`.
- `--install-tailscale`: Install Tailscale.
- `--configure-ufw`: Configure UFW for SSH + `tailscale0`.
- `--install-nvidia`: Run `ubuntu-drivers autoinstall`.
- `--reboot`: Reboot when script finishes.
- `-h`, `--help`: Show usage.

### `scripts/configure-dev.sh`

- `--skip-stow`: Skip the final dotfiles stow step.
- `-h`, `--help`: Show usage.

### `scripts/install.sh`

- No arguments. Runs stow for dotfiles using the repository path in the script.

## Documentation

- VPS system setup: `docs/vps-ubuntu.md`
- Dev environment setup: `docs/dev-environment.md`
