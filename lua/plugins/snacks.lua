return {
  "folke/snacks.nvim",
  opts = {
    image = {
      enabled = false,
      convert = {
        notify = false,
      },
      math = {
        enabled = false,
      },
    },
    picker = {
      win = {
        input = {
          keys = {
            ["<a-r>"] = { "toggle_regex", mode = { "i", "n" } },
          },
        },
      },
      sources = {
        files = {
          hidden = true,
        },
        grep = {
          regex = false,
        },
      },
    },
  },
}
