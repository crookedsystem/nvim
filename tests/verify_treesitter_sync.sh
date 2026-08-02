#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"

nvim --headless -u NONE "+lua \
  local spec = dofile('$repo_root/lua/plugins/treesitter.lua')[1] \
  assert(spec.commit == '7caec274fd19c12b55902a5b795100d21531391f', 'expected Neovim 0.11 compatibility pin') \
  local update_called = false \
  local wait_called = false \
  package.preload['nvim-treesitter'] = function() \
    return { \
      update = function(languages, opts) \
        assert(languages == nil, 'expected all installed parsers to be checked') \
        assert(opts.summary == true, 'expected update summary') \
        update_called = true \
        return { \
          wait = function() \
            wait_called = true \
          end, \
        } \
      end, \
    } \
  end \
  spec.build() \
  assert(update_called, 'expected parser update during plugin build') \
  assert(wait_called, 'expected plugin build to wait for parser synchronization') \
  print('treesitter sync verified')" \
  +qa
