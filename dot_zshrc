# =============================
# zsh オプション
# =============================
setopt AUTO_CD
setopt INTERACTIVE_COMMENTS

# =============================
# 履歴
# =============================
HISTFILE="$HOME/.zsh_history"
HISTSIZE=50000
SAVEHIST=50000
setopt SHARE_HISTORY
setopt HIST_IGNORE_ALL_DUPS

# =============================
# 補完
# =============================
if type brew &>/dev/null; then
  FPATH="$(brew --prefix)/share/zsh/site-functions:$FPATH"
fi
autoload -Uz compinit && compinit
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'

# =============================
# キーバインド
# =============================
bindkey -e

# =============================
# エイリアス
# =============================
alias grep='grep --color=auto'
alias ..='cd ..'
alias ...='cd ../..'

# =============================
# 関数
# =============================
mkcd() { mkdir -p "$1" && cd "$1"; }

# =============================
# プロンプト
# =============================
autoload -Uz vcs_info
precmd() { vcs_info }
zstyle ':vcs_info:git:*' formats ' (%b)'
setopt PROMPT_SUBST
PROMPT='%F{cyan}%n@%m%f:%F{yellow}%~%f%F{green}${vcs_info_msg_0_}%f $ '
