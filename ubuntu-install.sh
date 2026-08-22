#!/bin/bash
set -e

echo "=== Neovim config bootstrap (Ubuntu/Debian) ==="

sudo apt-get update -qq
sudo apt-get install -y ripgrep fd-find fzf curl unzip

# fd-find installs as fdfind on Ubuntu; symlink to fd for LazyVim compatibility
if command -v fdfind &>/dev/null && ! command -v fd &>/dev/null; then
  sudo ln -sf "$(which fdfind)" /usr/local/bin/fd
fi

# Node.js (vtsls, prismals 등 Mason LSP)
if ! command -v node &>/dev/null; then
  curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
  sudo apt-get install -y nodejs
fi

# Java 21+ (jdtls는 21 미만에서 기동 실패, kotlin_lsp도 21에서 동작)
java_major="$(java -version 2>&1 | sed -n 's/.*version "\([0-9]\{1,\}\).*/\1/p' | head -1)"
if [ -z "$java_major" ] || [ "$java_major" -lt 21 ]; then
  sudo apt-get install -y openjdk-21-jdk
fi

# uv (pylsp를 uv run으로 실행)
if ! command -v uv &>/dev/null; then
  curl -LsSf https://astral.sh/uv/install.sh | sh
  # 현재 셸 세션에 PATH 즉시 반영
  export PATH="$HOME/.local/bin:$PATH"
  # 미래 셸 세션을 위해 shell profile에도 추가
  for rc in "$HOME/.bashrc" "$HOME/.zshrc" "$HOME/.profile"; do
    if [ -f "$rc" ] && ! grep -q '\.local/bin' "$rc"; then
      echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$rc"
    fi
  done
fi

echo "=== Deps installed ==="
