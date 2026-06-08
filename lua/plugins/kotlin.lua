return {
  -- mason-lspconfig 자동 활성화 차단 (kotlin.nvim이 직접 관리)
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        kotlin_lsp = { enabled = false },
      },
    },
  },
  -- JetBrains kotlin-lsp 자동 설치
  {
    "mason-org/mason.nvim",
    opts = {
      ensure_installed = { "kotlin-lsp" },
    },
  },
  -- JetBrains kotlin-lsp
  {
    "AlexandrosAlexiou/kotlin.nvim",
    ft = { "kotlin" },
    dependencies = {
      "mason-org/mason.nvim",
      "mason-org/mason-lspconfig.nvim",
    },
    config = function()
      require("kotlin").setup({})
    end,
  },
}
