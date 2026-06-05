return {
  {
    "nvim-treesitter/nvim-treesitter",
    opts = {
      ensure_installed = { "prisma" },
    },
  },
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        prismals = {},
        pyright = { enabled = false },
        ruff = { enabled = false },
        pylsp = {
          -- mypy 타입체킹을 위해 pylsp-mypy와 ruff 추가
          cmd = {
            "uv",
            "run",
            "--with",
            "python-lsp-server,pylsp-rope,ruff,pylsp-mypy,mypy",
            "pylsp",
          },
          settings = {
            pylsp = {
              plugins = {
                -- Rope-based auto-imports
                rope_autoimport = {
                  enabled = true,
                  code_actions = true,
                },
                -- Ruff for linting/organizing imports
                ruff = { enabled = true },
                -- Mypy for type checking
                pylsp_mypy = {
                  enabled = true,
                  live_mode = true, -- true로 하면 실시간, false면 저장시에만
                  strict = true, -- 엄격한 타입체킹 원하면 true
                },
                -- 기본 pylsp 기능들 (필요에 따라 조정)
                pycodestyle = { enabled = false }, -- ruff 사용하므로 비활성화
                pyflakes = { enabled = false }, -- ruff 사용하므로 비활성화
                pylint = { enabled = false }, -- ruff 사용하므로 비활성화
                yapf = { enabled = false }, -- ruff 사용하므로 비활성화
                autopep8 = { enabled = false }, -- ruff 사용하므로 비활성화
                mccabe = { enabled = false }, -- ruff 사용하므로 비활성화
              },
            },
          },
        },
      },
    },
  },
}
