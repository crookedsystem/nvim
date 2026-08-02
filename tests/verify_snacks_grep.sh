#!/usr/bin/env bash
set -euo pipefail

repo="$(mktemp -d)"
trap 'rm -rf "$repo"' EXIT

printf 'local value = call({ key = "value" })\n' > "$repo/literal.lua"

set +e
output="$(
  nvim --headless "+lua \
    require('lazy').load({ plugins = { 'snacks.nvim' } }) \
    local picker = Snacks.picker.grep({ cwd = '$repo', search = '(' }) \
    local started_at = vim.uv.now() \
    local function check() \
      if picker:count() > 0 then \
        assert(picker.opts.regex == false, 'expected literal grep to disable regex') \
        local toggle = picker.opts.actions and picker.opts.actions.toggle_regex \
        assert(type(toggle) == 'function', 'expected toggle_regex action') \
        toggle(picker) \
        assert(picker.opts.regex == true, 'expected toggle_regex to enable regex') \
        print('RESULT:snacks-literal-grep-and-regex-toggle') \
        picker:close() \
        vim.cmd('qa!') \
        return \
      end \
      if vim.uv.now() - started_at > 5000 then \
        print('RESULT:literal-grep-returned-no-matches') \
        picker:close() \
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

grep -q "RESULT:snacks-literal-grep-and-regex-toggle" <<<"$output"
printf 'snacks grep verified\n'
