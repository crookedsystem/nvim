local M = {}
local command_name = "nvim.typescript.selectImport"
local script = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":h:h:h")
  .. "/scripts/typescript-import-paths.cjs"

local function unchanged(buf, tick)
  if vim.api.nvim_buf_is_valid(buf) and vim.api.nvim_buf_get_changedtick(buf) == tick then
    return true
  end
  vim.notify("Buffer changed; run Code Action again to select an import", vim.log.levels.WARN)
  return false
end

local function import_diagnostic(action)
  local command = type(action.command) == "table" and action.command
  local args = command and command.arguments and command.arguments[1]
  local fix = type(args) == "table" and (args.action or args)
  if fix and fix.fixName == "import" then
    return args.diagnostic or (action.diagnostics and action.diagnostics[1]) or command.arguments[2]
  end
end

local function apply(action, client, ctx, tick)
  if not unchanged(ctx.bufnr, tick) then
    return
  end
  if action.edit then
    vim.lsp.util.apply_workspace_edit(action.edit, client.offset_encoding)
  end
  if action.command then
    client:exec_cmd(action.command, ctx)
  end
end

local function select_paths(actions, client, ctx, tick)
  if not unchanged(ctx.bufnr, tick) then
    return
  end
  local function show(options)
    if not unchanged(ctx.bufnr, tick) then
      return
    end
    vim.ui.select(options, {
      prompt = "Select import module / path:",
      kind = "typescript_import",
      format_item = function(item)
        return item.label
      end,
    }, function(choice)
      if choice then
        local action = vim.deepcopy(actions[choice.index])
        action.edit = choice.edit
        apply(action, client, ctx, tick)
      end
    end)
  end

  local fallback = vim.tbl_map(function(action)
    return { label = action.title, index = 0, edit = action.edit }
  end, actions)
  for index, item in ipairs(fallback) do
    item.index = index
  end
  local executable = client.config.cmd
  executable = type(executable) == "table" and vim.fn.exepath(executable[1]) or ""
  local input = {
    file = vim.api.nvim_buf_get_name(ctx.bufnr),
    uri = vim.uri_from_bufnr(ctx.bufnr),
    server = executable,
    actions = actions,
  }
  vim.system({ "node", script }, { stdin = vim.json.encode(input), text = true }, function(result)
    vim.schedule(function()
      local ok, options = pcall(vim.json.decode, result.stdout or "")
      if result.code ~= 0 or not ok or type(options) ~= "table" or #options == 0 then
        vim.notify("Import path lookup unavailable; showing language server candidates", vim.log.levels.WARN)
        show(fallback)
      else
        show(options)
      end
    end)
  end)
end

local function select_import(command, ctx)
  local state = command.arguments[1]
  local client = vim.lsp.get_client_by_id(ctx.client_id)
  if not client or not unchanged(ctx.bufnr, state.tick) then
    return
  end
  local diagnostic = state.diagnostic
  local actions = {}
  for _, item in ipairs(state.imports) do
    if item.client_id == client.id and vim.deep_equal(item.diagnostic.range, diagnostic.range) then
      table.insert(actions, item.action)
    end
  end

  -- 기존 식별자 끝에서 자동완성을 조회한다. 식별자를 다시 쓰거나 함수 호출
  -- 스니펫이 포함될 수 있는 primary textEdit를 적용하지 않는다.
  local range = diagnostic.range
  local lines = vim.api.nvim_buf_get_lines(ctx.bufnr, range.start.line, range["end"].line + 1, false)
  if #lines ~= 1 then
    return select_paths(actions, client, ctx, state.tick)
  end
  local start_col = vim.str_byteindex(lines[1], client.offset_encoding, range.start.character, false)
  local end_col = vim.str_byteindex(lines[1], client.offset_encoding, range["end"].character, false)
  local name = lines[1]:sub(start_col + 1, end_col)
  local params = {
    textDocument = { uri = vim.uri_from_bufnr(ctx.bufnr) },
    position = range["end"],
    context = { triggerKind = vim.lsp.protocol.CompletionTriggerKind.Invoked },
  }
  client:request("textDocument/completion", params, function(err, result)
    if not unchanged(ctx.bufnr, state.tick) then
      return
    end
    local items = not err and result and (result.items or result) or {}
    local matches = vim.tbl_filter(function(item)
      return item.label == name
    end, items)
    local pending = #matches
    if pending == 0 then
      return select_paths(actions, client, ctx, state.tick)
    end
    local function resolved(item)
      if item and item.additionalTextEdits and #item.additionalTextEdits > 0 then
        table.insert(actions, {
          title = "Import " .. name,
          edit = { changes = { [params.textDocument.uri] = item.additionalTextEdits } },
          command = item.command,
        })
      end
      pending = pending - 1
      if pending == 0 then
        select_paths(actions, client, ctx, state.tick)
      end
    end
    for _, item in ipairs(matches) do
      if client:supports_method("completionItem/resolve") then
        client:request("completionItem/resolve", item, function(resolve_err, completion)
          resolved(not resolve_err and completion or item)
        end, ctx.bufnr)
      else
        resolved(item)
      end
    end
  end, ctx.bufnr)
end

function M.code_action()
  local buf = vim.api.nvim_get_current_buf()
  local tick = vim.api.nvim_buf_get_changedtick(buf)
  local imports = {}
  vim.lsp.buf.code_action({
    filter = function(action, client_id)
      local client = vim.lsp.get_client_by_id(client_id)
      local diagnostic = client and client.name == "vtsls" and import_diagnostic(action)
      if diagnostic then
        table.insert(imports, {
          client_id = client_id,
          diagnostic = diagnostic,
          action = vim.deepcopy(action),
        })
        client.commands[command_name] = select_import
        -- 기본 Code Action의 서버별 결과 수집과 resolve는 유지하면서,
        -- import 편집은 로컬 명령을 통해 경로를 고른 뒤 적용한다.
        action.edit = nil
        action.data = nil
        action.command = command_name
        action.arguments = { { tick = tick, diagnostic = diagnostic, imports = imports } }
      end
      return true
    end,
  })
end

return M
