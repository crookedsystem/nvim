-- kotlin-lsp 빌드는 만료 기한이 있는 EAP 라이선스를 내장해 시간이 지나면 실행을 거부한다.
-- ensure_installed는 이미 설치된 패키지를 올려주지 않으므로, 코틀린 파일을 열 때
-- 레지스트리를 갱신하고 새 빌드가 있으면 설치한다. 교체된 바이너리는 재시작 후 적용된다.
local function update_kotlin_lsp_if_outdated()
  local mason_registry = require("mason-registry")
  mason_registry.refresh(function()
    local kotlin_lsp = mason_registry.get_package("kotlin-lsp")
    if not kotlin_lsp:is_installed() or kotlin_lsp:is_installing() then
      return
    end
    if kotlin_lsp:get_installed_version() == kotlin_lsp:get_latest_version() then
      return
    end
    kotlin_lsp:install(nil, function(is_success)
      if is_success then
        vim.schedule(function()
          vim.notify("kotlin-lsp를 최신 빌드로 갱신했습니다. Neovim을 재시작하세요.", vim.log.levels.INFO)
        end)
      end
    end)
  end)
end

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
      update_kotlin_lsp_if_outdated()
      require("kotlin").setup({
        root_markers = {
          { "settings.gradle", "settings.gradle.kts", "mvnw", "mvnw.cmd", ".git" },
          { "build.gradle", "build.gradle.kts", "pom.xml" },
        },
      })
    end,
  },
}
