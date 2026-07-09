OS := $(shell uname)

.PHONY: install
install:
ifeq ($(OS),Darwin)
	@bash mac-install.sh
else
	@bash ubuntu-install.sh
endif
