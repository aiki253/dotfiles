# ~/.zshenv
export LANG="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"

export EDITOR="vim"
export VISUAL="$EDITOR"

# Homebrew (Apple Silicon)
if [[ -x /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# uv tool install で入るバイナリ
export PATH="$HOME/.local/bin:$PATH"

# PostgreSQL クライアント (keg-only)
[[ -d /opt/homebrew/opt/postgresql@17/bin ]] && export PATH="/opt/homebrew/opt/postgresql@17/bin:$PATH"
