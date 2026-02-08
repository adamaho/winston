#!/usr/bin/env bash

set -euo pipefail

SCRIPT_NAME="$(basename "$0")"
SSHD_CONFIG="/etc/ssh/sshd_config"
GRUB_CONFIG="/etc/default/grub"

DO_DISABLE_ROOT_LOGIN=false
DO_UPGRADE=false
DO_CONFIGURE_GRUB=false
DO_INSTALL_TAILSCALE=false
DO_CONFIGURE_UFW=false
DO_INSTALL_NVIDIA=false
DO_REBOOT=false

usage() {
  cat <<EOF
Usage: sudo ./scripts/$SCRIPT_NAME [options]

Configure Ubuntu VPS system settings.

Options:
  --all                 Run core VPS setup tasks
                        (disable root login, upgrade packages, configure grub,
                         install tailscale, configure ufw)
  --disable-root-login  Set PermitRootLogin no and restart SSH service
  --upgrade             Run apt update && apt upgrade -y
  --configure-grub      Set GRUB defaults and run update-grub
  --install-tailscale   Install tailscale package
  --configure-ufw       Lock down UFW to tailscale0 + SSH service restart
  --install-nvidia      Run ubuntu-drivers autoinstall
  --reboot              Reboot at the end of the script
  -h, --help            Show this help

Examples:
  sudo ./scripts/$SCRIPT_NAME --all
  sudo ./scripts/$SCRIPT_NAME --disable-root-login --configure-ufw
  sudo ./scripts/$SCRIPT_NAME --install-nvidia --reboot
EOF
}

log() {
  printf '[%s] %s\n' "$SCRIPT_NAME" "$1"
}

err() {
  printf '[%s] ERROR: %s\n' "$SCRIPT_NAME" "$1" >&2
}

require_root() {
  if [[ "${EUID}" -ne 0 ]]; then
    err "This script must run as root. Try: sudo ./scripts/$SCRIPT_NAME ..."
    exit 1
  fi
}

require_ubuntu() {
  if [[ ! -f /etc/os-release ]]; then
    err "Cannot detect OS: /etc/os-release not found."
    exit 1
  fi

  # shellcheck disable=SC1091
  source /etc/os-release

  if [[ "${ID:-}" != "ubuntu" ]]; then
    err "This script only supports Ubuntu VPS hosts. Detected: ${ID:-unknown}"
    exit 1
  fi
}

ensure_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    err "Missing required command: $1"
    exit 1
  fi
}

backup_file() {
  local target="$1"
  local backup_path
  backup_path="${target}.bak.$(date +%Y%m%d%H%M%S)"
  cp "$target" "$backup_path"
  log "Backed up $target -> $backup_path"
}

restart_ssh_service() {
  if systemctl list-unit-files | grep -q '^ssh\.service'; then
    systemctl restart ssh.service
  elif systemctl list-unit-files | grep -q '^sshd\.service'; then
    systemctl restart sshd.service
  else
    err "Unable to find ssh.service or sshd.service to restart."
    exit 1
  fi
  log "SSH service restarted"
}

set_config_value() {
  local file="$1"
  local key="$2"
  local value="$3"

  if grep -Eq "^\s*#?\s*${key}=" "$file"; then
    sed -i -E "s|^\s*#?\s*${key}=.*|${key}=${value}|" "$file"
  else
    printf '%s=%s\n' "$key" "$value" >>"$file"
  fi
}

disable_root_login() {
  log "Disabling root SSH login"
  ensure_cmd sed
  ensure_cmd systemctl

  backup_file "$SSHD_CONFIG"

  if grep -Eq '^\s*#?\s*PermitRootLogin\s+' "$SSHD_CONFIG"; then
    sed -i -E 's|^\s*#?\s*PermitRootLogin\s+.*|PermitRootLogin no|' "$SSHD_CONFIG"
  else
    printf '\nPermitRootLogin no\n' >>"$SSHD_CONFIG"
  fi

  restart_ssh_service
  log "Root SSH login disabled"
}

upgrade_packages() {
  log "Upgrading apt packages"
  ensure_cmd apt
  export DEBIAN_FRONTEND=noninteractive
  apt update
  apt upgrade -y
  log "Package upgrade complete"
}

configure_grub() {
  log "Configuring GRUB defaults"
  ensure_cmd sed
  ensure_cmd update-grub

  backup_file "$GRUB_CONFIG"

  set_config_value "$GRUB_CONFIG" "GRUB_TIMEOUT_STYLE" "menu"
  set_config_value "$GRUB_CONFIG" "GRUB_TIMEOUT" "5"
  set_config_value "$GRUB_CONFIG" "GRUB_TERMINAL" "console"

  update-grub
  log "GRUB updated"
}

install_tailscale() {
  log "Installing tailscale"
  ensure_cmd curl

  if command -v tailscale >/dev/null 2>&1; then
    log "tailscale is already installed"
    return
  fi

  curl -fsSL https://tailscale.com/install.sh | sh
  log "tailscale installed"
  log "Next: run 'sudo tailscale up' to authenticate this VPS"
}

configure_ufw() {
  log "Configuring UFW for tailscale0"
  ensure_cmd ufw

  if ufw app info OpenSSH >/dev/null 2>&1; then
    ufw allow OpenSSH
  else
    ufw allow 22/tcp
  fi

  ufw --force enable
  ufw default deny incoming
  ufw default allow outgoing
  ufw allow in on tailscale0
  ufw reload

  restart_ssh_service
  log "UFW configured: SSH allowed, inbound tailscale0 allowed"
}

install_nvidia_drivers() {
  log "Installing NVIDIA drivers"
  ensure_cmd ubuntu-drivers
  ubuntu-drivers autoinstall
  log "NVIDIA driver install completed"
  log "Run 'nvidia-smi' after reboot to verify"
}

parse_args() {
  if [[ "$#" -eq 0 ]]; then
    usage
    exit 1
  fi

  while [[ "$#" -gt 0 ]]; do
    case "$1" in
      --all)
        DO_DISABLE_ROOT_LOGIN=true
        DO_UPGRADE=true
        DO_CONFIGURE_GRUB=true
        DO_INSTALL_TAILSCALE=true
        DO_CONFIGURE_UFW=true
        ;;
      --disable-root-login)
        DO_DISABLE_ROOT_LOGIN=true
        ;;
      --upgrade)
        DO_UPGRADE=true
        ;;
      --configure-grub)
        DO_CONFIGURE_GRUB=true
        ;;
      --install-tailscale)
        DO_INSTALL_TAILSCALE=true
        ;;
      --configure-ufw)
        DO_CONFIGURE_UFW=true
        ;;
      --install-nvidia)
        DO_INSTALL_NVIDIA=true
        ;;
      --reboot)
        DO_REBOOT=true
        ;;
      -h|--help)
        usage
        exit 0
        ;;
      *)
        err "Unknown option: $1"
        usage
        exit 1
        ;;
    esac
    shift
  done
}

main() {
  parse_args "$@"
  require_root
  require_ubuntu

  if [[ "$DO_DISABLE_ROOT_LOGIN" == true ]]; then
    disable_root_login
  fi

  if [[ "$DO_UPGRADE" == true ]]; then
    upgrade_packages
  fi

  if [[ "$DO_CONFIGURE_GRUB" == true ]]; then
    configure_grub
  fi

  if [[ "$DO_INSTALL_TAILSCALE" == true ]]; then
    install_tailscale
  fi

  if [[ "$DO_CONFIGURE_UFW" == true ]]; then
    configure_ufw
  fi

  if [[ "$DO_INSTALL_NVIDIA" == true ]]; then
    install_nvidia_drivers
  fi

  log "VPS configuration tasks complete"

  if [[ "$DO_REBOOT" == true ]]; then
    log "Rebooting now"
    reboot
  else
    log "No reboot requested. Use --reboot if needed."
  fi
}

main "$@"
