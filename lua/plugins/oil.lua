return {
  "stevearc/oil.nvim",
  -- autocmds.lua는 인자 없는 실행에서 VimEnter 이후에 로드되므로 여기서 등록한다.
  init = function()
    vim.api.nvim_create_autocmd("VimEnter", {
      once = true,
      -- Oil의 :edit가 BufReadCmd를 실행해야 디렉터리 목록이 로드된다.
      nested = true,
      callback = function()
        local should_open = require("config.oil_startup").should_open(
          vim.fn.argc(-1),
          vim.api.nvim_buf_get_name(0),
          vim.api.nvim_list_uis(),
          vim.api.nvim_buf_line_count(0),
          vim.api.nvim_buf_get_lines(0, 0, 1, false)[1] or ""
        )
        if should_open then
          require("oil").open(vim.fn.getcwd())
        end
      end,
    })
  end,
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
}
