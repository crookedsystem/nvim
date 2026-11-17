vim.opt.runtimepath:prepend(vim.env.NVIM_IMPORT_REPO)

local client
local function run()
  dofile(vim.env.NVIM_IMPORT_REPO .. "/lua/config/autocmds.lua")
  local language = vim.env.NVIM_IMPORT_LANGUAGE
  local fixture = vim.uv.fs_realpath(vim.env.NVIM_IMPORT_FIXTURE)
  local root = fixture .. "/" .. language
  local file = ({ python = "/main.py", java = "/src/Main.java", kotlin = "/src/Main.kt" })[language]
  vim.cmd.edit(root .. file)
  vim.bo.filetype = language
  local buf = vim.api.nvim_get_current_buf()
  local initial = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  local mason = vim.fn.stdpath("data") .. "/mason/bin/"
  local config = {
    name = ({ python = "basedpyright", java = "jdtls", kotlin = "kotlin_lsp" })[language],
    root_dir = root,
    capabilities = vim.lsp.protocol.make_client_capabilities(),
  }
  if language == "python" then
    config.cmd = { mason .. "basedpyright-langserver", "--stdio" }
    config.settings = { basedpyright = { analysis = { autoImportCompletions = true } } }
  elseif language == "java" then
    local opts = { cmd = { mason .. "jdtls" } }
    dofile(vim.env.NVIM_IMPORT_REPO .. "/lua/plugins/jdtls.lua")[1].opts(nil, opts)
    config.cmd = opts.cmd
    vim.list_extend(config.cmd, { "-data", fixture .. "/java-workspace" })
    config.settings = {
      java = {
        import = { gradle = { enabled = false }, maven = { enabled = false } },
        configuration = opts.settings.java.configuration,
      },
    }
  else
    config.cmd = { mason .. "intellij-server", "--stdio", "--system-path=" .. fixture .. "/kotlin-cache" }
    local opts = { cmd = {} }
    dofile(vim.env.NVIM_IMPORT_REPO .. "/lua/plugins/jdtls.lua")[1].opts(nil, opts)
    local runtime = assert(opts.settings.java.configuration.runtimes[1], "Kotlin fixture needs a JDK")
    config.init_options = { defaultSdk = runtime.path, buildTools = { [vim.uri_from_fname(root)] = "jps" } }
  end
  client = assert(vim.lsp.get_client_by_id(assert(vim.lsp.start(config))))
  local function wait_for(predicate, description)
    assert(vim.wait(45000, predicate, 30), language .. ": " .. description)
  end
  local function ready()
    return vim.iter(vim.diagnostic.get(buf)):any(function(d)
      return d.message:find("SqsPublisher", 1, true) ~= nil
    end)
  end
  wait_for(ready, "missing unresolved-symbol diagnostic")
  local function reset()
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, initial)
    local col = initial[1]:find("SqsPublisher", 1, true) - 1
    vim.api.nvim_win_set_cursor(0, { 1, col + 3 })
    wait_for(ready, "missing diagnostic after resetting pasted code")
  end
  local function text()
    return table.concat(vim.api.nvim_buf_get_lines(buf, 0, -1, false), "\n")
  end
  local done, labels
  vim.ui.select = function(items, opts, callback)
    if opts.kind == "codeaction" then
      for _, item in ipairs(items) do
        if item.action.title == "Choose import for SqsPublisher" then
          return callback(item)
        end
      end
      error("ca must offer an import selector: " .. vim.inspect(items))
    end
    assert(opts.kind == "lsp_import", "unexpected selection kind")
    labels = vim.tbl_map(opts.format_item, items)
    for index, label in ipairs(labels) do
      if label:find("messaging", 1, true) then
        callback(items[index])
        done = true
        return
      end
    end
    error("messaging candidate missing: " .. vim.inspect(labels))
  end
  reset()
  -- Python Code Action에 import가 없어도 실제 자동완성의 두 모듈을 선택한다.
  local rpc_request = client.rpc.request
  if language == "python" then
    client.rpc.request = function(method, params, callback, ...)
      if method == "textDocument/codeAction" then
        local handler = callback
        callback = function(err, result)
          handler(
            err,
            vim.tbl_filter(function(action)
              return not action.title:match("^from .- import ")
            end, result or {})
          )
        end
      end
      return rpc_request(method, params, callback, ...)
    end
  end
  vim.lsp.buf.code_action()
  local expected = ({
    python = "from messaging.sqs_publisher import SqsPublisher",
    java = "import messaging.SqsPublisher;",
    kotlin = "import messaging.SqsPublisher",
  })[language]
  wait_for(function()
    return done and text():find(expected, 1, true) ~= nil
  end, "selected import did not apply")
  client.rpc.request = rpc_request
  assert(
    vim.iter(labels):any(function(label)
      return label:find("legacy", 1, true) ~= nil
    end),
    "same-name legacy implementation must also be offered"
  )
  assert(text():find(initial[1], 1, true), "pasted expression must be preserved")
  assert(text():find(expected, 1, true), "selected module import missing: " .. text())
  assert(not text():find("import legacy", 1, true), "unselected import must not be applied")
  print("PASS: " .. language .. " ca chooses between same-name modules and preserves pasted code")

  reset()
  done = false
  local select = vim.ui.select
  vim.ui.select = function(items, opts, callback)
    if opts.kind == "codeaction" then
      return select(items, opts, callback)
    end
    callback(nil)
    done = true
  end
  vim.lsp.buf.code_action()
  wait_for(function()
    return done
  end, "cancel did not finish")
  assert(text() == table.concat(initial, "\n"), "cancel must leave buffer unchanged")
  print("PASS: " .. language .. " cancelling import selection makes no edits")
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
