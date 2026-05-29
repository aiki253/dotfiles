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

# dotfiles を展開
chezmoi init --apply git@github.com:aiki253/dotfiles.git

# ===========================
# パッケージインストール
# ===========================
case "$(uname -s)" in
  Darwin)
    brew bundle --file="$(chezmoi source-path)/Brewfile"
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
