return {
  "stevearc/oil.nvim",
  ---@module 'oil'
  ---@type oil.SetupOpts
  opts = {
    view_options = {
      -- .env 같은 숨김 파일 표시
      show_hidden = true,
    },
  },
  -- Optional dependencies
  dependencies = { { "nvim-mini/mini.icons", opts = {} } },
  -- dependencies = { "nvim-tree/nvim-web-devicons" }, -- use if you prefer nvim-web-devicons
  -- Lazy loading is not recommended because it is very tricky to make it work correctly in all situations.
  lazy = false,
  config = function(_, opts)
    require("oil").setup(opts)

    -- 인자 없이 실행하면 대시보드 대신 oil 파일 탐색기로 시작
    vim.api.nvim_create_autocmd("VimEnter", {
      callback = function()
        if vim.fn.argc(-1) > 0 or vim.api.nvim_buf_get_name(0) ~= "" then
          return
        end
        if #vim.api.nvim_list_uis() == 0 then
          return
        end
        require("oil").open()
      end,
    })
  end,
}
