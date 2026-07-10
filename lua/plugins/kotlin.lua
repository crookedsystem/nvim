return {
  {
    "mason-org/mason.nvim",
    opts = {
      ensure_installed = { "kotlin-lsp" },
    },
  },
  {
    "neovim/nvim-lspconfig",
    opts = function(_, opts)
      opts.servers = opts.servers or {}
      opts.servers.kotlin_language_server = { enabled = false }
      opts.servers.kotlin_lsp = { enabled = false }
    end,
  },
  {
    "AlexandrosAlexiou/kotlin.nvim",
    ft = { "kotlin" },
    dependencies = {
      "mason-org/mason.nvim",
      "mason-org/mason-lspconfig.nvim",
      "stevearc/oil.nvim",
      "folke/trouble.nvim",
      "mfussenegger/nvim-dap",
    },
    config = function()
      require("kotlin").setup({
        root_markers = {
          { "settings.gradle", "settings.gradle.kts", "mvnw", "mvnw.cmd", ".git" },
          { "build.gradle", "build.gradle.kts", "pom.xml" },
        },
      })
    end,
  },
}
