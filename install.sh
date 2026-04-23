#!/usr/bin/env bash

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
    ;;
esac

chezmoi init --apply https://github.com/aiki253/dotfiles

case "$(uname -s)" in
  Darwin)
    brew bundle --file="$(chezmoi source-path)/Brewfile"
    ;;
  Linux)
    # TODO: apt対応
    echo "Linux: パッケージインストールは手動で行ってください"
    ;;
esac
