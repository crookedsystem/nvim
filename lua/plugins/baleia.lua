return {
  {
    "m00qek/baleia.nvim",
    version = "*",
    lazy = false,
    config = function()
      local baleia = require("baleia").setup({})

      -- 현재 버퍼의 ANSI 코드를 한 번 색으로 변환한다.
      vim.api.nvim_create_user_command("BaleiaColorize", function()
        baleia.once(vim.api.nvim_get_current_buf())
      end, {})

      -- 로그·ANSI 파일은 읽어 들일 때마다 색을 입힌다. 코드 제거로 생기는 수정 표시는
      -- 닫을 때 저장 확인이 뜨지 않도록 지운다.
      vim.api.nvim_create_autocmd("BufReadPost", {
        group = vim.api.nvim_create_augroup("BaleiaAutoColorize", { clear = true }),
        pattern = { "*.log", "*.ansi" },
        callback = function(event)
          vim.schedule(function()
            baleia.once(event.buf)
            vim.bo[event.buf].modified = false
          end)
        end,
      })
    end,
  },
}
