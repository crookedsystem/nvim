local M = {}

--- Pure predicate for whether the oil startup screen should replace the
--- current buffer. Kept side-effect free so it stays testable headless
--- (a real piped-stdin VimEnter can't be reproduced under `nvim --headless`).
---@param argc integer vim.fn.argc(-1)
---@param bufname string vim.api.nvim_buf_get_name(0)
---@param uis table vim.api.nvim_list_uis()
---@param buf_line_count integer vim.api.nvim_buf_line_count(0)
---@param first_line string first line of the current buffer, or ""
---@return boolean
function M.should_open(argc, bufname, uis, buf_line_count, first_line)
  if argc > 0 or bufname ~= "" then
    return false
  end
  if #uis == 0 then
    return false
  end
  if uis[1].stdout_tty and not uis[1].stdin_tty then
    return false
  end
  if buf_line_count > 1 or #first_line > 0 then
    return false
  end
  return true
end

return M
