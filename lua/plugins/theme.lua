return {
  -- add onenord
  {
    "Mofiqul/vscode.nvim",
    opts = {
      -- DiffChange/DiffText 기본값이 DiffDelete와 같은 빨간 계열이라 diff에서
      -- 변경/삭제가 구분 안 됨 (upstream https://github.com/Mofiqul/vscode.nvim/issues/247)
      group_overrides = {
        DiffAdd = { bg = "#34402a", fg = "NONE", bold = false },
        DiffChange = { bg = "#34402a", fg = "NONE", bold = false },
        DiffDelete = { bg = "#4A2323", fg = "NONE", bold = false },
        DiffText = { bg = "#44658A", fg = "NONE", bold = false },
      },
    },
  },
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "vscode",
    },
  },
}

