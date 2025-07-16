# History
HISTSIZE=1000
SAVEHIST=2000
setopt APPEND_HISTORY

# Colors and completion
autoload -U colors compinit && colors && compinit

# Aliases
alias ls='ls --color=auto'
alias ll='ls -alF'

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# opencode
export PATH=/home/adam/.opencode/bin:$PATH

# pnpm
export PNPM_HOME="/home/adam/.local/share/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac

# neovim
export PATH="$PATH:/opt/nvim-linux-x86_64/bin"
