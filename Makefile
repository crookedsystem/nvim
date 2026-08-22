OS := $(shell uname)

.PHONY: install
install: deps mason

# 시스템 의존성 (ripgrep, node, JDK 21+, uv 등)
.PHONY: deps
deps:
ifeq ($(OS),Darwin)
	@bash mac-install.sh
else
	@bash ubuntu-install.sh
endif

# Mason 레지스트리 갱신 + 만료되는 서버 재설치
# kotlin-lsp(JetBrains intellij-server)는 빌드에 만료일이 있어
# 만료되면 exit code 7로 죽는다. ensure_installed는 "설치돼 있으면 통과"라
# 갱신되지 않으므로 여기서 명시적으로 다시 받는다.
.PHONY: mason
mason:
	@echo "=== Updating Mason registry & kotlin-lsp ==="
	@nvim --headless "+MasonUpdate" "+MasonInstall kotlin-lsp --quiet" +qa
	@echo "=== Done ==="
