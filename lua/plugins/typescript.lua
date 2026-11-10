return {
  {
    "neovim/nvim-lspconfig",
    opts = {
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
}
