# Ubuntu VPS Configuration

This guide covers VPS-only system configuration steps. These are server hardening and networking tasks, not day-to-day dev tooling installs.

## Disable Root Login Over SSH

1. Edit `/etc/ssh/sshd_config` and set `PermitRootLogin no` (it may be commented out).
2. Restart SSH: `sudo systemctl restart ssh.service`
3. In another terminal, verify root login fails: `ssh root@<server-ip>`
4. Confirm normal login still works: `ssh <user>@<server-ip>`

## Upgrade System Packages

```sh
sudo apt update && sudo apt upgrade
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

Install Tailscale for Linux by following: https://tailscale.com/kb/1031/install-linux

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
