#!/bin/bash
set -e

echo "=== Neovim config bootstrap (macOS) ==="

brew install ripgrep fd fzf

# Node.js (vtsls, prismals 등 Mason LSP)
command -v node &>/dev/null || brew install node

# Java (kotlin_language_server)
command -v java &>/dev/null || brew install --cask temurin

# uv (pylsp를 uv run으로 실행)
command -v uv &>/dev/null || brew install uv

echo "=== Done. Open nvim — Mason will auto-install the rest ==="
