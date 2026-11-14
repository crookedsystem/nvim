-- 접속한 컴퓨터의 클립보드로 복사하고, Herdr의 읽기 응답 없이 붙여넣는다.
local copied = { {}, "v" }
local osc52_copy = require("vim.ui.clipboard.osc52").copy("+")

local function copy(lines, regtype)
  copied = { lines, regtype }
  osc52_copy(lines)
end

local function paste()
  return copied
end

vim.g.clipboard = {
  name = "OSC 52 (copy only)",
  copy = {
    ["+"] = copy,
    ["*"] = copy,
  },
  paste = {
    ["+"] = paste,
    ["*"] = paste,
  },
}

-- bootstrap lazy.nvim, LazyVim and your plugins
require("config.lazy")
