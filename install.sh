#!/usr/bin/env bash

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

for src in "$DOTFILES_DIR"/.*; do
  name="$(basename "$src")"

  # スキップ対象
  [[ "$name" == "." || "$name" == ".." || "$name" == ".git" ]] && continue

  # .macos は実行スクリプトなのでシンボリックリンク対象外
  [[ "$name" == ".macos" || "$name" == ".macos_backup" ]] && continue

  dst="$HOME/$name"
  ln -sf "$src" "$dst"
  echo "Linked: $dst -> $src"
done

echo "Done."
