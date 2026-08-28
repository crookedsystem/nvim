#!/usr/bin/env bash
set -euo pipefail

set +e
output="$(
  nvim --headless "+lua \
    local should_open = require('config.oil_startup').should_open \
    local function check(desc, expected, argc, bufname, uis, line_count, first_line) \
      local actual = should_open(argc, bufname, uis, line_count, first_line) \
      assert(actual == expected, ('%s: expected %s, got %s'):format(desc, tostring(expected), tostring(actual))) \
    end \
    local tty_ui = { { stdout_tty = true, stdin_tty = true } } \
    local piped_ui = { { stdout_tty = true, stdin_tty = false } } \
    check('no args, empty buf, interactive tty', true, 0, '', tty_ui, 1, '') \
    check('file args present', false, 1, '', tty_ui, 1, '') \
    check('buffer already named', false, 0, '/tmp/foo.txt', tty_ui, 1, '') \
    check('no ui attached', false, 0, '', {}, 1, '') \
    check('piped stdin with content', false, 0, '', piped_ui, 2, 'hello') \
    check('piped stdin, single non-empty line', false, 0, '', piped_ui, 1, 'hello') \
    print('RESULT:oil-startup-predicate-verified') \
    vim.cmd('qa!')" 2>&1
)"
nvim_status=$?
set -e

if [[ "$nvim_status" -ne 0 ]]; then
  printf '%s\n' "$output" >&2
  exit "$nvim_status"
fi

grep -q "RESULT:oil-startup-predicate-verified" <<<"$output"
printf 'oil startup predicate verified\n'
