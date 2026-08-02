#!/usr/bin/env bash
set -euo pipefail

if ! rg -q 'sindrets/diffview.nvim' lua/plugins; then
  printf 'expected diffview.nvim plugin spec\n' >&2
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
    assert(plugins['diffview.nvim'], 'expected diffview.nvim plugin spec') \
    assert(not plugins['codediff.nvim'], 'codediff.nvim plugin spec must be removed') \
    require('lazy').load({ plugins = { 'diffview.nvim' } }) \
    assert(vim.fn.exists(':DiffviewOpen') == 2, 'expected :DiffviewOpen command') \
    local config = require('diffview.config').get_config() \
    assert(config.view.default.layout == 'diff2_horizontal', 'expected horizontal review layout') \
    assert(config.view.merge_tool.layout == 'diff3_mixed', 'expected mixed 3-way merge layout') \
    local expected_maps = { \
      ['<leader>gd'] = 'Diffview (current file)', \
      ['<leader>gD'] = 'Diffview (repo)', \
      ['<leader>gH'] = 'File History (current file)', \
    } \
    for lhs, desc in pairs(expected_maps) do \
      local mapping = vim.fn.maparg(lhs, 'n', false, true) \
      assert(mapping.desc == desc, ('unexpected mapping for %s: %s'):format(lhs, vim.inspect(mapping))) \
    end \
    assert(vim.fn.maparg('<leader>gi', 'n') == '', 'obsolete inline diff mapping must be removed') \
    vim.cmd('DiffviewOpen') \
    local started_at = vim.uv.now() \
    local function check() \
      local has_conflict_mapping = false \
      for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do \
        vim.api.nvim_win_call(win, function() \
          has_conflict_mapping = has_conflict_mapping or vim.fn.maparg('<leader>co', 'n') ~= '' \
        end) \
      end \
      local windows = #vim.api.nvim_tabpage_list_wins(0) \
      if windows >= 3 and has_conflict_mapping then \
        print(('RESULT:diffview-conflict-windows=%d,ours-mapping=true'):format(windows)) \
        vim.cmd('qa!') \
        return \
      end \
      if vim.uv.now() - started_at > 5000 then \
        print(('RESULT:diffview-conflict-timeout-windows=%d'):format(windows)) \
        vim.cmd('cquit 1') \
        return \
      end \
      vim.defer_fn(check, 50) \
    end \
    check()" 2>&1
)"
nvim_status=$?
set -e

if [[ "$nvim_status" -ne 0 ]]; then
  printf '%s\n' "$output" >&2
  exit "$nvim_status"
fi

grep -q "RESULT:diffview-conflict-windows=.*ours-mapping=true" <<<"$output"
printf 'diffview keymaps verified\n'
