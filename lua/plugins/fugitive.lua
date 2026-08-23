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
    "tpope/vim-fugitive",
    cmd = {
      "G",
      "Git",
      "Gdiffsplit",
      "Gvdiffsplit",
      "Ghdiffsplit",
      "Gclog",
      "Gllog",
      "Gedit",
      "Gsplit",
      "Gvsplit",
      "Gtabedit",
      "Gread",
      "Gwrite",
      "Ggrep",
      "GMove",
      "GRename",
      "GDelete",
      "Gcd",
      "Glcd",
    },
    keys = {
      { "<leader>gd", "<cmd>Gvdiffsplit<cr>", desc = "Git Diff (current file)" },
      { "<leader>gD", "<cmd>Git<cr>", desc = "Git Status (repo)" },
      { "<leader>gH", "<cmd>0Gclog<cr>", desc = "File History (current file)" },
    },
  },
}
