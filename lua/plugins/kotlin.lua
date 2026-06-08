return {
  -- fwcd/kotlin-language-server 비활성화 (JetBrains kotlin-lsp로 교체)
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        kotlin_language_server = { enabled = false },
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
