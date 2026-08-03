return {
  {
    "MagicDuck/grug-far.nvim",
    cmd = { "GrugFar", "GrugFarWithin" },
    keys = {
      { "<leader>sr", "<cmd>GrugFar<cr>", desc = "Search and Replace (grug-far)" },
      { "<leader>sr", "<cmd>GrugFarWithin<cr>", mode = "x", desc = "Search and Replace in Selection (grug-far)" },
    },
    opts = {},
  },
}
