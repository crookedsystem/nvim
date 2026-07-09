local kotlin_root_markers = {
  "settings.gradle",
  "settings.gradle.kts",
  "pom.xml",
  "build.gradle",
  "build.gradle.kts",
  "workspace.json",
}

local function read_file(path)
  if not vim.uv.fs_stat(path) then
    return nil
  end

  local lines = vim.fn.readfile(path)
  return #lines > 0 and table.concat(lines, "\n") or nil
end

local function java_major(java_home)
  if not java_home or vim.fn.executable(java_home .. "/bin/java") ~= 1 then
    return nil
  end

  local version = vim.fn.system({ java_home .. "/bin/java", "-version" })
  local major = version:match('version "1%.(%d+)') or version:match('version "(%d+)')
  return major and tonumber(major) or nil
end

local function java_home_for_major(major)
  if vim.fn.executable("/usr/libexec/java_home") == 1 then
    local home = vim.fn.system({ "/usr/libexec/java_home", "-v", tostring(major) }):gsub("%s+$", "")
    if vim.v.shell_error == 0 and home ~= "" and java_major(home) == major then
      return home
    end
  end

  for _, pattern in ipairs({
    "/usr/lib/jvm/java-" .. major .. "-openjdk-*",
    "/usr/lib/jvm/java-" .. major .. "-openjdk",
    "/usr/lib/jvm/jdk-" .. major .. "*",
  }) do
    local homes = vim.fn.glob(pattern, false, true)
    for _, home in ipairs(homes) do
      if java_major(home) == major then
        return home
      end
    end
  end
end

local function project_java_major(root_dir)
  if not root_dir then
    return nil
  end

  local gradle_properties = read_file(root_dir .. "/gradle.properties")
  local gradle_java_home = gradle_properties and gradle_properties:match("org%.gradle%.java%.home%s*=%s*([^\n]+)")
  if gradle_java_home and java_major(gradle_java_home) then
    return java_major(gradle_java_home), gradle_java_home
  end

  local java_version = read_file(root_dir .. "/.java-version")
  local major = java_version and java_version:match("(%d+)")
  if major then
    return tonumber(major)
  end

  local sdkmanrc = read_file(root_dir .. "/.sdkmanrc")
  major = sdkmanrc and sdkmanrc:match("java%s*=%s*[^%d]*(%d+)")
  if major then
    return tonumber(major)
  end

  local tool_versions = read_file(root_dir .. "/.tool-versions")
  major = tool_versions and tool_versions:match("java%s+[^%d]*(%d+)")
  return major and tonumber(major) or nil
end

local function kotlin_java_home(root_dir)
  local major, explicit_home = project_java_major(root_dir)
  if explicit_home then
    return explicit_home
  end
  if major then
    local home = java_home_for_major(major)
    if home then
      return home
    end
  end

  local current_major = java_major(vim.env.JAVA_HOME)
  if current_major == 21 or current_major == 17 then
    return vim.env.JAVA_HOME
  end

  for _, fallback_major in ipairs({ 21, 17 }) do
    local home = java_home_for_major(fallback_major)
    if home then
      return home
    end
  end
end

local function kotlin_cmd()
  if vim.fn.executable("kotlin-lsp") == 1 then
    return { "kotlin-lsp", "--stdio" }
  end
  if vim.fn.executable("intellij-server") == 1 then
    return { "intellij-server", "--stdio" }
  end

  local servers =
    vim.fn.glob(vim.fn.stdpath("data") .. "/mason/packages/kotlin-lsp/**/bin/intellij-server", false, true)
  if #servers > 0 then
    return { servers[1], "--stdio" }
  end

  return { "kotlin-lsp", "--stdio" }
end

local function kotlin_cmd_env(root_dir)
  local mason_bin = vim.fn.stdpath("data") .. "/mason/bin"
  local path = vim.env.PATH or ""

  local env = {
    PATH = path:find(mason_bin, 1, true) and path or (mason_bin .. ":" .. path),
  }

  local java_home = kotlin_java_home(root_dir)
  if java_home then
    env.JAVA_HOME = java_home
  end

  return env
end

local function start_kotlin_buffer(bufnr)
  if not vim.api.nvim_buf_is_loaded(bufnr) or vim.bo[bufnr].filetype ~= "kotlin" then
    return
  end

  if #vim.lsp.get_clients({ bufnr = bufnr, name = "kotlin_lsp" }) > 0 then
    return
  end

  local root_dir = vim.fs.root(bufnr, kotlin_root_markers)
  if not root_dir then
    return
  end

  local config = vim.deepcopy(vim.lsp.config.kotlin_lsp)
  config.root_dir = root_dir
  config.cmd_env = kotlin_cmd_env(root_dir)
  vim.lsp.start(config, { bufnr = bufnr })
end

return {
  {
    "mason-org/mason.nvim",
    opts = {
      ensure_installed = { "kotlin-lsp" },
    },
  },
  {
    "neovim/nvim-lspconfig",
    opts = function(_, opts)
      opts.servers = opts.servers or {}
      opts.servers.kotlin_language_server = { enabled = false }
      opts.servers.kotlin_lsp = vim.tbl_deep_extend("force", opts.servers.kotlin_lsp or {}, {
        enabled = true,
        cmd = kotlin_cmd(),
        cmd_env = kotlin_cmd_env(),
        filetypes = { "kotlin" },
        root_markers = kotlin_root_markers,
      })

      opts.setup = opts.setup or {}
      local previous_setup = opts.setup.kotlin_lsp
      opts.setup.kotlin_lsp = function(server, server_opts)
        if previous_setup and previous_setup(server, server_opts) then
          return true
        end

        vim.lsp.config(server, server_opts)

        local group = vim.api.nvim_create_augroup("config_kotlin_lsp", { clear = true })
        vim.api.nvim_create_autocmd("FileType", {
          group = group,
          pattern = "kotlin",
          callback = function(args)
            vim.schedule(function()
              start_kotlin_buffer(args.buf)
            end)
          end,
        })

        vim.schedule(function()
          for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
            start_kotlin_buffer(bufnr)
          end
        end)

        return true
      end
    end,
  },
  {
    "AlexandrosAlexiou/kotlin.nvim",
    enabled = false,
    ft = { "kotlin" },
    dependencies = {
      "mason-org/mason.nvim",
      "mason-org/mason-lspconfig.nvim",
    },
    config = function()
      require("kotlin").setup({})
    end,
  },
}
