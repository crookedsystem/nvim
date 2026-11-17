// 프로젝트의 컴파일러로 원래 수정안과 같은 모듈로 해석되는 경로만 제안한다.
const fs = require("node:fs");
const path = require("node:path");

function run(input) {
  const search = [path.dirname(input.file)];
  if (input.server) search.push(path.dirname(fs.realpathSync(input.server)));
  const ts = require(require.resolve("typescript", { paths: search }));
  let configFile;
  let dir = path.dirname(input.file);
  while (!configFile) {
    configFile = ["tsconfig.json", "jsconfig.json"]
      .map((name) => path.join(dir, name)).find(ts.sys.fileExists);
    const parent = path.dirname(dir);
    if (parent === dir) break;
    dir = parent;
  }
  let options = { moduleResolution: ts.ModuleResolutionKind.Node10 };
  if (configFile) {
    const config = ts.readConfigFile(configFile, ts.sys.readFile);
    if (config.error) throw new Error("Cannot read " + configFile);
    const configHost = { ...ts.sys, readDirectory: () => [] };
    options = ts.parseJsonConfigFileContent(config.config, configHost, path.dirname(configFile)).options;
  }
  const slash = (value) => value.split(path.sep).join("/");
  const canonical = (file) => {
    const real = ts.sys.realpath ? ts.sys.realpath(file) : file;
    return ts.sys.useCaseSensitiveFileNames ? real : real.toLowerCase();
  };
  const strip = (file) => file.replace(/(?:\.d)?\.(?:tsx?|mts|cts|jsx?|mjs|cjs)$/, "");
  const output = [];
  const seen = new Set();
  input.actions.forEach((action, index) => {
    const edits = action.edit;
    const locations = [];
    const inspect = (edit) => {
      const source = ts.createSourceFile(input.file, edit.newText, ts.ScriptTarget.Latest, true);
      source.impliedNodeFormat = ts.getImpliedNodeFormatForFile(input.file, undefined, ts.sys, options);
      const visit = (node) => {
        let literal;
        if (ts.isImportDeclaration(node)) literal = node.moduleSpecifier;
        if (ts.isCallExpression(node) && node.expression.getText(source) === "require") literal = node.arguments[0];
        if (ts.isImportEqualsDeclaration(node) && ts.isExternalModuleReference(node.moduleReference)) {
          literal = node.moduleReference.expression;
        }
        if (literal && ts.isStringLiteralLike(literal)) {
          locations.push({
            edit, module: literal.text, start: literal.getStart(source) + 1, end: literal.end - 1,
            mode: ts.getModeForUsageLocation(source, literal, options),
          });
        }
        ts.forEachChild(node, visit);
      };
      visit(source);
    };
    for (const edit of edits?.changes?.[input.uri] || []) inspect(edit);
    for (const change of edits?.documentChanges || []) {
      if (change.textDocument?.uri === input.uri) change.edits.forEach(inspect);
    }
    const location = locations.length === 1 ? locations[0] : undefined;
    const add = (module) => {
      const key = module || JSON.stringify(edits);
      if (seen.has(key)) return;
      seen.add(key);
      let replacement = edits;
      if (location && module !== location.module) {
        replacement = JSON.parse(JSON.stringify(edits));
        const oldText = location.edit.newText;
        const quote = oldText[location.start - 1];
        const escaped = module.replace(/\\/g, "\\\\").replaceAll(quote, "\\" + quote);
        const newText = oldText.slice(0, location.start) + escaped + oldText.slice(location.end);
        const replace = (edit) => { if (edit.newText === oldText) edit.newText = newText; };
        (replacement.changes?.[input.uri] || []).forEach(replace);
        for (const change of replacement.documentChanges || []) {
          if (change.textDocument?.uri === input.uri) change.edits.forEach(replace);
        }
      }
      output.push({ index: index + 1, label: module || action.title, edit: replacement });
    };
    add(location?.module);
    if (!location) return;
    const resolve = (module) => ts.resolveModuleName(
      module, input.file, options, ts.sys, undefined, undefined, location.mode,
    ).resolvedModule;
    const target = resolve(location.module);
    if (!target || target.packageId || slash(target.resolvedFileName).includes("/node_modules/")) return;
    const alternatives = new Set();
    const full = slash(target.resolvedFileName);
    const bare = strip(full);
    const targets = [...new Set([bare.replace(/\/index$/, ""), bare, full])];
    const runtimeEnding = /\.(?:js|mjs|cjs)$/.test(location.module);
    for (const candidate of targets) {
      let relative = slash(path.relative(path.dirname(input.file), candidate));
      if (!relative.startsWith(".")) relative = "./" + relative;
      if (runtimeEnding && candidate === bare) {
        relative += full.endsWith(".mts") ? ".mjs" : full.endsWith(".cts") ? ".cjs" : ".js";
      }
      // 컴파일러 수정안이 생략한 .ts 확장자를 경로 후보에 덧붙이지 않는다.
      if (candidate !== full || location.module.endsWith(path.extname(full))) alternatives.add(relative);
      if (options.baseUrl && candidate !== full) {
        const base = slash(path.relative(options.baseUrl, candidate));
        if (base && base !== ".." && !base.startsWith("../")) alternatives.add(base);
      }
      const pathsRoot = options.baseUrl || options.pathsBasePath || (configFile && path.dirname(configFile));
      for (const [alias, patterns] of Object.entries(options.paths || {})) {
        for (const pattern of patterns) {
          const absolute = slash(path.resolve(pathsRoot, pattern));
          const star = absolute.indexOf("*");
          if (star === -1) {
            if (absolute === candidate) alternatives.add(alias);
          } else {
            const prefix = absolute.slice(0, star);
            const suffix = absolute.slice(star + 1);
            if (candidate.startsWith(prefix) && candidate.endsWith(suffix)) {
              const middle = candidate.slice(prefix.length, candidate.length - suffix.length || undefined);
              alternatives.add(alias.replace("*", middle));
            }
          }
        }
      }
    }
    for (const module of alternatives) {
      const result = resolve(module);
      if (result && canonical(result.resolvedFileName) === canonical(target.resolvedFileName)) add(module);
    }
  });
  return output;
}

let stdin = "";
process.stdin.setEncoding("utf8");
process.stdin.on("data", (chunk) => { stdin += chunk; });
process.stdin.on("end", () => {
  try {
    process.stdout.write(JSON.stringify(run(JSON.parse(stdin))));
  } catch (error) {
    process.stderr.write(error.message + "\n");
    process.exitCode = 1;
  }
});
