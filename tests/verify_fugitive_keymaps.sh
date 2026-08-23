#!/usr/bin/env bash
set -euo pipefail

if ! rg -q 'tpope/vim-fugitive' lua/plugins; then
  printf 'expected vim-fugitive plugin spec\n' >&2
  exit 1
fi

if rg -q 'sindrets/diffview.nvim' lua/plugins; then
  printf 'diffview.nvim plugin spec must be removed\n' >&2
  exit 1
fi

repo="$(mktemp -d)"
trap 'rm -rf "$repo"' EXIT

(
  cd "$repo"
  git init -q -b main
  git config user.email test@example.com
  git config user.name test
  printf 'base\n' > conflict.txt
  git add conflict.txt
  git commit -qm base
  git checkout -qb incoming
  printf 'incoming\n' > conflict.txt
  git commit -qam incoming
  git checkout -q main
  printf 'current\n' > conflict.txt
  git commit -qam current
  git merge incoming >/dev/null 2>&1 || true
)

set +e
output="$(
  cd "$repo"
  nvim --headless conflict.txt "+lua \
    local plugins = require('lazy.core.config').plugins \
    assert(plugins['vim-fugitive'], 'expected vim-fugitive plugin spec') \
    assert(not plugins['diffview.nvim'], 'diffview.nvim plugin spec must be removed') \
    require('lazy').load({ plugins = { 'vim-fugitive' } }) \
    assert(vim.fn.exists(':Git') == 2, 'expected :Git command') \
    assert(vim.fn.exists(':Gvdiffsplit') == 2, 'expected :Gvdiffsplit command') \
    assert(vim.fn.exists(':Gclog') == 2, 'expected :Gclog command') \
    local expected_maps = { \
      ['<leader>gd'] = 'Git Diff (current file)', \
      ['<leader>gD'] = 'Git Status (repo)', \
      ['<leader>gH'] = 'File History (current file)', \
    } \
    for lhs, desc in pairs(expected_maps) do \
      local mapping = vim.fn.maparg(lhs, 'n', false, true) \
      assert(mapping.desc == desc, ('unexpected mapping for %s: %s'):format(lhs, vim.inspect(mapping))) \
    end \
    assert(vim.fn.maparg('<leader>gi', 'n') == '', 'obsolete inline diff mapping must be removed') \
    vim.cmd('Gdiffsplit!') \
    local windows = #vim.api.nvim_tabpage_list_wins(0) \
    local has_ours_mapping = false \
    for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do \
      vim.api.nvim_win_call(win, function() \
        has_ours_mapping = has_ours_mapping or vim.fn.maparg('d2o', 'n') ~= '' \
      end) \
    end \
    assert(windows >= 3, ('expected 3-way merge windows, got %d'):format(windows)) \
    assert(has_ours_mapping, 'expected d2o ours-hunk mapping in conflict diff') \
    print(('RESULT:fugitive-conflict-windows=%d,ours-mapping=true'):format(windows)) \
    vim.cmd('qa!')" 2>&1
)"
nvim_status=$?
set -e

if [[ "$nvim_status" -ne 0 ]]; then
  printf '%s\n' "$output" >&2
  exit "$nvim_status"
fi

grep -q "RESULT:fugitive-conflict-windows=.*ours-mapping=true" <<<"$output"
printf 'fugitive keymaps verified\n'
