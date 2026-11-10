#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
fixture_root="$(mktemp -d)"
trap 'rm -rf "$fixture_root"' EXIT

write_composer() {
  mkdir -p "$fixture_root/$1"
  printf '%s' "$2" >"$fixture_root/$1/composer.json"
}

write_composer platform '{"config":{"platform":{"php":"7.4"}},"require":{"php":">=7.2"}}'
write_composer require_lower_bound '{"require":{"php":">=7.2"}}'
write_composer require_caret_patch '{"require":{"php":"^8.1.2 || ^9.0"}}'
write_composer without_php '{"require":{"monolog/monolog":"^1.23"}}'
write_composer malformed '{"require":'
mkdir -p "$fixture_root/no_composer"
write_composer subdirectory_only/www '{"require":{"php":">=7.2"}}'
mkdir -p "$fixture_root/subdirectory_only/cli"
write_composer root_over_subdirectory '{"require":{"php":"^8.2"}}'
write_composer root_over_subdirectory/www '{"require":{"php":">=7.2"}}'
write_composer multiple_subdirectories/api '{"require":{"php":"^8.1"}}'
write_composer multiple_subdirectories/admin '{"require":{"php":"^7.3"}}'
write_composer multiple_subdirectories/tools '{"require":{"monolog/monolog":"^1.23"}}'

nvim --headless -u NONE "+lua \
  local specs = dofile('$repo_root/lua/plugins/php.lua') \
  local treesitter_opts = {} \
  specs[1].opts(nil, treesitter_opts) \
  assert(vim.tbl_contains(treesitter_opts.ensure_installed, 'php'), 'expected php treesitter parser') \
  local server = specs[2].opts.servers.intelephense \
  assert(server.settings.intelephense.format.enable == false, 'expected intelephense formatting disabled') \
  local function detected(case) \
    local settings = vim.deepcopy(server.settings) \
    local intelephense_settings = settings.intelephense \
    local config = { root_dir = '$fixture_root/' .. case, settings = settings } \
    server.before_init({}, config) \
    assert(config.settings == settings and config.settings.intelephense == intelephense_settings, 'expected settings mutated in place') \
    return intelephense_settings.environment.phpVersion \
  end \
  local expectations = { \
    platform = '7.4.0', \
    require_lower_bound = '7.2.0', \
    require_caret_patch = '8.1.2', \
    without_php = '7.4.0', \
    malformed = '7.4.0', \
    no_composer = '7.4.0', \
    subdirectory_only = '7.2.0', \
    root_over_subdirectory = '8.2.0', \
    multiple_subdirectories = '7.3.0', \
  } \
  for case, expected in pairs(expectations) do \
    local actual = detected(case) \
    assert(actual == expected, case .. ': expected ' .. expected .. ', got ' .. tostring(actual)) \
  end \
  print('php lsp verified: ' .. vim.tbl_count(expectations) .. ' version cases')" \
  +qa
