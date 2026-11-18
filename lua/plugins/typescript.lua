return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        vtsls = {
          settings = {
            typescript = {
              preferences = {
                importModuleSpecifier = "relative",
              },
            },
            javascript = {
              preferences = {
                importModuleSpecifier = "relative",
              },
            },
          },
        },
      },
      setup = {
        eslint = function()
          LazyVim.format.register(LazyVim.lsp.formatter({
            name = "eslint: lsp",
            priority = 200,
            primary = false,
            filter = "eslint",
            format = function(buf)
              vim.lsp.buf.format({ bufnr = buf, name = "eslint", async = false, timeout_ms = 3000 })
            end,
          }))
        end,
      },
    },
    init = function()
      LazyVim.on_very_lazy(function()
        LazyVim.format.register({
          name = "typescript: remove unused imports",
          priority = 300,
          primary = false,
          sources = function(buf)
            return vim.lsp.get_clients({ bufnr = buf, name = "vtsls" })[1] and { "vtsls" } or {}
          end,
          format = function(buf)
            local client = vim.lsp.get_clients({ bufnr = buf, name = "vtsls" })[1]
            local response, err = client:request_sync("workspace/executeCommand", {
              command = "typescript.removeUnusedImports",
              arguments = { vim.api.nvim_buf_get_name(buf) },
            }, 3000, buf)
            if not response or response.err or response.result == false then
              error(response and response.err and response.err.message or err or "Failed to remove unused imports")
            end
          end,
        })
      end)
    end,
  },
  {
    "neovim/nvim-lspconfig",
    -- keys 목록을 opts 테이블로 넘기면 LazyVim vtsls extra의 키(<leader>cM, gR 등)를 통째로 덮어쓰므로 목록에 추가한다
    opts = function(_, opts)
      table.insert(opts.servers.vtsls.keys, {
        "<leader>ca",
        function()
          require("config.typescript_imports").code_action()
        end,
        desc = "Code Action",
        mode = { "n", "x" },
        has = "codeAction",
      })
    end,
  },
}
