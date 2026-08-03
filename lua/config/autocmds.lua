-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

-- didOpen 전에 oil:// 버퍼 attach를 차단 (vtsls UriError 방지)
local original_buf_attach = vim.lsp.buf_attach_client
vim.lsp.buf_attach_client = function(bufnr, client_id)
  local bufname = vim.api.nvim_buf_get_name(bufnr)
  if bufname:match("^oil://") then
    return false
  end
  return original_buf_attach(bufnr, client_id)
end

-- 정의 위치에서 gd를 누르면(더 갈 곳이 없으면) references로 폴백 (VSCode의
-- editor.gotoLocation.alternativeDefinitionCommand 기본 동작과 동일)
local function goto_definition_or_references()
  local origin_notify = vim.notify
  vim.notify = function(msg, ...)
    if msg == "No locations found" then
      vim.notify = origin_notify
      vim.lsp.buf.references()
      return
    end
    return origin_notify(msg, ...)
  end

  vim.lsp.buf.definition({
    on_list = function(list)
      vim.notify = origin_notify

      local item = list.items[1]
      if #list.items == 1 and item.filename == vim.api.nvim_buf_get_name(0) and item.lnum == vim.fn.line(".") then
        vim.lsp.buf.references()
        return
      end

      -- 단일 결과는 vim.lsp.buf.definition()의 기본 동작처럼 바로 이동 (on_list를
      -- 넘기면 이 점프 로직이 대체되어 버리므로 직접 재현)
      if #list.items == 1 then
        local buf = item.bufnr or vim.fn.bufadd(item.filename)
        vim.cmd("normal! m'")
        vim.bo[buf].buflisted = true
        vim.api.nvim_win_set_buf(0, buf)
        vim.api.nvim_win_set_cursor(0, { item.lnum, item.col - 1 })
        vim.cmd("normal! zv")
        return
      end

      vim.fn.setloclist(0, {}, " ", list)
      vim.cmd.lopen()
    end,
  })
end

-- LSP 네비게이션을 vim.lsp.buf 직접 호출로 오버라이드 (buffer-local)
vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(args)
    local buf = args.buf
    local opts = { buffer = buf, silent = true }
    vim.schedule(function()
      if not vim.api.nvim_buf_is_loaded(buf) then
        return
      end

      vim.keymap.set(
        "n",
        "gd",
        goto_definition_or_references,
        vim.tbl_extend("force", opts, { desc = "Goto Definition (or References)" })
      )
      vim.keymap.set(
        "n",
        "gI",
        vim.lsp.buf.implementation,
        vim.tbl_extend("force", opts, { desc = "Goto Implementation" })
      )
      vim.keymap.set("n", "gr", vim.lsp.buf.references, vim.tbl_extend("force", opts, { desc = "References" }))
      vim.keymap.set(
        "n",
        "gy",
        vim.lsp.buf.type_definition,
        vim.tbl_extend("force", opts, { desc = "Goto Type Definition" })
      )
    end)
  end,
})

-- 특정 파일타입만 autoformat 활성화
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "java", "typescript", "kotlin", "yaml", "json" },
  callback = function()
    vim.b.autoformat = true
  end,
})

-- Markdown 파일에서 spell check 비활성화
vim.api.nvim_create_autocmd("FileType", {
  pattern = "markdown",
  callback = function()
    vim.opt_local.spell = false
  end,
})
