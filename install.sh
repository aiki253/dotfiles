#!/usr/bin/env bash

# オプション解析
ROS2=false
CUDA=false
for arg in "$@"; do
  case "$arg" in
    --ros2) ROS2=true ;;
    --cuda) CUDA=true ;;
  esac
done

# ===========================
# 入力項目を事前収集（放置でも完走できるよう最初にまとめて聞く）
# ===========================

# Safari 設定の事前チェック（macOSのみ）
# - フルディスクアクセスがないと書き込みが TCC にブロックされる
# - Safari を一度も起動していないとコンテナ自体が存在しない
if [[ "$(uname -s)" == "Darwin" ]]; then
  _safari_ls=$(ls "$HOME/Library/Containers/com.apple.Safari" 2>&1)
  if echo "$_safari_ls" | grep -q "Operation not permitted"; then
    echo "======================================================"
    echo "Safari の設定を適用するため、以下を先に行ってください："
    echo ""
    echo "  システム設定 → プライバシーとセキュリティ → フルディスクアクセス"
    echo "  → Terminal をオンにする"
    echo "======================================================"
    read -rp "完了したら Enter キーを押してください: "
  elif echo "$_safari_ls" | grep -q "No such file"; then
    echo "======================================================"
    echo "Safari の設定を適用するため、以下を先に行ってください："
    echo ""
    echo "  1. システム設定 → プライバシーとセキュリティ → フルディスクアクセス"
    echo "     → Terminal をオンにする"
    echo "  2. Safari を一度起動して ⌘Q で終了する"
    echo "======================================================"
    read -rp "完了したら Enter キーを押してください: "
  fi
fi

# 既存値があれば表示して「変更しますか？」、なければそのまま入力
_ask_or_keep() {
  local label="$1" current="$2" example="$3"
  if [ -n "$current" ]; then
    echo "${label}: ${current}"
    read -rp "変更しますか？ [y/N]: " _yn
    if [[ "$_yn" =~ ^[Yy]$ ]]; then
      read -rp "${label} (例: ${example}): " _ask_result
    else
      _ask_result="$current"
    fi
  else
    read -rp "${label} (例: ${example}): " _ask_result
  fi
}

# Git name/email は git config から読む（chezmoi apply 後は必ず設定済みになる）
_ask_or_keep "Git name" "$(git config --global user.name 2>/dev/null || true)" "Taro Yamada"
GIT_NAME="$_ask_result"
_ask_or_keep "Git email" "$(git config --global user.email 2>/dev/null || true)" "taro@example.com"
GIT_EMAIL="$_ask_result"

# コンピューター名（macOSのみ）
COMPUTER_NAME=""
if [[ "$(uname -s)" == "Darwin" ]]; then
  _cur=$(scutil --get ComputerName 2>/dev/null || true)
  if [ -n "$_cur" ]; then
    echo "コンピューター名: ${_cur}"
    read -rp "変更しますか？ [y/N]: " _yn
    [[ "$_yn" =~ ^[Yy]$ ]] && \
      read -rp "コンピューター名 (例: m5-mba, 大文字/スペース非推奨): " COMPUTER_NAME
  else
    read -rp "コンピューター名を設定しますか？ [y/N]: " _yn
    [[ "$_yn" =~ ^[Yy]$ ]] && \
      read -rp "コンピューター名 (例: m5-mba, 大文字/スペース非推奨): " COMPUTER_NAME
  fi
fi

# sudo を最初に取得し、全工程が終わるまで維持する
sudo -v
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &
SUDO_KEEPALIVE_PID=$!
trap 'kill "$SUDO_KEEPALIVE_PID" 2>/dev/null || true' EXIT

# ===========================
# chezmoi のインストール
# ===========================
case "$(uname -s)" in
  Darwin)
    if ! command -v brew &>/dev/null; then
      /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
      eval "$(/opt/homebrew/bin/brew shellenv)"
    fi
    brew install chezmoi
    ;;
  Linux)
    sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "$HOME/.local/bin"
    export PATH="$HOME/.local/bin:$PATH"
    ;;
esac

# chezmoi の Git 設定を事前に書き込み（yaml との競合を避けるため yaml は削除する）
mkdir -p ~/.config/chezmoi
rm -f ~/.config/chezmoi/chezmoi.yaml
cat > ~/.config/chezmoi/chezmoi.toml << EOF
[data.git]
  name = "$GIT_NAME"
  email = "$GIT_EMAIL"
EOF

# dotfiles を展開（既にソースがあれば最新に更新してから適用）
if chezmoi source-path &>/dev/null; then
  git -C "$(chezmoi source-path)" pull --ff-only 2>/dev/null || true
fi
chezmoi init --apply https://github.com/aiki253/dotfiles.git
# init が chezmoi.yaml を再生成する場合があるため、toml との競合を解消する
rm -f ~/.config/chezmoi/chezmoi.yaml

# ===========================
# パッケージインストール
# ===========================
case "$(uname -s)" in
  Darwin)
    if [[ -n "$COMPUTER_NAME" ]]; then
      sudo scutil --set ComputerName "$COMPUTER_NAME"
      sudo scutil --set HostName "$COMPUTER_NAME"
      sudo scutil --set LocalHostName "$COMPUTER_NAME"
      sudo defaults write /Library/Preferences/SystemConfiguration/com.apple.smb.server NetBIOSName -string "$COMPUTER_NAME"
    fi

    echo "=== brew bundle 開始 ==="
    echo "※ Microsoft 系・tailscale・displaylink・orbstack は PKG/システム拡張のため最後に個別認証が求められます"
    sudo chflags nouchg /private/var/vm/sleepimage 2>/dev/null || true
    sudo -v

    # chezmoi source-path が取れない場合はデフォルトパスにフォールバック
    _brewfile="$(chezmoi source-path 2>/dev/null)/Brewfile"
    [ ! -f "$_brewfile" ] && _brewfile="$HOME/.local/share/chezmoi/Brewfile"

    _brew_bundle() {
      local log brew_status
      log=$(mktemp)
      # ✔︎（ダウンロード確認）と Fetching 一覧行を除いて進捗をリアルタイム表示
      brew bundle --file="$_brewfile" 2>&1 | \
        tee "$log" | \
        grep --line-buffered -vE "^✔︎|^Fetching:|^$"
      brew_status=${PIPESTATUS[0]}
      if [ $brew_status -ne 0 ]; then
        echo ""
        echo "--- 失敗したパッケージ ---"
        grep -iE "✘|Error:|failed" "$log" || tail -20 "$log"
      fi
      rm -f "$log"
      return $brew_status
    }

    if ! _brew_bundle; then
      echo "--- 再試行 ---"
      if ! _brew_bundle; then
        echo "上記のパッケージは手動でインストールしてください: brew install --cask <name>"
      fi
    fi
    echo "=== brew bundle 完了 ==="
    ;;

  Linux)
    # --- 基本パッケージ ---
    sudo apt update && sudo apt upgrade -y
    sudo apt install -y curl wget git tar vim build-essential \
      apt-transport-https gnupg htop fzf snapd

    # --- Google Chrome ---
    wget -qP /tmp https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
    sudo apt install -y /tmp/google-chrome-stable_current_amd64.deb
    rm /tmp/google-chrome-stable_current_amd64.deb

    # --- Slack ---
    sudo snap install slack --classic

    # --- VS Code ---
    wget -qO /tmp/code.deb "https://code.visualstudio.com/sha/download?build=stable&os=linux-deb-x64"
    sudo dpkg -i /tmp/code.deb
    rm /tmp/code.deb

    # --- Docker ---
    curl -fsSL https://get.docker.com -o /tmp/get-docker.sh
    sudo sh /tmp/get-docker.sh
    sudo usermod -aG docker "$USER"
    rm /tmp/get-docker.sh
    echo "注意: Docker グループへの追加は再ログイン後に有効になります"

    # --- GitHub CLI ---
    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
      | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
    sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
      | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
    sudo apt update && sudo apt install -y gh

    # --- Node.js (LTS 20) + Claude Code ---
    curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
    sudo apt install -y nodejs
    sudo npm install -g @anthropic-ai/claude-code

    # --- pixi ---
    curl -fsSL https://pixi.sh/install.sh | sh

    # --- uv ---
    curl -LsSf https://astral.sh/uv/install.sh | sh

    # --- pueue (バイナリリリース) ---
    PUEUE_VER=$(curl -s https://api.github.com/repos/Nukesor/pueue/releases/latest \
      | grep '"tag_name"' | cut -d'"' -f4)
    curl -LO "https://github.com/Nukesor/pueue/releases/download/${PUEUE_VER}/pueue-linux-x86_64"
    curl -LO "https://github.com/Nukesor/pueue/releases/download/${PUEUE_VER}/pueued-linux-x86_64"
    chmod +x pueue-linux-x86_64 pueued-linux-x86_64
    sudo mv pueue-linux-x86_64 /usr/local/bin/pueue
    sudo mv pueued-linux-x86_64 /usr/local/bin/pueued

    # pueue systemd サービス
    mkdir -p ~/.config/systemd/user
    cat > ~/.config/systemd/user/pueued.service << 'EOF'
[Unit]
Description=Pueue Daemon
[Service]
ExecStart=/usr/local/bin/pueued -v
[Install]
WantedBy=default.target
EOF
    systemctl --user daemon-reload
    systemctl --user enable --now pueued

    # --- VS Code 拡張機能 ---
    code --install-extension ms-ceintl.vscode-language-pack-ja
    code --install-extension anthropic.claude-code
    code --install-extension github.copilot
    code --install-extension eamodio.gitlens
    code --install-extension ms-python.python
    code --install-extension ms-python.vscode-pylance
    code --install-extension ms-toolsai.jupyter
    code --install-extension ms-vscode-remote.remote-ssh
    code --install-extension ms-vscode-remote.remote-containers
    code --install-extension james-yu.latex-workshop
    code --install-extension mechatroner.rainbow-csv

    # --- ROS2 humble (--ros2 オプション、Ubuntu 22.04 のみ) ---
    if $ROS2; then
      if [[ "$(lsb_release -rs)" == "22.04" ]]; then
        sudo apt install -y curl gnupg2 lsb-release
        sudo curl -sSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.key \
          -o /usr/share/keyrings/ros-archive-keyring.gpg
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/ros-archive-keyring.gpg] http://packages.ros.org/ros2/ubuntu $(source /etc/os-release && echo $UBUNTU_CODENAME) main" \
          | sudo tee /etc/apt/sources.list.d/ros2.list > /dev/null
        sudo apt update
        sudo apt install -y ros-humble-desktop \
          python3-colcon-common-extensions python3-rosdep
        sudo rosdep init
        rosdep update
        echo "source /opt/ros/humble/setup.bash" >> ~/.bashrc
      else
        echo "ROS2 humble は Ubuntu 22.04 のみ対応しています（現在: $(lsb_release -rs)）"
      fi
    fi

    # --- CUDA (--cuda オプション) ---
    if $CUDA; then
      echo ""
      echo "=== CUDA セットアップ (手動手順) ==="
      echo "1. 推奨ドライバを確認: ubuntu-drivers devices"
      echo "2. ドライバをインストール: sudo apt install nvidia-driver-<version>"
      echo "3. 再起動後、nvidia-smi で確認"
      echo "4. CUDA toolkit を手動インストール:"
      echo "   https://developer.nvidia.com/cuda-downloads"
      echo "5. ~/.bashrc に以下を追記:"
      echo "   export PATH=/usr/local/cuda/bin:\$PATH"
      echo "   export LD_LIBRARY_PATH=/usr/local/cuda/lib64:\$LD_LIBRARY_PATH"
    fi
    ;;
esac
