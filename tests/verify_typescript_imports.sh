#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
fixture_root="$(mktemp -d)"
trap 'rm -rf "$fixture_root"' EXIT

mkdir -p "$fixture_root/config" "$fixture_root/src/messaging" "$fixture_root/src/legacy" "$fixture_root/src/reward"
cat > "$fixture_root/config/tsconfig.base.json" <<'JSON'
{
  "compilerOptions": {
    "target": "ES2022",
    "module": "commonjs",
    "moduleResolution": "node",
    "baseUrl": "..",
    "paths": { "@messaging/*": ["src/messaging/*"], "@broken/*": ["absent/*"] }
  }
}
JSON
cat > "$fixture_root/tsconfig.json" <<'JSON'
{ "extends": "./config/tsconfig.base.json", "include": ["src/**/*.ts"] }
JSON
printf 'export class SqsPublisher { send() {} }\n' > "$fixture_root/src/messaging/sqs-publisher.ts"
printf 'export class SqsPublisher { send() {} }\n' > "$fixture_root/src/legacy/sqs-publisher.ts"
printf 'export class Existing {}\n' > "$fixture_root/src/messaging/existing.ts"
cat > "$fixture_root/src/reward/redriver.ts" <<'TS'
import { Existing } from "../messaging/existing";
const label = "한글😀"; const publisher = new SqsPublisher();
TS

mkdir -p "$fixture_root/esm/src" "$fixture_root/node_modules/tiny-publisher"
printf '{"type":"module"}\n' > "$fixture_root/esm/package.json"
printf '{"compilerOptions":{"module":"NodeNext","moduleResolution":"NodeNext"}}\n' > "$fixture_root/esm/tsconfig.json"
printf 'export class SqsPublisher {}\n' > "$fixture_root/esm/src/publisher.ts"
printf 'export {};\n' > "$fixture_root/esm/src/main.ts"
printf '{"name":"tiny-publisher","types":"index.d.ts"}\n' > "$fixture_root/node_modules/tiny-publisher/package.json"
printf 'export declare class Publisher {}\n' > "$fixture_root/node_modules/tiny-publisher/index.d.ts"

NVIM_IMPORT_REPO="$repo_root" NVIM_IMPORT_FIXTURE="$fixture_root" \
  nvim --headless -u NONE -l "$repo_root/tests/verify_typescript_imports.lua"
