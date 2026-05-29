# dotfiles

## macOS

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/aiki253/dotfiles/main/install.sh)
```

以下が自動で行われます:
- chezmoi のインストールと dotfiles の展開 (`.zshenv`, `.zshrc`)
- Brewfile によるツール・アプリの一括インストール
- macOS 設定スクリプト (`.macos`) の適用

実行後に再起動してください。

---

## Ubuntu

**install.sh を実行**
```bash
bash <(curl -fsSL https://raw.githubusercontent.com/aiki253/dotfiles/main/install.sh)
```

オプション:
```bash
# ROS2 humble を追加インストール (Ubuntu 22.04 のみ)
bash <(curl -fsSL https://raw.githubusercontent.com/aiki253/dotfiles/main/install.sh) --ros2

# CUDA セットアップ手順を表示
bash <(curl -fsSL https://raw.githubusercontent.com/aiki253/dotfiles/main/install.sh) --cuda

# 両方
bash <(curl -fsSL https://raw.githubusercontent.com/aiki253/dotfiles/main/install.sh) --ros2 --cuda
```

---

## 日常的な使い方

| やること | コマンド |
|---|---|
| dotfiles の更新を取り込む | `chezmoi update` |
| 設定ファイルを編集して反映 | `chezmoi edit ~/.zshrc && chezmoi apply` |
| 差分確認 | `chezmoi diff` |

### Brewfile の管理

| やること | コマンド |
|---|---|
| アプリを追加・削除後に反映 | `brew bundle install --file=~/Brewfile` |
| 現在の環境から Brewfile を更新 | `brew bundle dump --force --file=~/dotfiles/Brewfile` |
| インストール済みか確認 | `brew bundle check --file=~/Brewfile` |
