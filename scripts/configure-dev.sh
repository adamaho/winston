#!/usr/bin/env bash

set -euo pipefail

SCRIPT_NAME="$(basename "$0")"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
OS=""
ARCH="$(uname -m)"
APT_UPDATED=false
DO_STOW=true
PNPM_HOME="${PNPM_HOME:-$HOME/.local/share/pnpm}"
CARGO_HOME="${CARGO_HOME:-$HOME/.cargo}"

log() {
  printf '[%s] %s\n' "$SCRIPT_NAME" "$1"
}

warn() {
  printf '[%s] WARN: %s\n' "$SCRIPT_NAME" "$1" >&2
}

err() {
  printf '[%s] ERROR: %s\n' "$SCRIPT_NAME" "$1" >&2
}

usage() {
  cat <<EOF
Usage: ./$SCRIPT_NAME [options]

Configure development tooling for supported OSes.

Installs:
  zsh, oh-my-zsh, stow, make, ripgrep, lazygit, aws cli, ghostty,
  neovim, lua, luarocks, tmux, git, node, pnpm, rust (rustup/cargo/rustc),
  opencode, github cli

Supported OS:
  - macOS (Homebrew)
  - Ubuntu Linux (apt + official installers)

Notes:
  - On macOS, Homebrew is installed automatically when missing.
  - On macOS and Ubuntu, Node.js is installed with pnpm.

Options:
  --skip-stow   Skip stowing dotfiles at the end
  -h, --help    Show this help
EOF
}

has_cmd() {
  command -v "$1" >/dev/null 2>&1
}

ensure_pnpm_home_path() {
  case ":$PATH:" in
    *":$PNPM_HOME:"*) ;;
    *) export PATH="$PNPM_HOME:$PATH" ;;
  esac
}

ensure_cargo_bin_path() {
  local cargo_bin
  cargo_bin="$CARGO_HOME/bin"

  case ":$PATH:" in
    *":$cargo_bin:"*) ;;
    *) export PATH="$cargo_bin:$PATH" ;;
  esac
}

run_root() {
  if [[ "${EUID}" -eq 0 ]]; then
    "$@"
  else
    sudo "$@"
  fi
}

detect_os() {
  case "$(uname -s)" in
    Darwin)
      OS="macos"
      ;;
    Linux)
      if [[ ! -f /etc/os-release ]]; then
        err "Linux detected but /etc/os-release is missing"
        exit 1
      fi

      # shellcheck disable=SC1091
      source /etc/os-release
      if [[ "${ID:-}" == "ubuntu" ]]; then
        OS="ubuntu"
      else
        err "Unsupported Linux distro: ${ID:-unknown}. Supported: ubuntu"
        exit 1
      fi
      ;;
    *)
      err "Unsupported OS: $(uname -s)"
      exit 1
      ;;
  esac

  log "Detected OS: $OS ($ARCH)"
}

ensure_brew() {
  if [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [[ -x /usr/local/bin/brew ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi

  if has_cmd brew; then
    log "Homebrew already installed"
    return
  fi

  if [[ " $(id -Gn) " != *" admin "* ]]; then
    err "Homebrew install requires a macOS Administrator account."
    err "Current user '$USER' is not in the admin group."
    err "Switch to an admin user, then re-run ./$SCRIPT_NAME"
    exit 1
  fi

  log "Installing Homebrew"
  if [[ -t 0 ]]; then
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  else
    err "Homebrew install needs an interactive terminal for sudo/password prompts."
    err "Run this script directly in your local terminal."
    exit 1
  fi

  if [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [[ -x /usr/local/bin/brew ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi

  if ! has_cmd brew; then
    err "Homebrew install completed but brew is still unavailable"
    exit 1
  fi
}

ensure_clt_macos() {
  if xcode-select -p >/dev/null 2>&1; then
    log "Xcode Command Line Tools already installed"
    return
  fi

  log "Installing Xcode Command Line Tools"
  if [[ -t 0 ]]; then
    xcode-select --install || true
    err "Finish installing Xcode Command Line Tools, then re-run ./$SCRIPT_NAME"
  else
    err "Xcode Command Line Tools are required on macOS"
    err "Run 'xcode-select --install' in a local terminal, then re-run ./$SCRIPT_NAME"
  fi
  exit 1
}

apt_update_once() {
  if [[ "$APT_UPDATED" == true ]]; then
    return
  fi

  log "Running apt update"
  run_root apt update
  APT_UPDATED=true
}

install_oh_my_zsh() {
  if [[ -d "$HOME/.oh-my-zsh" ]]; then
    log "oh-my-zsh already installed"
    return
  fi

  log "Installing oh-my-zsh"
  if has_cmd curl; then
    RUNZSH=no CHSH=no KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
  elif has_cmd wget; then
    RUNZSH=no CHSH=no KEEP_ZSHRC=yes sh -c "$(wget https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh -O -)"
  else
    warn "Skipping oh-my-zsh install: curl/wget not available"
    return
  fi
}

ensure_zsh_default_shell() {
  local zsh_path
  local current_shell
  zsh_path="$(command -v zsh)"
  current_shell=""

  if [[ "$OS" == "macos" ]]; then
    local dscl_output
    dscl_output="$(dscl . -read "/Users/$USER" UserShell 2>/dev/null || true)"
    current_shell="${dscl_output#*UserShell: }"
  else
    local passwd_entry
    passwd_entry="$(getent passwd "$USER" 2>/dev/null || true)"
    if [[ -n "$passwd_entry" ]]; then
      IFS=':' read -r _ _ _ _ _ _ current_shell <<<"$passwd_entry"
    fi
  fi

  if [[ "$current_shell" == "$zsh_path" ]]; then
    log "zsh already configured as default shell"
    return
  fi

  if [[ "$OS" == "macos" ]]; then
    if ! grep -qx "$zsh_path" /etc/shells 2>/dev/null; then
      log "Adding $zsh_path to /etc/shells"
      run_root sh -c "printf '%s\n' '$zsh_path' >> /etc/shells"
    fi
  fi

  log "Setting zsh as default shell for $USER"
  if chsh -s "$zsh_path" "$USER"; then
    local updated_shell
    updated_shell=""
    if [[ "$OS" == "macos" ]]; then
      local updated_dscl
      updated_dscl="$(dscl . -read "/Users/$USER" UserShell 2>/dev/null || true)"
      updated_shell="${updated_dscl#*UserShell: }"
    else
      local updated_passwd
      updated_passwd="$(getent passwd "$USER" 2>/dev/null || true)"
      if [[ -n "$updated_passwd" ]]; then
        IFS=':' read -r _ _ _ _ _ _ updated_shell <<<"$updated_passwd"
      fi
    fi

    if [[ "$updated_shell" == "$zsh_path" ]]; then
      log "Default shell is zsh (new sessions only)"
    else
      if [[ "$OS" == "macos" ]]; then
        warn "chsh completed but could not verify default shell. Check with: dscl . -read /Users/$USER UserShell"
      else
        warn "chsh completed but could not verify default shell. Check with: getent passwd $USER"
      fi
    fi
  else
    warn "Could not change default shell automatically; run: chsh -s $zsh_path"
  fi
}

ensure_pnpm() {
  if has_cmd pnpm; then
    log "pnpm already installed: $(pnpm -v)"
    ensure_pnpm_home_path
    return
  fi

  if has_cmd corepack; then
    log "Installing pnpm via corepack"
    corepack enable
    corepack prepare pnpm@latest --activate
  elif has_cmd npm; then
    log "Installing pnpm via npm"
    npm install -g pnpm@latest-10
  else
    log "Installing pnpm via official install script"
    curl -fsSL https://get.pnpm.io/install.sh | sh -
  fi

  ensure_pnpm_home_path

  if ! has_cmd pnpm; then
    err "pnpm install completed but pnpm is still unavailable"
    exit 1
  fi

  log "pnpm installed: $(pnpm -v)"
}

install_node_with_pnpm() {
  ensure_pnpm_home_path

  if [[ -x "$PNPM_HOME/node" ]]; then
    log "pnpm-managed node already installed: $("$PNPM_HOME/node" -v)"
    return
  fi

  log "Installing Node.js LTS with pnpm"
  pnpm env use --global lts

  if [[ -x "$PNPM_HOME/node" ]]; then
    log "node installed via pnpm: $("$PNPM_HOME/node" -v)"
  else
    warn "Node install via pnpm may have failed; '$PNPM_HOME/node' not found"
  fi
}

install_rust_toolchain() {
  ensure_cargo_bin_path

  if has_cmd rustup; then
    log "rustup already installed: $(rustup --version | head -n 1)"
  else
    if ! has_cmd curl; then
      err "curl is required to install rustup"
      exit 1
    fi

    log "Installing Rust stable toolchain with rustup"
    curl -fsSL https://sh.rustup.rs | sh -s -- -y --default-toolchain stable
  fi

  ensure_cargo_bin_path

  if ! has_cmd rustup; then
    err "rustup install completed but rustup is still unavailable"
    exit 1
  fi

  log "Ensuring Rust stable toolchain and components"
  rustup toolchain install stable
  rustup default stable
  rustup component add rustfmt clippy

  if has_cmd rustc; then
    log "rustc installed: $(rustc --version)"
  else
    warn "Rust install may have failed; rustc not found"
  fi

  if has_cmd cargo; then
    log "cargo installed: $(cargo --version)"
  else
    warn "Rust install may have failed; cargo not found"
  fi
}

install_opencode() {
  if has_cmd opencode; then
    log "opencode already installed"
    return
  fi

  log "Installing opencode"
  pnpm add -g opencode-ai
}

stow_dotfiles() {
  if [[ "$DO_STOW" != true ]]; then
    log "Skipping dotfile stow (--skip-stow)"
    return
  fi

  if ! has_cmd stow; then
    warn "stow not found; skipping dotfile symlink step"
    return
  fi

  if [[ ! -d "$REPO_ROOT/home" ]]; then
    warn "Dotfiles directory not found at $REPO_ROOT/home; skipping stow"
    return
  fi

  local backup_root
  backup_root="$HOME/.winston-backups/stow-$(date +%Y%m%d%H%M%S)"

  backup_existing_path() {
    local target_abs="$1"
    if [[ ! -e "$target_abs" || -L "$target_abs" ]]; then
      return
    fi

    local target_rel
    local backup_path
    target_rel="${target_abs#"$HOME"/}"
    backup_path="$backup_root/$target_rel"
    mkdir -p "$(dirname "$backup_path")"
    mv "$target_abs" "$backup_path"
    log "Backed up existing file: $target_abs -> $backup_path"
  }

  run_stow_with_backup() {
    local stow_dir="$1"
    local target_dir="$2"
    shift 2

    local output
    local status=0
    output="$(stow --dotfiles -v -t "$target_dir" -d "$stow_dir" "$@" 2>&1)" || status=$?
    printf '%s\n' "$output"

    if [[ "$status" -eq 0 ]]; then
      return
    fi

    if ! printf '%s\n' "$output" | grep -q "cannot stow"; then
      err "stow failed for an unknown reason"
      return "$status"
    fi

    local moved_any=false

    while IFS= read -r line; do
      case "$line" in
        *"cannot stow "*"existing target "*)
          local target_rel
          local target_abs
          local backup_path

          target_rel="${line#* existing target }"
          target_rel="${target_rel%% since*}"
          target_abs="$target_dir/$target_rel"

          if [[ -e "$target_abs" && ! -L "$target_abs" ]]; then
            backup_path="$backup_root/$target_rel"
            mkdir -p "$(dirname "$backup_path")"
            mv "$target_abs" "$backup_path"
            moved_any=true
            log "Backed up existing file: $target_abs -> $backup_path"
          fi
          ;;
      esac
    done < <(printf '%s\n' "$output")

    if [[ "$moved_any" != true ]]; then
      err "stow reported conflicts, but no files were backed up automatically"
      return "$status"
    fi

    log "Retrying stow after backing up conflicting files"
    stow --dotfiles -v -t "$target_dir" -d "$stow_dir" "$@"
  }

  log "Linking top-level dotfiles from $REPO_ROOT/home"
  local top_level_dotfile
  for top_level_dotfile in .zshrc .tmux.conf; do
    if [[ ! -e "$REPO_ROOT/home/$top_level_dotfile" ]]; then
      continue
    fi
    backup_existing_path "$HOME/$top_level_dotfile"
    ln -sfn "$REPO_ROOT/home/$top_level_dotfile" "$HOME/$top_level_dotfile"
  done

  if [[ -d "$REPO_ROOT/home/dot-config" ]]; then
    mkdir -p "$HOME/.config"
    log "Stowing .config entries from $REPO_ROOT/home/dot-config"
    run_stow_with_backup "$REPO_ROOT/home" "$HOME/.config" dot-config
  fi
}

install_neovim_ubuntu() {
  if has_cmd nvim; then
    log "neovim already installed: $(nvim --version | head -n 1)"
    return
  fi

  local nvim_arch
  case "$ARCH" in
    x86_64|amd64)
      nvim_arch="x86_64"
      ;;
    arm64|aarch64)
      nvim_arch="arm64"
      ;;
    *)
      warn "Unsupported architecture for Neovim tarball ($ARCH), falling back to apt"
      apt_update_once
      run_root apt install -y neovim
      return
      ;;
  esac

  local tarball="nvim-linux-${nvim_arch}.tar.gz"
  local url="https://github.com/neovim/neovim/releases/latest/download/${tarball}"
  local tmp_dir
  tmp_dir="$(mktemp -d)"

  log "Installing Neovim from official release"
  curl -fsSL "$url" -o "$tmp_dir/$tarball"
  run_root rm -rf /opt/nvim
  run_root mkdir -p /opt
  run_root tar -C /opt -xzf "$tmp_dir/$tarball"
  run_root ln -sf "/opt/nvim-linux-${nvim_arch}/bin/nvim" /usr/local/bin/nvim
  rm -rf "$tmp_dir"
}

install_lazygit_ubuntu() {
  if has_cmd lazygit; then
    log "lazygit already installed"
    return
  fi

  if apt-cache show lazygit >/dev/null 2>&1; then
    apt_update_once
    run_root apt install -y lazygit
    return
  fi

  log "Installing lazygit from GitHub release"
  local version
  version="$(curl -fsSL https://api.github.com/repos/jesseduffield/lazygit/releases/latest | sed -n 's/.*"tag_name": "v\([^"]*\)".*/\1/p' | head -n 1)"
  if [[ -z "$version" ]]; then
    err "Could not determine latest lazygit version"
    exit 1
  fi

  local lazygit_arch
  case "$ARCH" in
    x86_64|amd64)
      lazygit_arch="x86_64"
      ;;
    arm64|aarch64)
      lazygit_arch="arm64"
      ;;
    *)
      err "Unsupported architecture for lazygit release archive: $ARCH"
      exit 1
      ;;
  esac

  local tmp_dir
  tmp_dir="$(mktemp -d)"
  local archive="lazygit_${version}_Linux_${lazygit_arch}.tar.gz"
  curl -fsSL "https://github.com/jesseduffield/lazygit/releases/latest/download/${archive}" -o "$tmp_dir/$archive"
  tar -C "$tmp_dir" -xzf "$tmp_dir/$archive"
  run_root install "$tmp_dir/lazygit" /usr/local/bin/lazygit
  rm -rf "$tmp_dir"
}

install_awscli_ubuntu() {
  if has_cmd aws; then
    log "aws cli already installed"
    return
  fi

  apt_update_once
  run_root apt install -y unzip

  log "Installing AWS CLI v2"
  local awscli_arch
  case "$ARCH" in
    x86_64|amd64)
      awscli_arch="x86_64"
      ;;
    arm64|aarch64)
      awscli_arch="aarch64"
      ;;
    *)
      err "Unsupported architecture for AWS CLI v2 installer: $ARCH"
      exit 1
      ;;
  esac

  local tmp_dir
  tmp_dir="$(mktemp -d)"
  curl -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-${awscli_arch}.zip" -o "$tmp_dir/awscliv2.zip"
  unzip -q "$tmp_dir/awscliv2.zip" -d "$tmp_dir"
  run_root "$tmp_dir/aws/install" --update
  rm -rf "$tmp_dir"
}

install_github_cli_ubuntu() {
  if has_cmd gh; then
    log "github cli already installed"
    return
  fi

  apt_update_once
  run_root apt install -y curl ca-certificates

  log "Installing GitHub CLI"
  run_root install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | run_root tee /etc/apt/keyrings/githubcli-archive-keyring.gpg >/dev/null
  run_root chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg
  run_root sh -c 'echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" > /etc/apt/sources.list.d/github-cli.list'

  APT_UPDATED=false
  apt_update_once
  run_root apt install -y gh
}

install_ghostty_ubuntu() {
  if has_cmd ghostty; then
    log "ghostty already installed"
    return
  fi

  log "Installing Ghostty on Ubuntu"
  if ! /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/mkasberg/ghostty-ubuntu/HEAD/install.sh)"; then
    warn "Ghostty install failed; continuing without ghostty"
  fi
}

ensure_telescope_fzf_native() {
  if ! has_cmd nvim; then
    warn "neovim not found; skipping telescope-fzf-native setup"
    return
  fi

  local nvim_config_dir="$HOME/.config/nvim"
  local plugin_dir="$HOME/.local/share/nvim/lazy/telescope-fzf-native.nvim"
  local library_path="$plugin_dir/build/libfzf.so"

  if [[ -f "$library_path" ]]; then
    log "telescope-fzf-native already built"
    return
  fi

  if [[ ! -d "$nvim_config_dir" ]]; then
    warn "Neovim config not found at $nvim_config_dir; skipping telescope-fzf-native setup"
    return
  fi

  log "Syncing Neovim plugins"
  if ! nvim --headless "+Lazy! sync" "+qa" >/dev/null 2>&1; then
    warn "Could not sync Neovim plugins automatically; run: nvim --headless \"+Lazy! sync\" \"+qa\""
  fi

  if [[ ! -d "$plugin_dir" ]]; then
    warn "telescope-fzf-native plugin not found after sync; run :Lazy sync in Neovim"
    return
  fi

  log "Building telescope-fzf-native"
  if ! make -C "$plugin_dir"; then
    warn "Failed to build telescope-fzf-native; run: make -C $plugin_dir"
    return
  fi

  if [[ -f "$library_path" ]]; then
    log "telescope-fzf-native built successfully"
  else
    warn "Build finished but $library_path is missing"
  fi
}

configure_ghostty_shell() {
  local zsh_path
  local ghostty_dir="$HOME/.config/ghostty"
  local ghostty_config="$ghostty_dir/config"
  local desired_command

  zsh_path="$(command -v zsh 2>/dev/null || true)"
  if [[ -z "$zsh_path" ]]; then
    warn "zsh not found; skipping Ghostty shell configuration"
    return
  fi

  desired_command="command = $zsh_path --login"

  if ! has_cmd ghostty && [[ ! -e "$ghostty_config" ]]; then
    log "Ghostty not installed; skipping shell command configuration"
    return
  fi

  mkdir -p "$ghostty_dir"

  if [[ -L "$ghostty_config" ]]; then
    log "Ghostty config is symlinked; shell command managed by dotfiles"
    return
  fi

  if [[ ! -f "$ghostty_config" ]]; then
    printf '%s\n' "$desired_command" > "$ghostty_config"
    log "Configured Ghostty to launch zsh login shell"
    return
  fi

  if grep -Fqx "$desired_command" "$ghostty_config"; then
    log "Ghostty already configured to launch zsh login shell"
    return
  fi

  local tmp_config
  tmp_config="$(mktemp)"
  awk -v command_line="$desired_command" '
    BEGIN { replaced=0 }
    /^command = / {
      if (replaced == 0) {
        print command_line
        replaced=1
      }
      next
    }
    { print }
    END {
      if (replaced == 0) {
        print command_line
      }
    }
  ' "$ghostty_config" > "$tmp_config"
  mv "$tmp_config" "$ghostty_config"

  log "Updated Ghostty shell command to zsh login shell"
}

configure_github_cli() {
  if ! has_cmd gh; then
    warn "github cli not found; skipping configuration"
    return
  fi

  if gh auth status >/dev/null 2>&1; then
    log "Configuring GitHub CLI git integration"
    gh auth setup-git >/dev/null 2>&1 || warn "Could not configure gh git integration automatically; run: gh auth setup-git"
  else
    log "GitHub CLI installed. Authenticate with: gh auth login"
  fi
}

install_macos() {
  ensure_clt_macos
  ensure_brew

  log "Installing macOS packages with Homebrew"
  brew update
  brew install zsh stow make ripgrep lazygit awscli neovim lua luarocks tmux git pnpm gh

  if brew list --cask ghostty >/dev/null 2>&1; then
    log "ghostty already installed via Homebrew cask"
  elif [[ -d "/Applications/Ghostty.app" ]]; then
    warn "Ghostty.app already exists in /Applications; attempting Homebrew install with --force"
    brew install --cask --force ghostty
  else
    brew install --cask ghostty
  fi
}

install_ubuntu() {
  apt_update_once

  log "Installing Ubuntu packages with apt"
  run_root apt install -y \
    zsh \
    stow \
    build-essential \
    make \
    ripgrep \
    tmux \
    git \
    curl \
    wget \
    ca-certificates \
    gnupg \
    lua5.1 \
    liblua5.1-0-dev \
    luarocks

  install_lazygit_ubuntu
  install_awscli_ubuntu
  install_neovim_ubuntu
  install_github_cli_ubuntu
  install_ghostty_ubuntu
}

print_summary() {
  log "Installation complete. Verifying key tools:"

  local tools=(zsh stow make rg lazygit aws nvim lua luarocks tmux git node pnpm rustup cargo rustc rustfmt gh opencode)
  local tool
  for tool in "${tools[@]}"; do
    if has_cmd "$tool"; then
      printf '  - %-8s %s\n' "$tool" "OK"
    else
      printf '  - %-8s %s\n' "$tool" "MISSING"
    fi
  done

  if [[ "$OS" == "macos" ]]; then
    if [[ -d "/Applications/Ghostty.app" ]]; then
      printf '  - %-8s %s\n' "ghostty" "OK"
    else
      printf '  - %-8s %s\n' "ghostty" "MISSING"
    fi
  else
    if has_cmd ghostty; then
      printf '  - %-8s %s\n' "ghostty" "OK"
    else
      printf '  - %-8s %s\n' "ghostty" "MISSING"
    fi
  fi

  log "Next steps:"
  log "1) Open a new shell session"
  log "2) Run: gh auth login && gh auth setup-git"
  log "3) Run: opencode auth login"
}

main() {
  while [[ "$#" -gt 0 ]]; do
    case "$1" in
      --skip-stow)
        DO_STOW=false
        ;;
      -h|--help)
        usage
        exit 0
        ;;
      *)
        err "Unknown argument: $1"
        usage
        exit 1
        ;;
    esac
    shift
  done

  detect_os

  case "$OS" in
    macos)
      install_macos
      ;;
    ubuntu)
      install_ubuntu
      ;;
  esac

  install_oh_my_zsh
  ensure_zsh_default_shell
  ensure_pnpm
  ensure_pnpm_home_path
  install_node_with_pnpm
  install_rust_toolchain
  install_opencode
  configure_github_cli
  stow_dotfiles
  ensure_telescope_fzf_native
  configure_ghostty_shell
  print_summary
}

main "$@"
