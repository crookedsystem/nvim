return {
  -- mason-lspconfig 자동 활성화 차단 (kotlin.nvim이 직접 관리)
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        kotlin_language_server = { enabled = false },
        kotlin_lsp = { enabled = false },
      },
    },
  },
  -- JetBrains kotlin-lsp
  {
    "AlexandrosAlexiou/kotlin.nvim",
    enabled = false, -- Mason 최신 kotlin-lsp 빌드가 만료되어 자동 시작 시 exit code 7 발생
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
