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
      { "<leader>gH", "<cmd>DiffviewFileHistory %<cr>", desc = "File History (current file)" },
    },
    opts = {
      enhanced_diff_hl = true,
      view = {
        default = {
          layout = "diff2_horizontal",
          winbar_info = true,
        },
        merge_tool = {
          layout = "diff3_mixed",
          disable_diagnostics = true,
          winbar_info = true,
        },
        file_history = {
          layout = "diff2_horizontal",
          winbar_info = true,
        },
        -- g<C-x>로 diff2_horizontal <-> unified inline(diff1_inline) 순환
        cycle_layouts = {
          default = { "diff2_horizontal", "diff2_vertical", "diff1_inline" },
        },
      },
    },
  },
}
