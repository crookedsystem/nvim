#!/bin/bash
set -e

echo "=== Neovim config bootstrap (Ubuntu/Debian) ==="

sudo apt-get update -qq
sudo apt-get install -y ripgrep fd-find fzf curl unzip

# Node.js (vtsls, prismals 등 Mason LSP)
if ! command -v node &>/dev/null; then
  curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
  sudo apt-get install -y nodejs
fi

# Java (kotlin_language_server)
if ! command -v java &>/dev/null; then
  sudo apt-get install -y default-jdk
fi

# uv (pylsp를 uv run으로 실행)
if ! command -v uv &>/dev/null; then
  curl -LsSf https://astral.sh/uv/install.sh | sh
  source "$HOME/.local/bin/env" 2>/dev/null || true
fi

echo "=== Done. Open nvim — Mason will auto-install the rest ==="
