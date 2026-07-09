return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        kotlin_language_server = { enabled = false },
        kotlin_lsp = { enabled = true },
      },
    },
  },
  -- JetBrains kotlin-lsp
  {
    "AlexandrosAlexiou/kotlin.nvim",
    enabled = false,
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
