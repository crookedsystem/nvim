-- ref : https://github.com/MariaSolOs/dotfiles/blob/022de739ecbf4c6c20aadf1d1be143f1f3a65967/.config/nvim/lua/plugins/copilot.lua#L4
-- Copilot completion.

-- NVM에 설치된 Node v22 계열 중 가장 최신 버전 경로를 반환.
-- system Node 버전을 v22+로 끌어올리지 않고 Copilot 전용으로 v22를 쓰기 위해 사용한다.
-- 경로 문자열 정렬은 v22.9.0 > v22.10.0처럼 잘못된 결과를 내므로 semver 숫자 비교를 한다.
local function find_copilot_node()
  local nvm_dir = vim.fn.expand("$HOME") .. "/.nvm/versions/node"
  local candidates = vim.fn.glob(nvm_dir .. "/v22.*/bin/node", false, true)
  if #candidates == 0 then
    return nil
  end
  local function semver(path)
    local major, minor, patch = path:match("/v(%d+)%.(%d+)%.(%d+)/bin/node$")
    return tonumber(major) or 0, tonumber(minor) or 0, tonumber(patch) or 0
  end
  table.sort(candidates, function(a, b)
    local a_major, a_minor, a_patch = semver(a)
    local b_major, b_minor, b_patch = semver(b)
    if a_major ~= b_major then
      return a_major < b_major
    end
    if a_minor ~= b_minor then
      return a_minor < b_minor
    end
    return a_patch < b_patch
  end)
  return candidates[#candidates]
end

return {
  {
    "zbirenbaum/copilot.lua",
    cmd = "Copilot",
    event = "InsertEnter",
    opts = {
      copilot_node_command = find_copilot_node() or "node",
      -- ghost text(인라인 자동완성) 활성화. Tab으로 accept.
      suggestion = {
        enabled = true,
        auto_trigger = true,
        hide_during_completion = false,
        debounce = 75,
        keymap = {
          accept = "<Tab>",
          accept_word = false,
          accept_line = false,
          next = "<M-]>",
          prev = "<M-[>",
          dismiss = "<C-]>",
        },
      },
      panel = { enabled = false },
      filetypes = {
        markdown = true,
        yaml = true,
      },
    },
  },
  -- blink.cmp 메뉴는 Arrow + Enter로 적용. Copilot은 ghost text로 분리되어
  -- source/dependency를 제거한다(중복 제안 방지).
  {
    "saghen/blink.cmp",
    optional = true,
    opts = {
      sources = {
        default = { "lsp", "path", "snippets", "buffer" },
      },
      keymap = {
        preset = "enter",
        -- 메뉴 항목은 화살표로만 선택, Enter로 accept(preset = "enter"가 처리).
        ["<Up>"] = { "select_prev", "fallback" },
        ["<Down>"] = { "select_next", "fallback" },
        -- Tab은 Copilot ghost text 전용. blink.cmp가 Tab을 가로채지 않도록 비운다.
        ["<Tab>"] = {},
        ["<S-Tab>"] = {},
      },
    },
  },
}
