-- bootstrap lazy.nvim, LazyVim and your plugins
require("config.lazy")

-- SSH 세션에서는 로컬 클립보드 도구(pbcopy/xclip)에 접근할 수 없으므로
-- OSC 52 escape sequence로 터미널을 통해 로컬 클립보드에 yank 내용을 전달한다.
if vim.env.SSH_TTY or vim.env.SSH_CONNECTION then
  local osc52 = require("vim.ui.clipboard.osc52")
  vim.g.clipboard = {
    name = "OSC 52",
    copy = {
      ["+"] = osc52.copy("+"),
      ["*"] = osc52.copy("*"),
    },
    paste = {
      ["+"] = osc52.paste("+"),
      ["*"] = osc52.paste("*"),
    },
  }
end
