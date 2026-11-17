-- 실제 Kotlin 서버 만료와 무관하게 lazy resolve와 서버 주도 편집 계약을 검증한다.
vim.opt.runtimepath:prepend(vim.env.NVIM_IMPORT_REPO)
local client
local function run()
  dofile(vim.env.NVIM_IMPORT_REPO .. "/lua/config/autocmds.lua")
  vim.cmd.edit(vim.env.NVIM_IMPORT_FIXTURE .. "/Main.kt")
  vim.bo.filetype = "kotlin"
  local buf = vim.api.nvim_get_current_buf()
  local uri = vim.uri_from_bufnr(buf)
  local initial = "val publisher: SqsPublisher? = null"
  local start = initial:find("SqsPublisher", 1, true) - 1
  local range = { start = { line = 0, character = start }, ["end"] = { line = 0, character = start + 12 } }
  local diagnostic = { code = "UNRESOLVED_REFERENCE", message = "Unresolved reference: SqsPublisher", range = range }
  local executions, resolutions = 0, 0
  local function transport(dispatchers)
    local closed, sequence = false, 0
    return {
      request = function(method, params, callback)
        sequence = sequence + 1
        vim.schedule(function()
          if method == "initialize" then
            return callback(nil, {
              capabilities = {
                textDocumentSync = 1,
                codeActionProvider = { resolveProvider = true },
                completionProvider = { resolveProvider = true },
                executeCommandProvider = { commands = { "test.kotlin.import", "jetbrains.kotlin.completion.apply" } },
              },
            })
          elseif method == "textDocument/codeAction" then
            return callback(nil, {
              { title = "Import SqsPublisher (legacy)", kind = "quickfix", data = { package = "legacy" } },
              { title = "Import SqsPublisher (messaging)", kind = "quickfix", data = { package = "messaging" } },
              { title = "Create class SqsPublisher", kind = "quickfix", data = { create = true } },
            })
          elseif method == "codeAction/resolve" then
            resolutions = resolutions + 1
            params.command = { command = "test.kotlin.import", title = "", arguments = { params.data.package } }
            return callback(nil, params)
          elseif method == "textDocument/completion" then
            return callback(nil, {
              { label = "SqsPublisher", command = { command = "jetbrains.kotlin.completion.apply", title = "" } },
            })
          elseif method == "completionItem/resolve" then
            return callback(nil, params)
          elseif method == "workspace/executeCommand" then
            assert(params.command == "test.kotlin.import", "command-only completion must never run")
            executions = executions + 1
            dispatchers.server_request("workspace/applyEdit", {
              edit = {
                changes = {
                  [uri] = {
                    {
                      range = { start = { line = 0, character = 0 }, ["end"] = { line = 0, character = 0 } },
                      newText = "import " .. params.arguments[1] .. ".SqsPublisher\n\n",
                    },
                  },
                },
              },
            })
            return callback(nil, nil)
          end
          callback(nil, nil)
        end)
        return true, sequence
      end,
      notify = function(method)
        if method == "textDocument/didOpen" or method == "textDocument/didChange" then
          vim.schedule(function()
            dispatchers.notification("textDocument/publishDiagnostics", { uri = uri, diagnostics = { diagnostic } })
          end)
        end
        return true
      end,
      is_closing = function()
        return closed
      end,
      terminate = function()
        closed = true
      end,
    }
  end
  client = assert(vim.lsp.get_client_by_id(assert(vim.lsp.start({ name = "kotlin_lsp", cmd = transport }))))
  local function wait_for(predicate)
    assert(vim.wait(3000, predicate, 10), "Kotlin import protocol did not finish")
  end
  wait_for(function()
    return #vim.diagnostic.get(buf) > 0
  end)
  local function reset()
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, { initial })
    vim.api.nvim_win_set_cursor(0, { 1, start + 2 })
  end
  local done
  local select_action
  select_action = function(items, opts, callback)
    if opts.kind == "codeaction" then
      assert(
        vim.iter(items):any(function(item)
          return item.action.title == "Create class SqsPublisher"
        end),
        "non-import Kotlin action must remain available"
      )
      for _, item in ipairs(items) do
        if item.action.title == "Choose import for SqsPublisher" then
          return callback(item)
        end
      end
      error("Kotlin import selector missing")
    end
    assert(opts.kind == "lsp_import" and #items == 2, "expected two Kotlin import actions")
    assert(resolutions >= 2 and executions == 0, "resolving candidates must not execute commands")
    for _, item in ipairs(items) do
      if opts.format_item(item):find("messaging", 1, true) then
        callback(item)
        done = true
        return
      end
    end
  end
  reset()
  vim.ui.select = select_action
  vim.lsp.buf.code_action()
  wait_for(function()
    return done and executions == 1
  end)
  local text = table.concat(vim.api.nvim_buf_get_lines(buf, 0, -1, false), "\n")
  assert(text == "import messaging.SqsPublisher\n\n" .. initial, "Kotlin must preserve the pasted expression")
  print("PASS: Kotlin lazy import choices apply only the selected server command without completion insertion")

  reset()
  executions, done = 0, false
  vim.ui.select = function(items, opts, callback)
    if opts.kind == "codeaction" then
      return select_action(items, opts, callback)
    end
    callback(nil)
    done = true
  end
  vim.lsp.buf.code_action()
  wait_for(function()
    return done
  end)
  assert(executions == 0 and vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1] == initial, "cancel must not run commands")
  print("PASS: cancelling Kotlin selection executes no server commands")

  reset()
  done = false
  vim.ui.select = function(items, opts, callback)
    if opts.kind == "codeaction" then
      return select_action(items, opts, callback)
    end
    vim.api.nvim_buf_set_lines(buf, 0, 0, false, { "// concurrent edit" })
    callback(items[1])
    done = true
  end
  vim.lsp.buf.code_action()
  wait_for(function()
    return done
  end)
  assert(executions == 0, "a stale Kotlin import command must not execute")
  assert(vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1] == "// concurrent edit", "concurrent edit must be retained")
  print("PASS: stale Kotlin import selection preserves concurrent edits and runs no commands")
end

local ok, err = xpcall(run, debug.traceback)
if client then
  client:stop(true)
end
if not ok then
  io.stderr:write(err .. "\n")
  vim.cmd("cquit 1")
end
vim.cmd("qa!")
