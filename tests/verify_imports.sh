#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
fixture_root="$(mktemp -d)"
trap 'rm -rf "$fixture_root"' EXIT

mkdir -p "$fixture_root/python/messaging" "$fixture_root/python/legacy"
for module in messaging legacy; do
  printf 'class SqsPublisher:\n    pass\n' > "$fixture_root/python/$module/sqs_publisher.py"
  touch "$fixture_root/python/$module/__init__.py"
done
printf 'publisher = SqsPublisher()\n' > "$fixture_root/python/main.py"
printf '{"include":["."],"typeCheckingMode":"basic"}\n' > "$fixture_root/python/pyrightconfig.json"

mkdir -p "$fixture_root/java/src/messaging" "$fixture_root/java/src/legacy"
for module in messaging legacy; do
  printf 'package %s; public class SqsPublisher {}\n' "$module" > "$fixture_root/java/src/$module/SqsPublisher.java"
done
printf 'public class Main { SqsPublisher publisher; }\n' > "$fixture_root/java/src/Main.java"
cat > "$fixture_root/java/.project" <<'XML'
<projectDescription><name>ImportFixture</name><buildSpec><buildCommand><name>org.eclipse.jdt.core.javabuilder</name></buildCommand></buildSpec><natures><nature>org.eclipse.jdt.core.javanature</nature></natures></projectDescription>
XML
cat > "$fixture_root/java/.classpath" <<'XML'
<classpath><classpathentry kind="src" path="src"/><classpathentry kind="con" path="org.eclipse.jdt.launching.JRE_CONTAINER"/><classpathentry kind="output" path="bin"/></classpath>
XML

mkdir -p "$fixture_root/kotlin/src/messaging" "$fixture_root/kotlin/src/legacy" "$fixture_root/kotlin/.idea"
for module in messaging legacy; do
  printf 'package %s\nclass SqsPublisher\n' "$module" > "$fixture_root/kotlin/src/$module/SqsPublisher.kt"
done
printf 'val publisher: SqsPublisher? = null\n' > "$fixture_root/kotlin/src/Main.kt"
cat > "$fixture_root/kotlin/.idea/modules.xml" <<'XML'
<project version="4"><component name="ProjectModuleManager"><modules><module fileurl="file://$PROJECT_DIR$/fixture.iml" filepath="$PROJECT_DIR$/fixture.iml"/></modules></component></project>
XML
cat > "$fixture_root/kotlin/.idea/misc.xml" <<'XML'
<project version="4"><component name="ProjectRootManager" version="2" languageLevel="JDK_21" project-jdk-name="21" project-jdk-type="JavaSDK"/></project>
XML
cat > "$fixture_root/kotlin/fixture.iml" <<'XML'
<module type="JAVA_MODULE" version="4"><component name="NewModuleRootManager" inherit-compiler-output="true"><exclude-output/><content url="file://$MODULE_DIR$"><sourceFolder url="file://$MODULE_DIR$/src" isTestSource="false"/></content><orderEntry type="inheritedJdk"/><orderEntry type="sourceFolder" forTests="false"/></component><component name="FacetManager"><facet type="kotlin-language" name="Kotlin"><configuration version="5" platform="JVM 21" useProjectSettings="false"><compilerSettings/><compilerArguments><option name="jvmTarget" value="21"/></compilerArguments></configuration></facet></component></module>
XML

for language in python java kotlin; do
  NVIM_IMPORT_REPO="$repo_root" NVIM_IMPORT_FIXTURE="$fixture_root" NVIM_IMPORT_LANGUAGE="$language" \
    nvim --headless -u NONE -l "$repo_root/tests/verify_imports.lua"
done

printf 'val publisher: SqsPublisher? = null\n' > "$fixture_root/Main.kt"
NVIM_IMPORT_REPO="$repo_root" NVIM_IMPORT_FIXTURE="$fixture_root" \
  nvim --headless -u NONE -l "$repo_root/tests/verify_kotlin_imports.lua"
