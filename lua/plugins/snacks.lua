return {
  "folke/snacks.nvim",
  opts = {
    -- 시작 화면을 대시보드 대신 oil 파일 탐색기로 대체 (lua/config/autocmds.lua)
    dashboard = { enabled = false },
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
