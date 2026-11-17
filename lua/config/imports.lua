local M = {}
local servers = { basedpyright = true, kotlin_lsp = true, jdtls = true }
local command_name = "nvim.imports.select"

local function current(state)
  if vim.api.nvim_buf_is_valid(state.buf) and vim.api.nvim_buf_get_changedtick(state.buf) == state.tick then
    return true
  end
  if not state.discarded then
    vim.notify("Buffer changed; run Code Action again to select an import", vim.log.levels.WARN)
    state.discarded = true
  end
  return false
end

local function import_action(action)
  if action.disabled or (action.kind and not vim.startswith(action.kind, "quickfix")) then
    return false
  end
  local title = action.title:lower()
  return title:match("^import[%s(]") or title:match("^from .- import ") or title:match("^add import")
end

local function missing(diagnostic)
  local code = diagnostic.code
  code = type(code) == "table" and code.value or code
  local message = diagnostic.message:lower()
  return code == "reportUndefinedVariable"
    or tostring(code):upper():find("UNRESOLVED_REFERENCE", 1, true)
    or message:find("unresolved reference", 1, true)
    or message:find("cannot be resolved to a type", 1, true)
    or message:find("cannot be resolved to a variable", 1, true)
end

local function symbol_at(client, buf, range)
  if range.start.line ~= range["end"].line then
    return
  end
  local line = vim.api.nvim_buf_get_lines(buf, range.start.line, range.start.line + 1, false)[1]
  if not line then
    return
  end
  local start_col = vim.str_byteindex(line, client.offset_encoding, range.start.character, false)
  local end_col = vim.str_byteindex(line, client.offset_encoding, range["end"].character, false)
  local name = line:sub(start_col + 1, end_col)
  return name ~= "" and not name:find("%s") and name or nil
end

local function import_label(action, state)
  local edits = action.edit and action.edit.changes and action.edit.changes[state.uri] or {}
  for _, change in ipairs(action.edit and action.edit.documentChanges or {}) do
    if change.textDocument and change.textDocument.uri == state.uri then
      edits = vim.list_extend(vim.deepcopy(edits), change.edits)
    end
  end
  for _, edit in ipairs(edits) do
    for line in edit.newText:gmatch("[^\r\n]+") do
      if line:find(state.name, 1, true) then
        local from = line:match("^%s*(from%s+.+%s+import%s+.+)")
        if from then
          return from
        end
        local qualified = line:match("^%s*import%s+static%s+([^;%s]+)") or line:match("^%s*import%s+([^;%s]+)")
        if qualified then
          return qualified
        end
      end
    end
  end
  return action.title
end

local function apply(action, state)
  if not current(state) then
    return
  end
  if action.edit then
    vim.lsp.util.apply_workspace_edit(action.edit, state.client.offset_encoding)
  end
  if action.command then
    local command = type(action.command) == "string" and action or action.command
    state.client:exec_cmd(command, { bufnr = state.buf, client_id = state.client.id, params = state.params })
  end
end

local function choose(state)
  if not current(state) then
    return
  end
  local choices, seen = {}, {}
  local pending = 1
  local function add(action)
    local label = import_label(action, state)
    if not seen[label] then
      seen[label] = true
      table.insert(choices, { label = label, action = action })
    end
  end
  local function finished()
    pending = pending - 1
    if pending ~= 0 or not current(state) then
      return
    end
    if #choices == 0 then
      vim.notify("No import candidates for " .. state.name, vim.log.levels.INFO)
      return
    end
    table.sort(choices, function(a, b)
      return a.label < b.label
    end)
    vim.ui.select(choices, {
      prompt = "Select import for " .. state.name .. ":",
      kind = "lsp_import",
      format_item = function(choice)
        return choice.label
      end,
    }, function(choice)
      if choice then
        apply(choice.action, state)
      end
    end)
  end
  for _, action in ipairs(state.actions) do
    if action.data and not action.edit and state.client:supports_method("codeAction/resolve") then
      pending = pending + 1
      state.client:request("codeAction/resolve", action, function(err, resolved)
        if not err and resolved then
          add(resolved)
        elseif action.command then
          add(action)
        end
        finished()
      end, state.buf)
    else
      add(action)
    end
  end
  if state.client:supports_method("textDocument/completion") then
    pending = pending + 1
    state.client:request("textDocument/completion", {
      textDocument = { uri = state.uri },
      position = state.range["end"],
      context = { triggerKind = vim.lsp.protocol.CompletionTriggerKind.Invoked },
    }, function(err, result)
      for _, item in ipairs(not err and result and (result.items or result) or {}) do
        local name = item.filterText or item.label
        if name == state.name or item.label == state.name or name:match("^([%w_$]+)%s*[%(%-:]") == state.name then
          local function resolved(completion)
            -- Kotlin의 command-only completion은 이름과 괄호도 서버에서 삽입한다.
            -- 붙여넣은 식을 보존하기 위해 import 편집이 명시된 후보만 보완한다.
            if completion and completion.additionalTextEdits and #completion.additionalTextEdits > 0 then
              add({
                title = "Import " .. state.name,
                edit = { changes = { [state.uri] = completion.additionalTextEdits } },
                command = completion.command,
              })
            end
            finished()
          end
          pending = pending + 1
          if state.client:supports_method("completionItem/resolve") then
            state.client:request("completionItem/resolve", item, function(resolve_err, completion)
              resolved(not resolve_err and completion or item)
            end, state.buf)
          else
            resolved(item)
          end
        end
      end
      finished()
    end, state.buf)
  end
  finished()
end

local function augment(client, params, result, buf, tick)
  local only = params.context.only
  if
    params.context.triggerKind == vim.lsp.protocol.CodeActionTriggerKind.Automatic
    or (only and not vim.tbl_contains(only, "quickfix"))
  then
    return result
  end
  local imports = vim.tbl_filter(import_action, result or {})
  local claimed, names, selectors = {}, {}, {}
  for _, diagnostic in ipairs(params.context.diagnostics or {}) do
    if missing(diagnostic) then
      local name = symbol_at(client, buf, diagnostic.range)
      if name and not names[name] then
        names[name] = true
        local actions = vim.tbl_filter(function(action)
          if action.diagnostics and #action.diagnostics > 0 then
            return vim.iter(action.diagnostics):any(function(d)
              return vim.deep_equal(d.range, diagnostic.range)
            end)
          end
          local first, last = action.title:find(name, 1, true)
          return first
            and not action.title:sub(first - 1, first - 1):match("[%w_$]")
            and not action.title:sub(last + 1, last + 1):match("[%w_$]")
        end, imports)
        for _, action in ipairs(actions) do
          claimed[action] = true
        end
        local state = {
          client = client,
          buf = buf,
          tick = tick,
          uri = params.textDocument.uri,
          name = name,
          range = diagnostic.range,
          params = params,
          actions = actions,
        }
        table.insert(selectors, {
          title = "Choose import for " .. name,
          kind = "quickfix",
          command = command_name,
          arguments = { state },
        })
      end
    end
  end
  vim.list_extend(
    selectors,
    vim.tbl_filter(function(action)
      return not claimed[action]
    end, result or {})
  )
  return selectors
end

function M.attach(client)
  if not servers[client.name] or client._import_picker_attached then
    return
  end
  client._import_picker_attached = true
  client.commands[command_name] = function(command)
    choose(command.arguments[1])
  end
  local request = client.request
  client.request = function(self, method, params, handler, buf)
    if method == "textDocument/codeAction" and handler then
      local callback = handler
      local target = buf and buf ~= 0 and buf or vim.uri_to_bufnr(params.textDocument.uri)
      local tick = vim.api.nvim_buf_get_changedtick(target)
      handler = function(err, result, ctx, config)
        if not err and vim.api.nvim_buf_is_valid(target) then
          if vim.api.nvim_buf_get_changedtick(target) == tick then
            result = augment(self, params, result, target, tick)
          else
            result = {}
            vim.notify("Buffer changed; run Code Action again", vim.log.levels.WARN)
          end
        end
        return callback(err, result, ctx, config)
      end
    end
    return request(self, method, params, handler, buf)
  end
end

function M.setup()
  vim.api.nvim_create_autocmd("LspAttach", {
    group = vim.api.nvim_create_augroup("import-picker", { clear = true }),
    callback = function(args)
      local client = vim.lsp.get_client_by_id(args.data.client_id)
      if client then
        M.attach(client)
      end
    end,
  })
  for _, client in ipairs(vim.lsp.get_clients()) do
    M.attach(client)
  end
end

return M
