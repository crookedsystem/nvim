#!/bin/bash
set -e

echo "=== Neovim config bootstrap (macOS) ==="

brew install ripgrep fd fzf

# Python (Mason의 basedpyright 설치용 가상환경 생성)
command -v python3 &>/dev/null || brew install python

# Node.js (vtsls, prismals 등 Mason LSP)
command -v node &>/dev/null || brew install node

# Java 21+ (jdtls는 21 미만에서 기동 실패, kotlin_lsp도 21에서 동작)
/usr/libexec/java_home -v 21+ &>/dev/null || brew install --cask temurin@21

# uv (Python 디버깅의 dap-python에서 사용)
command -v uv &>/dev/null || brew install uv

echo "=== Deps installed ==="
