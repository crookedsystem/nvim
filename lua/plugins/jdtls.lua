-- jdtls는 Java 21 이상에서만 기동한다. 그런데 셸의 JAVA_HOME은 프로젝트 사정에
-- 따라 더 낮은 버전(예: 17)을 가리키고 있을 수 있고, 그러면 jdtls가
-- "requires at least Java 21"로 즉시 죽는다.
--
-- LSP 서버가 도는 JVM과 프로젝트가 컴파일되는 JDK는 별개이므로, 전역
-- JAVA_HOME은 건드리지 않고 jdtls에만 21+ JDK를 지정한다.
--
-- 고를 때는 21 이상 중 **가장 낮은** 버전을 쓴다. jdtls의 Gradle import가 이
-- JVM에서 돌기 때문에, 최신 JDK를 고르면 프로젝트의 Gradle wrapper가 그 버전을
-- 아직 지원하지 않아 import가 깨질 수 있다(예: Gradle 8.14 + Java 25).
--
-- 아울러 설치된 JDK 전부를 `java.configuration.runtimes`로 등록한다. 이러면
-- 구버전을 타깃하는 프로젝트를 열어도 jdtls가 알아서 해당 JDK로 분석하므로,
-- 프로젝트마다 JAVA_HOME이나 이 설정을 바꿔줄 필요가 없다.

local MIN_MAJOR = 21

---`java -version` 출력에서 major 버전을 뽑는다.
---@return integer|nil
local function java_major(exe)
  if vim.fn.executable(exe) ~= 1 then
    return nil
  end
  local out = vim.fn.system({ exe, "-version" })
  if vim.v.shell_error ~= 0 then
    return nil
  end
  -- `openjdk version "21.0.8"` / `java version "1.8.0_403"` 양쪽을 처리
  local major = out:match('version "(%d+)')
  if major == "1" then
    major = out:match('version "1%.(%d+)')
  end
  return tonumber(major)
end

---설치된 JDK 후보들을 { major, home } 목록으로 수집한다.
local function installed_jdks()
  local found, seen = {}, {}

  local function add(major, home)
    if major and home and not seen[home] and vim.fn.executable(home .. "/bin/java") == 1 then
      seen[home] = true
      table.insert(found, { major = major, home = home })
    end
  end

  -- macOS: java_home -V가 `  21.0.8 (arm64) "Azul" - "Zulu 21" /path/to/Home` 형태로
  -- stderr에 전부 나열한다. 여기서 바로 major를 읽으면 JDK마다 java를 실행하지 않아도 된다.
  if vim.fn.executable("/usr/libexec/java_home") == 1 then
    local out = vim.fn.system({ "/usr/libexec/java_home", "-V" })
    for line in out:gmatch("[^\n]+") do
      local major, home = line:match("^%s*(%d+)[%d%.]*%s.*%s(/.+)$")
      add(tonumber(major), home)
    end
  end

  -- Linux
  for _, home in ipairs(vim.fn.glob("/usr/lib/jvm/*", false, true)) do
    add(java_major(home .. "/bin/java"), home)
  end

  return found
end

---JAVA_HOME이 이미 21+ 면 nil(=jdtls 기본 동작에 위임), 아니면 21+ 중 가장 낮은 java 경로.
---@return string|nil
local function jdtls_java_executable(jdks)
  local home = vim.env.JAVA_HOME
  if home then
    local major = java_major(home .. "/bin/java")
    if major and major >= MIN_MAJOR then
      return nil
    end
  end

  local best
  for _, jdk in ipairs(jdks) do
    if jdk.major >= MIN_MAJOR and (not best or jdk.major < best.major) then
      best = jdk
    end
  end

  return best and (best.home .. "/bin/java") or nil
end

---설치된 JDK를 jdtls의 execution environment 이름으로 매핑한다.
---프로젝트가 어떤 버전을 타깃하든 jdtls가 맞는 JDK를 찾아 쓸 수 있게 해준다.
local function runtimes(jdks)
  local list = {}
  for _, jdk in ipairs(jdks) do
    -- JavaSE-1.8 / JavaSE-11 / JavaSE-17 ... 형태. JDT가 모르는 이름은 무시된다.
    local name = jdk.major <= 8 and ("JavaSE-1." .. jdk.major) or ("JavaSE-" .. jdk.major)
    table.insert(list, { name = name, path = jdk.home })
  end
  return list
end

return {
  {
    "mfussenegger/nvim-jdtls",
    opts = function(_, opts)
      local jdks = installed_jdks()

      local exe = jdtls_java_executable(jdks)
      if exe then
        table.insert(opts.cmd, "--java-executable=" .. exe)
      end

      opts.settings = vim.tbl_deep_extend("force", opts.settings or {}, {
        java = { configuration = { runtimes = runtimes(jdks) } },
      })
    end,
  },
}
