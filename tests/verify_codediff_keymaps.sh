#!/usr/bin/env bash
set -euo pipefail

make_repo() {
  local repo
  repo="$(mktemp -d)"
  (
    cd "$repo"
    git init -q
    git config user.email test@example.com
    git config user.name test
    printf 'a\nb\n' > file.txt
    git add file.txt
    git commit -qm init
    printf 'a\nb changed\n' > file.txt
  )
  printf '%s\n' "$repo"
}

make_multi_hunk_repo() {
  local repo
  repo="$(mktemp -d)"
  (
    cd "$repo"
    git init -q
    git config user.email test@example.com
    git config user.name test
    for line in $(seq 1 20); do
      printf 'line %s\n' "$line"
    done > file.txt
    git add file.txt
    git commit -qm init
    perl -0pi -e 's/line 2/line 2 changed/; s/line 18/line 18 changed/' file.txt
  )
  printf '%s\n' "$repo"
}

run_keymap_case() {
  local key_input="$1"
  local expected_mode="$2"
  local expected_wins="${3:-}"
  local repo
  local output

  repo="$(make_repo)"
  trap 'rm -rf "$repo"' RETURN

  output="$(
    cd "$repo"
    nvim --headless "$repo/file.txt" +"lua \
      local key = [[$key_input]] \
      local done = false \
      vim.api.nvim_create_autocmd('User', { \
        pattern = 'CodeDiffOpen', \
        callback = function(args) \
          done = true \
          print(('RESULT:mode=%s,wins=%d'):format(args.data.mode, vim.fn.winnr('$'))) \
          vim.cmd('qa!') \
        end, \
      }) \
      vim.defer_fn(function() \
        vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(key, true, false, true), 'm', false) \
      end, 200) \
      vim.defer_fn(function() \
        if not done then \
          print('RESULT:timeout') \
          vim.cmd('qa!') \
        end \
      end, 5000)" 2>&1
  )"

  if [[ -n "$expected_wins" ]]; then
    grep -q "RESULT:mode=${expected_mode},wins=${expected_wins}" <<<"$output"
  else
    grep -q "RESULT:mode=${expected_mode}," <<<"$output"
  fi
}

run_fold_case() {
  local repo
  local output

  repo="$(make_multi_hunk_repo)"
  trap 'rm -rf "$repo"' RETURN

  output="$(
    cd "$repo"
    nvim --headless "$repo/file.txt" +"lua \
      local done = false \
      local function check() \
        local lifecycle = require('codediff.ui.lifecycle') \
        local session = lifecycle.get_session(vim.api.nvim_get_current_tabpage()) \
        if session and session.modified_win and vim.api.nvim_win_is_valid(session.modified_win) then \
          vim.api.nvim_set_current_win(session.modified_win) \
          local before_first = vim.fn.foldclosed(1) \
          local first_change = vim.fn.foldclosed(2) \
          local after_first = vim.fn.foldclosed(3) \
          local second_change = vim.fn.foldclosed(18) \
          if before_first ~= -1 and first_change == -1 and after_first ~= -1 and second_change == -1 then \
            done = true \
            print(('RESULT:folds=%d,%d'):format(before_first, after_first)) \
            vim.cmd('qa!') \
            return \
          end \
        end \
        vim.defer_fn(check, 100) \
      end \
      vim.defer_fn(function() \
        vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(' gd', true, false, true), 'm', false) \
      end, 200) \
      vim.defer_fn(check, 500) \
      vim.defer_fn(function() \
        if not done then \
          print('RESULT:timeout') \
          vim.cmd('qa!') \
        end \
      end, 5000)" 2>&1
  )"

  grep -q "RESULT:folds=1,3" <<<"$output"
}

run_single_line_gap_fold_case() {
  local repo
  local output

  repo="$(mktemp -d)"
  trap 'rm -rf "$repo"' RETURN
  (
    cd "$repo"
    git init -q
    git config user.email test@example.com
    git config user.name test
    printf 'line 1\nline 2\nline 3\nline 4\nline 5\n' > file.txt
    git add file.txt
    git commit -qm init
    perl -0pi -e 's/line 2/line 2 changed/; s/line 4/line 4 changed/' file.txt
  )

  output="$(
    cd "$repo"
    nvim --headless "$repo/file.txt" +"lua \
      local done = false \
      local function check() \
        local lifecycle = require('codediff.ui.lifecycle') \
        local session = lifecycle.get_session(vim.api.nvim_get_current_tabpage()) \
        if session and session.modified_win and vim.api.nvim_win_is_valid(session.modified_win) then \
          vim.api.nvim_set_current_win(session.modified_win) \
          local middle_gap = vim.fn.foldclosed(3) \
          local first_change = vim.fn.foldclosed(2) \
          local second_change = vim.fn.foldclosed(4) \
          if middle_gap == 3 and first_change == -1 and second_change == -1 then \
            done = true \
            print('RESULT:single-line-gap-folded') \
            vim.cmd('qa!') \
            return \
          end \
        end \
        vim.defer_fn(check, 100) \
      end \
      vim.defer_fn(function() \
        vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(' gd', true, false, true), 'm', false) \
      end, 200) \
      vim.defer_fn(check, 500) \
      vim.defer_fn(function() \
        if not done then \
          print('RESULT:timeout') \
          vim.cmd('qa!') \
        end \
      end, 5000)" 2>&1
  )"

  grep -q "RESULT:single-line-gap-folded" <<<"$output"
}

run_repo_fold_case() {
  local repo
  local output

  repo="$(make_multi_hunk_repo)"
  trap 'rm -rf "$repo"' RETURN

  output="$(
    cd "$repo"
    nvim --headless "$repo/file.txt" +"lua \
      local done = false \
      local function check() \
        local lifecycle = require('codediff.ui.lifecycle') \
        local session = lifecycle.get_session(vim.api.nvim_get_current_tabpage()) \
        if session and session.modified_win and vim.api.nvim_win_is_valid(session.modified_win) and session.stored_diff_result and #session.stored_diff_result.changes > 0 then \
          vim.api.nvim_set_current_win(session.modified_win) \
          if vim.fn.foldclosed(1) ~= -1 and vim.fn.foldclosed(2) == -1 and vim.fn.foldclosed(3) ~= -1 then \
            done = true \
            print('RESULT:repo-folded') \
            vim.cmd('qa!') \
            return \
          end \
        end \
        vim.defer_fn(check, 100) \
      end \
      vim.api.nvim_create_autocmd('User', { \
        pattern = 'CodeDiffOpen', \
        callback = function() \
          vim.defer_fn(function() \
            vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('j<CR>', true, false, true), 'm', false) \
          end, 500) \
          vim.defer_fn(check, 1000) \
        end, \
      }) \
      vim.defer_fn(function() \
        vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(' gD', true, false, true), 'm', false) \
      end, 200) \
      vim.defer_fn(function() \
        if not done then \
          print('RESULT:timeout') \
          vim.cmd('qa!') \
        end \
      end, 7000)" 2>&1
  )"

  grep -q "RESULT:repo-folded" <<<"$output"
}

run_keymap_case ' gd' standalone 2
run_keymap_case ' gi' standalone 1
run_keymap_case ' gD' explorer
run_fold_case
run_single_line_gap_fold_case
run_repo_fold_case

echo "codediff keymaps verified"
