#!/usr/bin/env bash
set -euo pipefail

repo="$(mktemp -d)"
trap 'rm -rf "$repo"' EXIT
cd "$repo"
git init -q
git config user.email test@example.com
git config user.name test
printf 'one\ntwo\nthree\nfour\n' > sample.txt
git add sample.txt
git commit -qm base

cat > verify.lua <<'LUA'
local function git(args)
  local output = vim.fn.system(vim.list_extend({ "git" }, args))
  assert(vim.v.shell_error == 0, output)
  return output
end

local ok, err = pcall(function()
  local request = vim.lsp.buf_request
  vim.lsp.buf_request = function(bufnr, method, ...)
    assert(method ~= "textDocument/hover", "stage unexpectedly requested hover: " .. debug.traceback())
    return request(bufnr, method, ...)
  end
  local cases = {
    { name = "one adjacent change", working = { "one", "TWO", "THREE", "four" },
      side = "b", line = 2, keys = "Vs", expected = "one\nTWO\nthree\nfour\n" },
    { name = "reverse selection", working = { "one", "TWO", "THREE", "four" },
      side = "b", line = 3, keys = "Vks", expected = "one\nTWO\nTHREE\nfour\n" },
    { name = "one added line", working = { "one", "two", "added-a", "added-b", "three", "four" },
      side = "b", line = 3, keys = "Vs", expected = "one\ntwo\nadded-a\nthree\nfour\n" },
    { name = "one deleted line from INDEX", working = { "one", "four" },
      side = "a", line = 2, keys = "Vs", expected = "one\nthree\nfour\n" },
    { name = "selected change from INDEX", working = { "one", "TWO", "THREE", "four" },
      side = "a", line = 2, keys = "Vs", expected = "one\nTWO\nthree\nfour\n" },
  }
  for _, case in ipairs(cases) do
    git({ "read-tree", "HEAD" })
    vim.fn.writefile(case.working, "sample.txt")
    vim.cmd("checktime")
    vim.cmd("DiffviewOpen -- sample.txt")
    local view = require("diffview.lib").get_current_view()
    assert(vim.wait(5000, function()
      return view.cur_layout and view.cur_layout:is_valid()
        and view.cur_layout:is_files_loaded() and view.cur_layout.b.file.path == "sample.txt"
    end, 20), "diff load timeout")
    vim.api.nvim_set_current_win(view.cur_layout[case.side].id)
    assert(vim.fn.maparg("s", "x", false, true).desc == "Stage selected lines")
    vim.api.nvim_win_set_cursor(0, { case.line, 0 })
    vim.api.nvim_feedkeys(case.keys, "xt", false)
    assert(vim.wait(5000, function()
      return git({ "show", ":sample.txt" }) == case.expected
    end, 20), case.name .. ": wrong index: " .. git({ "show", ":sample.txt" }))
    assert(vim.deep_equal(vim.fn.readfile("sample.txt"), case.working), "working file changed")
    vim.api.nvim_feedkeys("gF", "xt", false)
    assert(require("diffview.lib").get_current_view() == nil, "gF did not leave Diffview")
    assert(vim.api.nvim_buf_get_name(0) == vim.fn.getcwd() .. "/sample.txt", "gF opened wrong file")
    assert(not vim.wo.diff, "gF left diff mode enabled")
    print("PASS: " .. case.name)
  end
  -- Diffview를 닫으면 일반 창의 s 매핑으로 돌아온다.
  assert(vim.fn.maparg("s", "x", false, true).desc ~= "Stage selected lines")
end)
if not ok then
  print(err)
  vim.cmd("cquit 1")
else
  vim.cmd("qa!")
end
LUA

nvim --headless -c 'luafile verify.lua'
