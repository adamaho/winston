# Winston

### Disable root login over ssh
- in `/etc/ssh/sshd_config` find `PermitRootLogin` and change its value to `no`. Note it might be commented out.
- restart ssh service in systemd `sudo systemctl restart ssh.service`
- in another terminal confirm that you get `Permission Denied` error by trying to ssh as root via `ssh root@<server-ip>`
- `exit` session in both terminals and try logging in with `ssh <user>@<server-ip>`

### Upgrade Deps

```
sudo apt update && sudo apt upgrade
```

### Change GRUB Settings

By default GRUB will open when the server reboots. We want to auto-select `ubuntu`. Modify the `/etc/default/grub` config with `sudo` the following:

```sh
GRUB_TIMEOUT_STYLE=menu
GRUB_TIMEOUT=5
GRUB_TERMINAL=console
```

Then run `sudo update-grub` to pull in the latest changes and `sudo reboot` to test to make sure it works. You'll know it works if you can ssh back in after a minute or so.

### Install and Configure Tailscale

Tailscale provides an all-in-one vpn solution. This will allow my devices to talk to the server from outside of my home network. Visit https://tailscale.com/kb/1031/install-linux and install for your version of linux. Then install tailscale on any of the devices you plan to connect to the server with. P.S Tailscale is GOATED.

Now you can access your server from within the tailscale network. Try a couple commands out:

```sh
ping <server-name> (winston)
ssh <username>@<server-name>
```

### Configure Firewall

We only need to allow traffic into the server for a for development. Now that we have tailscale configured we can add firewall rules to only allow traffic into the server that comes from tailscale.

First we need to ssh to the server over tailscale with `ssh <username>@<100.x.y.z>`. The IP address comes from the server in the tailscale dashboard.

```sh
sudo ufw enable
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow in on tailscale0
sudo ufw reload
sudo service ssh restart
```

Verify the configuration with `sudo ufw status` and you should see something like:

```
Status: active

To                         Action      From
--                         ------      ----
Anywhere on tailscale0     ALLOW       Anywhere
Anywhere (v6) on tailscale0 ALLOW       Anywhere (v6)
```

## Configure GPU

Note: this assumes you are configuring a server that is built of gaming computer parts. So consumer GPUs like GeForce. This means you might need to disable SecureBoot.

If you have an NVDIA GPU you can do the following `sudo ubuntu-drivers autoinstall` and then reboot your server with `sudo reboot`. Then you can confirm that it works by running `nvidia-smi` and should return something like the following.

```
+-----------------------------------------------------------------------------------------+
| NVIDIA-SMI 570.133.07             Driver Version: 570.133.07     CUDA Version: 12.8     |
|-----------------------------------------+------------------------+----------------------+
| GPU  Name                 Persistence-M | Bus-Id          Disp.A | Volatile Uncorr. ECC |
| Fan  Temp   Perf          Pwr:Usage/Cap |           Memory-Usage | GPU-Util  Compute M. |
|                                         |                        |               MIG M. |
|=========================================+========================+======================|
|   0  NVIDIA GeForce GTX 1050 Ti     Off |   00000000:01:00.0 Off |                  N/A |
|  0%   32C    P8            N/A  /   95W |       3MiB /   4096MiB |      0%      Default |
|                                         |                        |                  N/A |
+-----------------------------------------+------------------------+----------------------+

+-----------------------------------------------------------------------------------------+
| Processes:                                                                              |
|  GPU   GI   CI              PID   Type   Process name                        GPU Memory |
|        ID   ID                                                               Usage      |
|=========================================================================================|
|  No running processes found                                                             |
+-----------------------------------------------------------------------------------------+
```

### Install C and Other C Like Libs

In order for the full dev workflow to work we need to install c and adjecent c languages `sudo apt update && sudo apt install build-essential`.

### Install zsh

1. Install `sudo apt install zsh`
2. Make it the default shell `chsh -s $(which zsh)`
3. Logout of ssh session and log back in again and test with `echo $SHELL` which should return `/bin/zsh`

### Install oh-my-zsh

In order to get some of the fancy command line info like the current git branch, we need oh-my-zsh.

1. Install `sh -c "$(wget https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh -O -)"`

### Configure Stow

Stow allows you to create a symlink between two directories. Super useful for when you want to work on dotfiles and saving to github.

1. Install stow `sudo apt install stow`
2. Create a `home` directory in your dotfiles repo with the structure you want in your home directory
3. From your dotfiles directory (`cd ~/github.com/adamaho/winston`) you can run `stow -R -v -t ~ home` to create the symlinks

For dotfiles (files starting with `.`), you have two options:
- Use actual dotfile names: `home/.config/nvim/` 
- Use `dot-` prefix with `--dotfiles` flag: `home/dot-config/nvim/` and run `stow --dotfiles -R -v -t ~ home`

The `home` directory structure should mirror where you want files to appear in your home directory.


### Install ripgrep

ripgrep is a powerful fuzzy finding tool used by telescope in nvim. But it works independently of nvim.

```
sudo apt install ripgrep
```

### Install lazygit

lazygit is a terminal UI for git commands that integrates with nvim.

```
LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')
curl -Lo /tmp/lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
cd /tmp && tar xf lazygit.tar.gz && sudo install lazygit /usr/local/bin && rm lazygit lazygit.tar.gz
```

## Development

### Install Sqlite3

On unbuntu server, sqlite3 does not come pre-installed. Run `sudo apt install sqlite3` to install.

### Install zip

By default ubuntu server doesn't come with zip and unzip install. Run `sudo apt-get install zip unzip` to install.

### Configure Ghostyy Terminal

Since ghostyy is kind of new we need to make sure the server has the TermInfo for it. You can copy this over with ssh. `infocmp -x xterm-ghostty | ssh adam@winston -- tic -x -`. The `tic` command on the server may give the warning `"<stdin>", line 2, col 31, terminal 'xterm-ghostty': older tic versions may treat the description field as an alias` which can be safely ignored.

Now we need to configure it on your laptop or host computer. Lets do that. Add your config in `~/.config/ghostty/config`

## Install Neovim

The ubunutu apt version of neovim is quite out of date. So we need to install the app image manually.

1. `curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz`
2. `sudo rm -rf /opt/nvim`
3. `sudo tar -C /opt -xzf nvim-linux-x86_64.tar.gz`
4. add `export PATH="$PATH:/opt/nvim-linux-x86_64/bin"` to the bottom of `~/.zshrc`
5. confirm installation dir by running `which nvim`. It should return `/opt/nvim-linux-x86_64/bin/nvim` and then `nvim --version`. You should see something equal to or greater than `0.11`
6. Open with `nvim`

### Install Lua and Luarocks

Some nvim plugins (like rest.nvim) require Lua and luarocks to be installed system-wide:

```
sudo apt-get update && sudo apt-get install -y lua5.1 liblua5.1-0-dev luarocks
```

This enables plugins that use luarocks for dependency management, including XML parsing and other native libraries.

### Configure Tmux 

Tmux lets you create panes, manage layouts, and resume terminal sessions even across reboots.

1. Install with `sudo apt install tmux`
2. Create a new tmux conf in home dir with `touch ~/.tmux.conf`
3. Clone the repo to `~/.tmux/plugins/tpm` via `git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm`

Finally, add your tmux config to `~/.tmux.conf` and if you are using `tpm` don't forget to run `Prefix + I` to install the plugins. 

### Configure Git

Set up the ssh key
1. `ssh-keygen -t ed25519 -C "your_email@example.com"`
2. `cat ~/.ssh/<key-name>.pub`
3. create new key in github
4. test with `ssh -T git@github.com`

Set username and email:

`git config --global user.email "you@example.com"`
`git config --global user.name "Your Name"`

### Install Node

1. install nvm `curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash`
2. exit ssh session and log back in
3. `nvm install 22` or the latest node version
4. `nvm alias default 22`

You can test with `node -v`.

### Install pnpm

`npm install -g pnpm@latest-10`

You can test with `pnpm -v`

### Install Bun

`curl -fsSL https://bun.com/install | bash`

### Install ROS

Follow the instructions [here](https://docs.ros.org/en/jazzy/Installation/Ubuntu-Install-Debs.html#system-setup) to install ROS.

### Install opencode 

`pnpm install -g opencode-ai` then run opencode auth login to login to any of the providers.

