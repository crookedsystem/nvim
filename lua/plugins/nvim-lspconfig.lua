return {
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, { "prisma" })
    end,
  },
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        prismals = {},
        dartls = {
          mason = false,
          cmd = function(dispatchers, config)
            return vim.lsp.rpc.start({ "fvm", "dart", "language-server", "--protocol=lsp" }, dispatchers, {
              cwd = config.root_dir,
            })
          end,
        },
      },
    },
  },
}
