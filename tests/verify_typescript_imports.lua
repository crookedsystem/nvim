vim.opt.runtimepath:prepend(vim.env.NVIM_IMPORT_REPO)
dofile(vim.env.NVIM_IMPORT_REPO .. "/lua/config/autocmds.lua")

local function run()
  require("config.typescript_imports")
  local root = vim.env.NVIM_IMPORT_FIXTURE
  local file = root .. "/src/reward/redriver.ts"
  vim.cmd.edit(file)
  vim.bo.filetype = "typescript"
  local buf = vim.api.nvim_get_current_buf()
  local initial = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  local typescript_specs = dofile(vim.env.NVIM_IMPORT_REPO .. "/lua/plugins/typescript.lua")
  local server = typescript_specs[1].opts.servers.vtsls
  assert(server.keys == nil, "vtsls keys table must not replace LazyVim vtsls keys")
  local lsp_opts = { servers = { vtsls = { keys = { { "<leader>cM" } } } } }
  typescript_specs[2].opts(nil, lsp_opts)
  local vtsls_keys = lsp_opts.servers.vtsls.keys
  assert(vtsls_keys[1][1] == "<leader>cM", "LazyVim vtsls keys must be kept")
  local code_action
  for _, key in ipairs(vtsls_keys) do
    assert(key[1] ~= "<leader>ci", "ci must not be mapped")
    if key[1] == "<leader>ca" then
      code_action = key[2]
    end
  end
  assert(type(code_action) == "function", "existing ca must open the picker")
  local id = assert(vim.lsp.start({
    name = "vtsls",
    cmd = { vim.fn.stdpath("data") .. "/mason/bin/vtsls", "--stdio" },
    root_dir = root,
    settings = server.settings,
  }))
  local client = assert(vim.lsp.get_client_by_id(id))
  local function wait_for(predicate, message)
    assert(vim.wait(15000, predicate, 20), message)
  end
  local function diagnostics_ready()
    for _, diagnostic in ipairs(vim.diagnostic.get(buf)) do
      if tonumber(diagnostic.code) == 2552 or tonumber(diagnostic.code) == 2304 then
        return true
      end
    end
    return false
  end
  wait_for(diagnostics_ready, "vtsls did not report the unresolved publisher")

  local function reset()
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, initial)
    vim.api.nvim_win_set_cursor(0, { 2, #initial[2] - 4 })
    wait_for(diagnostics_ready, "unresolved diagnostic missing after reset")
  end
  local function text()
    return table.concat(vim.api.nvim_buf_get_lines(buf, 0, -1, false), "\n")
  end

  local done, choices, native_menus, import_menus
  local select_import = function(items, opts, callback)
    if opts.kind == "codeaction" then
      native_menus = native_menus + 1
      for _, item in ipairs(items) do
        if item.action.title:find("Add import from", 1, true) then
          callback(item)
          return
        end
      end
      error("ca did not offer an import action")
    end
    assert(opts.kind == "typescript_import", "unexpected picker: " .. vim.inspect(opts))
    import_menus = import_menus + 1
    choices = vim.tbl_map(opts.format_item, items)
    for index, label in ipairs(choices) do
      if label == "@messaging/sqs-publisher" then
        callback(items[index])
        done = true
        return
      end
    end
    error("expected inherited tsconfig alias in choices: " .. vim.inspect(choices))
  end

  reset()
  native_menus, import_menus = 0, 0
  -- ca 응답이 import 하나뿐인 경우에도 실제 completion으로 다른 구현체를 찾는다.
  local request = client.request
  client.request = function(self, method, params, handler, bufnr)
    if method ~= "textDocument/codeAction" then
      return request(self, method, params, handler, bufnr)
    end
    return request(self, method, params, function(err, result, ctx, config)
      local seen_import = false
      local filtered = vim.tbl_filter(function(action)
        if not action.title:find("Add import from", 1, true) then
          return true
        end
        if seen_import then
          return false
        end
        seen_import = true
        return true
      end, result or {})
      handler(err, filtered, ctx, config)
    end, bufnr)
  end
  vim.ui.select = select_import
  code_action()
  wait_for(function()
    return done
  end, "import picker did not finish")
  client.request = request
  for _, expected in ipairs({
    "../messaging/sqs-publisher",
    "../legacy/sqs-publisher",
    "src/messaging/sqs-publisher",
    "src/legacy/sqs-publisher",
    "@messaging/sqs-publisher",
  }) do
    assert(vim.tbl_contains(choices, expected), "missing candidate " .. expected .. ": " .. vim.inspect(choices))
  end
  assert(native_menus == 1 and import_menus == 1, "expected ca followed by one import selection")
  assert(text():find('from "@messaging/sqs-publisher"', 1, true), "selected alias import missing")
  assert(text():find(initial[1], 1, true), "existing import changed")
  assert(text():find(initial[2], 1, true), "pasted identifier or Unicode text changed")
  print("PASS: one ca import expands to both implementations and validated relative/baseUrl/paths imports")

  reset()
  done = false
  vim.ui.select = function(items, opts, callback)
    if opts.kind == "codeaction" then
      return select_import(items, opts, callback)
    end
    callback(nil)
    done = true
  end
  code_action()
  wait_for(function()
    return done
  end, "cancelled picker did not finish")
  assert(text() == table.concat(initial, "\n"), "cancel must not edit buffer")
  print("PASS: cancelling import selection leaves pasted code unchanged")

  reset()
  done = false
  local notified = false
  local notify = vim.notify
  vim.notify = function(message, ...)
    notified = notified or message:find("changed", 1, true) ~= nil
    return notify(message, ...)
  end
  vim.ui.select = function(items, opts, callback)
    if opts.kind == "codeaction" then
      return select_import(items, opts, callback)
    end
    vim.api.nvim_buf_set_lines(buf, 0, 0, false, { "// concurrent edit" })
    callback(items[1])
    done = true
  end
  code_action()
  wait_for(function()
    return done
  end, "stale selection did not finish")
  assert(notified and not text():find("import { SqsPublisher", 1, true), "stale import must not apply")
  print("PASS: editing while picker is open prevents stale edits")
  vim.notify = notify

  reset()
  done = false
  vim.ui.select = function(items, opts, callback)
    assert(opts.kind == "codeaction", "ordinary fixes must use the native code action menu")
    for _, item in ipairs(items) do
      if item.action.title:find("Change spelling", 1, true) then
        callback(item)
        done = true
        return
      end
    end
    error("spelling fix missing")
  end
  code_action()
  wait_for(function()
    return done
  end, "ordinary code action did not finish")
  assert(text():find("new publisher()", 1, true), "native non-import action was not applied")
  print("PASS: non-import code actions retain native application")

  local function path_choices(filename, import)
    local uri = vim.uri_from_fname(filename)
    local response = vim
      .system({ "node", vim.env.NVIM_IMPORT_REPO .. "/scripts/typescript-import-paths.cjs" }, {
        stdin = vim.json.encode({
          file = filename,
          uri = uri,
          server = client.config.cmd[1],
          actions = {
            {
              title = "Import",
              edit = {
                changes = {
                  [uri] = {
                    {
                      range = { start = { line = 0, character = 0 }, ["end"] = { line = 0, character = 0 } },
                      newText = import,
                    },
                  },
                },
              },
            },
          },
        }),
        text = true,
      })
      :wait()
    assert(response.code == 0, response.stderr)
    return vim.json.decode(response.stdout)
  end
  local esm = path_choices(root .. "/esm/src/main.ts", "import type { SqsPublisher } from './publisher.js';\n")
  assert(#esm == 1 and esm[1].label == "./publisher.js", "NodeNext must not offer extensionless imports")
  local edits = esm[1].edit.changes[vim.uri_from_fname(root .. "/esm/src/main.ts")]
  assert(edits[1].newText:find("import type", 1, true), "type-only import must be preserved")
  local external = path_choices(file, 'import { Publisher } from "tiny-publisher";\n')
  assert(#external == 1 and external[1].label == "tiny-publisher", "must not offer node_modules relative paths")
  print("PASS: NodeNext .js/type imports and external package boundaries are preserved")
  client:stop(true)
end

local ok, err = xpcall(run, debug.traceback)
if not ok then
  io.stderr:write(err .. "\n")
  vim.cmd("cquit 1")
end
vim.cmd("qa!")
