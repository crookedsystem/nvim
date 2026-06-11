return {
  -- JetBrains kotlin-lsp는 Mason 패키지가 안정화될 때까지 끄고, LazyVim 기본 서버를 사용한다.
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        kotlin_language_server = { enabled = true },
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
