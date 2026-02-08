# Ubuntu VPS Configuration

This guide covers VPS-only system configuration steps. These are server hardening and networking tasks, not day-to-day dev tooling installs.

## Scripted Setup

Run the VPS configurator with one or more flags:

```sh
sudo ./scripts/configure-vps.sh --all
```

### `configure-vps.sh` args

- `--all`: Run core hardening/network setup flags together (`--disable-root-login`, `--upgrade`, `--configure-grub`, `--install-tailscale`, `--configure-ufw`).
- `--disable-root-login`: Set `PermitRootLogin no` in `/etc/ssh/sshd_config` and restart SSH.
- `--upgrade`: Run `apt update` and `apt upgrade -y`.
- `--configure-grub`: Set GRUB defaults (`GRUB_TIMEOUT_STYLE=menu`, `GRUB_TIMEOUT=5`, `GRUB_TERMINAL=console`) and run `update-grub`.
- `--install-tailscale`: Install Tailscale via the official install script.
- `--configure-ufw`: Allow SSH, enable UFW, deny incoming by default, allow incoming on `tailscale0`, then reload UFW.
- `--install-nvidia`: Run `ubuntu-drivers autoinstall`.
- `--reboot`: Reboot after all selected tasks complete.
- `-h`, `--help`: Print usage and exit.

Argument notes:

- You can pass one or many flags in a single run.
- Unknown args fail fast with an error and usage output.
- Script requires root (`sudo`) and Ubuntu.

Common examples:

```sh
sudo ./scripts/configure-vps.sh --disable-root-login --configure-ufw
sudo ./scripts/configure-vps.sh --configure-grub --reboot
sudo ./scripts/configure-vps.sh --install-nvidia --reboot
```

Use `--help` for the full option list.

## Disable Root Login Over SSH

1. Edit `/etc/ssh/sshd_config` and set `PermitRootLogin no` (it may be commented out).
2. Restart SSH: `sudo systemctl restart ssh.service`
3. In another terminal, verify root login fails: `ssh root@<server-ip>`
4. Confirm normal login still works: `ssh <user>@<server-ip>`

## Upgrade System Packages

```sh
sudo apt update && sudo apt upgrade -y
```

## Configure GRUB Boot Selection

By default GRUB can pause at boot. Set a short timeout and auto-select Ubuntu in `/etc/default/grub`:

```sh
GRUB_TIMEOUT_STYLE=menu
GRUB_TIMEOUT=5
GRUB_TERMINAL=console
```

Then apply and reboot:

```sh
sudo update-grub
sudo reboot
```

If the reboot succeeds, you should be able to SSH back in after about a minute.

## Install and Configure Tailscale

Tailscale lets your devices securely reach the VPS from outside your local network.

Install Tailscale for Linux by following the official guide: https://tailscale.com/kb/1031/install-linux

After setup, test reachability:

```sh
ping <server-name>
ssh <username>@<server-name>
```

## Configure UFW for Tailscale-Only Access

SSH to the server over Tailscale first:

```sh
ssh <username>@<100.x.y.z>
```

Apply firewall rules:

```sh
sudo ufw enable
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow in on tailscale0
sudo ufw reload
sudo service ssh restart
```

Verify status:

```sh
sudo ufw status
```

Expected output includes:

```text
Anywhere on tailscale0        ALLOW  Anywhere
Anywhere (v6) on tailscale0   ALLOW  Anywhere (v6)
```

## Optional: Configure NVIDIA GPU Drivers

If your VPS has an NVIDIA GPU, install drivers with:

```sh
sudo ubuntu-drivers autoinstall
sudo reboot
```

Verify installation:

```sh
nvidia-smi
```

## Next Step

After VPS system setup is complete, install development tools with `scripts/configure-dev.sh`.
