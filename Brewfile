# =======================
# CLI Tools
# =======================

# Core dev
brew "git"
brew "git-lfs"
brew "chezmoi"

# Python ecosystem
brew "pixi"
brew "uv"

# Document / LaTeX
brew "ghostscript"

# Database
brew "postgresql@17", restart_service: :changed

# Mac App Store CLI
brew "mas"

# File system
brew "tree"

# 用途次第で有効化
# brew "go"           # Go 開発するなら
# brew "wakeonlan"    # リモート起動するなら

# =======================
# GUI Apps (Casks)
# =======================

# Editor / Terminal
cask "visual-studio-code"
# cask "iterm2"         # ターミナル替える派なら
# cask "wezterm"        # モダンな選択肢

# Browser
cask "google-chrome"
# cask "firefox"
# cask "arc"

# Utility
cask "scroll-reverser"
# cask "raycast"        # Spotlight 代替
# cask "rectangle"      # ウィンドウ管理
# cask "appcleaner"     # アンインストール
# cask "the-unarchiver" # 解凍
# cask "1password"      # パスワードマネージャ

# Communication
cask "slack"
cask "zoom"
cask "discord"

# Mail
cask "thunderbird"

# Productivity
cask "todoist-app"

# =======================
# Mac App Store
# =======================
mas "Magnet", id: 441258766
mas "LINE", id: 539883307
# mas "Xcode", id: 497799835
# mas "Keynote", id: 409183694

# =======================
# VSCode Extensions
# =======================

# AI
vscode "anthropic.claude-code"
vscode "github.copilot-chat"

# Git
vscode "donjayamanne.githistory"
vscode "mhutchie.git-graph"

# Python / Jupyter
vscode "ms-python.python"
vscode "ms-python.vscode-pylance"
vscode "ms-python.debugpy"
vscode "ms-python.vscode-python-envs"
vscode "ms-toolsai.jupyter"
vscode "ms-toolsai.jupyter-renderers"

# C++
vscode "ms-vscode.cpptools"
vscode "ms-vscode.makefile-tools"

# Remote
vscode "ms-vscode-remote.remote-containers"
vscode "ms-vscode-remote.remote-ssh"
vscode "ms-vscode-remote.remote-ssh-edit"
vscode "ms-vscode.remote-explorer"

# LaTeX
vscode "james-yu.latex-workshop"

# Database
# vscode "cweijan.dbclient-jdbc"
# vscode "cweijan.vscode-postgresql-client2"

# Utility
vscode "mechatroner.rainbow-csv"
vscode "oderwat.indent-rainbow"
vscode "yzhang.markdown-all-in-one"
vscode "njzy.stats-bar"
vscode "ms-ceintl.vscode-language-pack-ja"

# =======================
# PKG / System Extensions（個別の admin 認証が必要なため最後にまとめる）
# =======================

# Microsoft（PKG インストーラーのため認証が必要）
cask "microsoft-teams"
cask "microsoft-outlook"
cask "microsoft-word"
cask "microsoft-excel"
cask "microsoft-powerpoint"

# System Extensions（システム拡張のため認証が必要）
cask "tailscale-app"
cask "displaylink"
cask "orbstack"
