local function stage_selection()
  local view = require("diffview.lib").get_current_view()
  local RevType = require("diffview.vcs.rev").RevType
  if
    not (view and view.left and view.right and view.left.type == RevType.STAGE and view.right.type == RevType.LOCAL)
  then
    vim.notify("줄 단위 stage는 :DiffviewOpen의 Changes에서 사용할 수 있습니다.", vim.log.levels.WARN)
    return
  end

  local layout = view.cur_layout
  if not (layout and layout.a and layout.b and vim.wo.diff) then
    vim.notify("줄 단위 stage는 좌우 또는 상하 diff 레이아웃에서 사용할 수 있습니다.", vim.log.levels.WARN)
    return
  end
  local index = layout.a.file
  local working = layout.b.file
  if not (index and working and index.rev.type == RevType.STAGE and index.rev.stage == 0) then
    vim.notify("Changes의 파일을 선택해 주세요.", vim.log.levels.WARN)
    return
  end
  local current = vim.api.nvim_get_current_buf()
  if current ~= index.bufnr and current ~= working.bufnr then
    return
  end
  if vim.bo[index.bufnr].modified then
    vim.notify("INDEX 창의 편집 내용을 먼저 저장해 주세요.", vim.log.levels.WARN)
    return
  end

  local first, last = vim.fn.line("v"), vim.fn.line(".")
  if first > last then
    first, last = last, first
  end
  vim.cmd.normal({ args = { vim.api.nvim_replace_termcodes("<Esc>", true, false, true) }, bang = true })
  if current == working.bufnr then
    vim.cmd.diffput({ range = { first, last }, args = { tostring(index.bufnr) } })
  else
    vim.cmd.diffget({ range = { first, last }, args = { tostring(working.bufnr) } })
  end
  vim.api.nvim_buf_call(index.bufnr, function()
    vim.cmd.write()
  end)
  view:update_files()
end

local function goto_file_and_close()
  require("diffview.actions").goto_file_edit_close()
end

-- File History는 처음 열 때 첫 변경 지점으로 이동하므로, 열기 전에 보던 파일과 화면 위치를 기억해 둔다.
local pending_file_history_position

local function open_current_file_history()
  pending_file_history_position = {
    file_path = vim.fn.resolve(vim.api.nvim_buf_get_name(0)),
    saved_view = vim.fn.winsaveview(),
  }
  vim.cmd("DiffviewFileHistory %")
end

-- diffview는 cursor_map에 저장된 위치가 있으면 첫 변경 지점 대신 그 위치를 복원하므로, 기억한 화면 위치를 미리 넣어 둔다.
local function seed_file_history_position(view)
  local position = pending_file_history_position
  pending_file_history_position = nil
  if not (position and view.cursor_map and view.adapter) then
    return
  end
  local repo_relative_path = vim.fs.relpath(vim.fn.resolve(view.adapter.ctx.toplevel), position.file_path)
  if repo_relative_path then
    view.cursor_map[repo_relative_path] = position.saved_view
  end
end

return {
  {
    "folke/snacks.nvim",
    keys = {
      { "<leader>gd", false },
      { "<leader>gD", false },
      { "<leader>gi", false },
    },
  },
  {
    "dlyongemallo/diffview-plus.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    cmd = {
      "DiffviewOpen",
      "DiffviewClose",
      "DiffviewToggleFiles",
      "DiffviewFocusFiles",
      "DiffviewRefresh",
      "DiffviewFileHistory",
    },
    keys = {
      { "<leader>gd", "<cmd>DiffviewOpen HEAD -- %<cr>", desc = "Diffview (current file)" },
      { "<leader>gD", "<cmd>DiffviewOpen<cr>", desc = "Diffview (repo)" },
      { "<leader>gH", open_current_file_history, desc = "File History (current file)" },
      { "<leader>gA", "<cmd>DiffviewFileHistory<cr>", desc = "File History (repo)" },
    },
    opts = {
      enhanced_diff_hl = true,
      hooks = {
        view_opened = seed_file_history_position,
      },
      keymaps = {
        view = {
          -- Unified에서도 Flash의 s로 빠지지 않고 지원 여부를 안내한다.
          { "x", "s", stage_selection, { desc = "Stage selected lines" } },
          { "n", "gF", goto_file_and_close, { desc = "Open file and close Diffview" } },
          { "n", "q", "<cmd>DiffviewClose<cr>", { desc = "Close Diffview" } },
        },
        file_panel = {
          { "n", "gF", goto_file_and_close, { desc = "Open file and close Diffview" } },
          { "n", "q", "<cmd>DiffviewClose<cr>", { desc = "Close Diffview" } },
        },
        file_history_panel = {
          { "n", "gF", goto_file_and_close, { desc = "Open file and close Diffview" } },
          { "n", "q", "<cmd>DiffviewClose<cr>", { desc = "Close Diffview" } },
        },
      },
      view = {
        default = {
          layout = "diff1_inline",
          winbar_info = true,
        },
        merge_tool = {
          layout = "diff3_mixed",
          disable_diagnostics = true,
          winbar_info = true,
        },
        file_history = {
          layout = "diff1_inline",
          winbar_info = true,
        },
        -- g<C-x>로 diff1_inline(unified) -> diff2_horizontal -> diff2_vertical 순환
        cycle_layouts = {
          default = { "diff2_horizontal", "diff2_vertical", "diff1_inline" },
        },
      },
    },
  },
}
