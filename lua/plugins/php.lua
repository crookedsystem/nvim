-- composer.json에서 PHP 버전을 찾지 못한 프로젝트가 쓰는 기본 버전
local DEFAULT_PHP_VERSION = "7.4.0"

-- "7.4", ">=7.2", "^8.1.2 || ^9" 같은 버전 문자열에서 처음 나오는 버전을 x.y.z 형식으로 맞춘다
local function normalize_php_version(version_text)
  local major, minor, patch = version_text:match("(%d+)%.?(%d*)%.?(%d*)")
  if not major then
    return nil
  end
  return string.format("%s.%s.%s", major, minor ~= "" and minor or "0", patch ~= "" and patch or "0")
end

-- 정확한 실행 버전인 config.platform.php를 먼저 보고, 없으면 require.php 제약의 하한을 쓴다
local function read_declared_php_version(composer_path)
  if vim.fn.filereadable(composer_path) == 0 then
    return nil
  end

  local is_decoded, composer = pcall(vim.json.decode, table.concat(vim.fn.readfile(composer_path), "\n"))
  if not is_decoded or type(composer) ~= "table" then
    return nil
  end

  local platform_php = vim.tbl_get(composer, "config", "platform", "php")
  local required_php = vim.tbl_get(composer, "require", "php")
  local declared_version = type(platform_php) == "string" and platform_php or required_php
  return type(declared_version) == "string" and normalize_php_version(declared_version) or nil
end

-- 바로 아래 하위 폴더들의 composer.json 중 가장 낮은 버전을 고른다.
-- 워크스페이스에는 버전 하나만 적용되므로, 낮은 버전 앱의 호환성 오류를 놓치지 않는 쪽을 택한다
local function find_lowest_subdirectory_php_version(root_dir)
  local lowest_version = nil
  for name, type in vim.fs.dir(root_dir) do
    local subdirectory_version = type == "directory"
      and read_declared_php_version(vim.fs.joinpath(root_dir, name, "composer.json"))
    if subdirectory_version and (not lowest_version or vim.version.lt(subdirectory_version, lowest_version)) then
      lowest_version = subdirectory_version
    end
  end
  return lowest_version
end

-- 루트의 composer.json이 있으면 그것만 따르고, 없을 때만 하위 폴더를 본다
local function detect_php_version(root_dir)
  if not root_dir then
    return DEFAULT_PHP_VERSION
  end

  local root_composer_path = vim.fs.joinpath(root_dir, "composer.json")
  if vim.fn.filereadable(root_composer_path) == 1 then
    return read_declared_php_version(root_composer_path) or DEFAULT_PHP_VERSION
  end
  return find_lowest_subdirectory_php_version(root_dir) or DEFAULT_PHP_VERSION
end

return {
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, { "php" })
    end,
  },
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        intelephense = {
          settings = {
            intelephense = {
              -- LazyVim은 conform 포매터가 없으면 LSP 포맷으로 대신하므로, 레거시 파일이 저장 때마다 재포맷되지 않게 끈다
              format = { enable = false },
            },
          },
          -- 클라이언트가 같은 settings 테이블을 서버에 보내므로 새 테이블을 대입하지 않고 제자리에서 고친다
          before_init = function(_, config)
            local intelephense_settings = config.settings.intelephense
            intelephense_settings.environment = intelephense_settings.environment or {}
            intelephense_settings.environment.phpVersion = detect_php_version(config.root_dir)
          end,
        },
      },
    },
  },
}
