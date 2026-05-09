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
    "esmuellert/codediff.nvim",
    cmd = "CodeDiff",
    init = function()
      vim.keymap.set("n", "<leader>gd", function()
        require("config.codediff").open_current_file("side-by-side", { fold_unchanged = true })
      end, { desc = "Git Diff (current file, folded)" })

      vim.keymap.set("n", "<leader>gi", function()
        require("config.codediff").open_current_file("inline", { fold_unchanged = true })
      end, { desc = "Git Diff Inline (current file, folded)" })

      vim.keymap.set("n", "<leader>gD", function()
        require("config.codediff").open_repo("side-by-side", { fold_unchanged = true })
      end, { desc = "Git Diff (repo, folded)" })

      vim.keymap.set("n", "<leader>gH", function()
        require("config.codediff").open_history({ fold_unchanged = true })
      end, { desc = "Git History (CodeDiff, folded)" })
    end,
    opts = {
      diff = {
        layout = "side-by-side",
        ignore_trim_whitespace = true,
        jump_to_first_change = true,
        compute_moves = true,
      },
      explorer = {
        position = "left",
        width = 40,
        view_mode = "tree",
        flatten_dirs = true,
      },
      keymaps = {
        view = {
          quit = "q",
          next_hunk = "]c",
          prev_hunk = "[c",
          next_file = "]f",
          prev_file = "[f",
          diff_get = "do",
          diff_put = "dp",
          toggle_stage = "-",
          stage_hunk = "<leader>hs",
          unstage_hunk = "<leader>hu",
          discard_hunk = "<leader>hr",
          toggle_layout = "t",
          show_help = "g?",
        },
      },
    },
  },
}
