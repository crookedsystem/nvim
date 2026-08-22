#!/bin/bash
set -e

echo "=== Neovim config bootstrap (macOS) ==="

brew install ripgrep fd fzf

# Node.js (vtsls, prismals 등 Mason LSP)
command -v node &>/dev/null || brew install node

# Java 21+ (jdtls는 21 미만에서 기동 실패, kotlin_lsp도 21에서 동작)
/usr/libexec/java_home -v 21+ &>/dev/null || brew install --cask temurin@21

# uv (pylsp를 uv run으로 실행)
command -v uv &>/dev/null || brew install uv

echo "=== Done. Open nvim — Mason will auto-install the rest ==="
