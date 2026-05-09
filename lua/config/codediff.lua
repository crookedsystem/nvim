local M = {}

local FOLD_CONTEXT_LINES = 0
local MIN_FOLD_LINES = 1
local FOLD_RETRY_INTERVAL_MS = 50
local MAX_FOLD_RETRY_COUNT = 100

local fold_autocmd_seq = 0

local function ensure_codediff_loaded()
  require("lazy").load({ plugins = { "codediff.nvim" } })
end

local function layout_flag(layout)
  if layout == "inline" then
    return "--inline"
  end
  return "--side-by-side"
end

local function buffer_path(bufnr)
  if vim.bo[bufnr].buftype ~= "" then
    return nil
  end

  local path = vim.api.nvim_buf_get_name(bufnr)
  if path == "" then
    return nil
  end

  return path
end

local function in_git_repo(path)
  local git_dir = vim.fs.find(".git", { path = path, upward = true })[1]
  return git_dir ~= nil
end

local function merge_ranges(ranges)
  table.sort(ranges, function(left, right)
    return left.start_line < right.start_line
  end)

  local merged = {}
  for _, range in ipairs(ranges) do
    local last = merged[#merged]
    if last and range.start_line <= last.end_line + 1 then
      last.end_line = math.max(last.end_line, range.end_line)
    else
      table.insert(merged, range)
    end
  end

  return merged
end

local function changed_range(range, line_count)
  if not range or range.end_line <= range.start_line then
    return nil
  end

  local change_start = math.min(math.max(range.start_line, 1), line_count)
  local change_end = math.min(math.max(range.end_line - 1, 1), line_count)
  if change_end < change_start then
    return nil
  end

  return {
    start_line = math.max(1, change_start - FOLD_CONTEXT_LINES),
    end_line = math.min(line_count, change_end + FOLD_CONTEXT_LINES),
  }
end

local function visible_ranges(changes, side, line_count)
  local ranges = {}

  for _, change in ipairs(changes or {}) do
    local range = changed_range(change[side], line_count)
    if range then
      table.insert(ranges, range)
    end
  end

  return merge_ranges(ranges)
end

local function create_fold(start_line, end_line)
  if end_line - start_line + 1 < MIN_FOLD_LINES then
    return
  end

  vim.cmd(("%d,%dfold"):format(start_line, end_line))
end

local function clear_folds(win)
  if not win or not vim.api.nvim_win_is_valid(win) then
    return
  end

  vim.api.nvim_win_call(win, function()
    vim.wo.foldmethod = "manual"
    vim.cmd("silent! normal! zE")
  end)
end

local function restore_source_buffer(win, bufnr)
  if vim.api.nvim_win_is_valid(win) then
    vim.api.nvim_set_current_win(win)

    if vim.api.nvim_buf_is_valid(bufnr) and vim.api.nvim_win_get_buf(win) ~= bufnr then
      vim.api.nvim_win_set_buf(win, bufnr)
    end
  end
end

local function execute_codediff(args, bufnr)
  if vim.api.nvim_buf_is_valid(bufnr) then
    vim.api.nvim_buf_call(bufnr, function()
      vim.cmd("CodeDiff " .. args)
    end)
    return
  end

  vim.cmd("CodeDiff " .. args)
end

local function normalize_path(path)
  return path and path:gsub("\\", "/") or nil
end

local function ends_with(value, suffix)
  return value:sub(-#suffix) == suffix
end

local function path_matches(path, expected_path)
  path = normalize_path(path)
  expected_path = normalize_path(expected_path)

  if not path or not expected_path or expected_path == "" then
    return false
  end

  return path == expected_path or ends_with(path, "/" .. expected_path)
end

local function session_matches_path(session, expected_path)
  if not expected_path then
    return true
  end

  return path_matches(session.original_path, expected_path) or path_matches(session.modified_path, expected_path)
end

local function fold_unchanged_window(win, bufnr, changes, side)
  if not win or not vim.api.nvim_win_is_valid(win) or not vim.api.nvim_buf_is_valid(bufnr) then
    return
  end

  vim.api.nvim_win_call(win, function()
    local line_count = vim.api.nvim_buf_line_count(bufnr)
    if line_count == 0 then
      return
    end

    vim.wo.foldmethod = "manual"
    vim.wo.foldenable = true
    vim.wo.foldminlines = 0
    vim.wo.foldtext = "v:lua.require'config.codediff'.fold_text()"
    vim.cmd("silent! normal! zE")

    local next_fold_start = 1
    for _, range in ipairs(visible_ranges(changes, side, line_count)) do
      create_fold(next_fold_start, range.start_line - 1)
      next_fold_start = range.end_line + 1
    end

    create_fold(next_fold_start, line_count)
    vim.cmd("silent! normal! zM")
  end)
end

local function clear_session_folds(session)
  clear_folds(session.original_win)
  clear_folds(session.modified_win)
end

local function apply_changed_folds(tabpage, retry_count, expected_path)
  retry_count = retry_count or 0

  local ok, lifecycle = pcall(require, "codediff.ui.lifecycle")
  if not ok then
    return
  end

  local session = lifecycle.get_session(tabpage)
  if not session or not session_matches_path(session, expected_path) then
    if retry_count < MAX_FOLD_RETRY_COUNT then
      vim.defer_fn(function()
        apply_changed_folds(tabpage, retry_count + 1, expected_path)
      end, FOLD_RETRY_INTERVAL_MS)
    end
    return
  end

  local changes = session and session.stored_diff_result and session.stored_diff_result.changes
  if not changes then
    if retry_count < MAX_FOLD_RETRY_COUNT then
      vim.defer_fn(function()
        apply_changed_folds(tabpage, retry_count + 1, expected_path)
      end, FOLD_RETRY_INTERVAL_MS)
    end
    return
  end

  if #changes == 0 then
    clear_session_folds(session)
    return
  end

  if session.layout == "inline" then
    fold_unchanged_window(session.modified_win, session.modified_bufnr, changes, "modified")
    return
  end

  fold_unchanged_window(session.original_win, session.original_bufnr, changes, "original")
  fold_unchanged_window(session.modified_win, session.modified_bufnr, changes, "modified")
end

local function create_fold_autocmds()
  fold_autocmd_seq = fold_autocmd_seq + 1

  local did_open = false
  local opened_tabpage
  local group = vim.api.nvim_create_augroup("config_codediff_folds_" .. fold_autocmd_seq, { clear = true })

  vim.api.nvim_create_autocmd("User", {
    group = group,
    pattern = "CodeDiffOpen",
    callback = function(event)
      if not event.data or not event.data.tabpage then
        return
      end

      did_open = true
      opened_tabpage = event.data.tabpage
      apply_changed_folds(opened_tabpage)
    end,
  })

  vim.api.nvim_create_autocmd("User", {
    group = group,
    pattern = "CodeDiffFileSelect",
    callback = function(event)
      if not event.data or not event.data.tabpage then
        return
      end
      if opened_tabpage and event.data.tabpage ~= opened_tabpage then
        return
      end

      vim.defer_fn(function()
        apply_changed_folds(event.data.tabpage, 0, event.data.path)
      end, FOLD_RETRY_INTERVAL_MS)
    end,
  })

  vim.api.nvim_create_autocmd("User", {
    group = group,
    pattern = "CodeDiffClose",
    callback = function(event)
      if opened_tabpage and event.data and event.data.tabpage ~= opened_tabpage then
        return
      end

      pcall(vim.api.nvim_del_augroup_by_id, group)
    end,
  })

  vim.defer_fn(function()
    if not did_open then
      pcall(vim.api.nvim_del_augroup_by_id, group)
    end
  end, FOLD_RETRY_INTERVAL_MS * MAX_FOLD_RETRY_COUNT)
end

local function run_codediff(args, opts)
  local source_win = vim.api.nvim_get_current_win()
  local source_buf = vim.api.nvim_get_current_buf()

  ensure_codediff_loaded()
  restore_source_buffer(source_win, source_buf)

  opts = opts or {}

  if opts.fold_unchanged then
    create_fold_autocmds()
  end

  execute_codediff(args, source_buf)
end

function M.open_current_file(layout, opts)
  local path = buffer_path(vim.api.nvim_get_current_buf())
  if path and in_git_repo(path) then
    run_codediff(("file HEAD %s"):format(layout_flag(layout)), opts)
    return
  end

  vim.notify("Current buffer is not a git file; opening repository diff", vim.log.levels.INFO)
  M.open_repo(layout, opts)
end

function M.open_repo(layout, opts)
  run_codediff(layout_flag(layout), opts)
end

function M.open_history(opts)
  local path = buffer_path(vim.api.nvim_get_current_buf())
  if path and in_git_repo(path) then
    run_codediff("history %", opts)
    return
  end

  run_codediff("history", opts)
end

function M.fold_text()
  local line_count = vim.v.foldend - vim.v.foldstart + 1
  local suffix = line_count == 1 and "" or "s"
  return ("  ... %d unchanged line%s folded"):format(line_count, suffix)
end

return M
