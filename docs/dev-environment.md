# Dev Environment

This guide covers developer tooling and dotfiles setup for local machines and remote dev hosts.

Use `scripts/configure-dev.sh` for automated installs. Manual commands are listed here as references and verification steps.

## Scripted Setup

Run the installer:

```sh
./scripts/configure-dev.sh
```

Skip auto-stow if needed:

```sh
./scripts/configure-dev.sh --skip-stow
```

### `configure-dev.sh` args

- `--skip-stow`: Skip the final `stow` pass that symlinks files from `home/` into `~`.
- `-h`, `--help`: Print usage and exit.

Argument notes:

- Unknown args fail fast with an error and usage output.
- Args can be combined (currently only `--skip-stow` is actionable).
- No args means full install + stow.

Supported OSes:

- macOS
- Ubuntu Linux

Notes:

- Ghostty is installed only on macOS.
- On macOS, Xcode Command Line Tools are installed first when missing.
- On macOS and Ubuntu, Node.js LTS is installed with `pnpm env use --global lts`.
- On macOS and Ubuntu, Rust stable is installed with rustup and includes `rustfmt` + `clippy`.
- On Ubuntu, Neovim is installed from the official release tarball.

## Dotfiles with Stow

Winston stores home-directory files under `home/` and symlinks them into `~`.

`scripts/configure-dev.sh` runs this stow command automatically by default.

```sh
stow --dotfiles -R -v -t ~ -d ~/github.com/adamaho/winston/home .
```

The helper script `scripts/install.sh` runs this same command and accepts no args.

Notes:

- Dotfiles can be represented as real dotfiles (for example `home/.config/nvim`) or `dot-` names (for example `home/dot-config/nvim`) with `--dotfiles`.
- The `home/` structure should mirror where files should appear in your home directory.

## zsh and Oh My Zsh

Install zsh and set it as default shell:

```sh
zsh --version
chsh -s "$(which zsh)"
```

Install Oh My Zsh:

```sh
sh -c "$(wget https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh -O -)"
```

Log out and back in, then verify:

```sh
echo "$SHELL"
```

## Core CLI Tools

Install and verify:

- `stow`
- `ripgrep` (`rg`)
- `lazygit`
- `aws` (AWS CLI)
- `tmux`
- `git`
- `node`
- `pnpm`
- `rustup`
- `cargo`
- `rustc`
- `rustfmt`
- `opencode`

`scripts/configure-dev.sh` is the canonical installer for these tools.

## Ghostty

On your local machine, configure Ghostty at `~/.config/ghostty/config`.

If connecting to a remote machine from Ghostty, copy Ghostty terminfo to the remote host:

```sh
infocmp -x xterm-ghostty | ssh <username>@<host> -- tic -x -
```

The warning about older `tic` versions treating the description field as an alias is safe to ignore.

## Neovim, Lua, LuaRocks, and Rust

Install `nvim`, `lua`, `luarocks`, and Rust tooling, then verify:

```sh
nvim --version
lua -v
luarocks --version
rustup --version
cargo --version
rustc --version
rustfmt --version
```

`scripts/configure-dev.sh` should manage installation across supported OSes.

## tmux Plugin Manager (TPM)

Install TPM:

```sh
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
```

After starting `tmux`, run `Prefix + I` to install plugins.

## Git SSH and Identity

Generate and add an SSH key:

```sh
ssh-keygen -t ed25519 -C "your_email@example.com"
cat ~/.ssh/<key-name>.pub
ssh -T git@github.com
```

Set Git identity:

```sh
git config --global user.email "you@example.com"
git config --global user.name "Your Name"
```

## Node, pnpm, and opencode

If not installed by `scripts/configure-dev.sh`, install manually:

macOS:

```sh
brew install pnpm
pnpm env use --global lts
pnpm install -g opencode-ai
```

Ubuntu:

```sh
curl -fsSL https://get.pnpm.io/install.sh | sh -
export PNPM_HOME="$HOME/.local/share/pnpm"
export PATH="$PNPM_HOME:$PATH"
pnpm env use --global lts
pnpm install -g opencode-ai
```

Authenticate opencode:

```sh
opencode auth login
```
