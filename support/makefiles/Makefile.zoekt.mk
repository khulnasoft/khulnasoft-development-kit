zoekt_dir = ${khulnasoft_development_root}/zoekt

.PHONY: zoekt-setup
ifeq ($(zoekt_enabled),true)
zoekt-setup: zoekt/bin/zoekt-webserver
else
zoekt-setup:
	@true
endif

.PHONY: zoekt-update
ifeq ($(zoekt_enabled),true)
zoekt-update: zoekt-update-timed
else
zoekt-update:
	@true
endif

.PHONY: zoekt-update-run
zoekt-update-run: zoekt/.git/pull zoekt-clean-bin zoekt/bin/zoekt-webserver

zoekt-asdf-install:
ifeq ($(asdf_opt_out),false)
	@echo
	@echo "${DIVIDER}"
	@echo "Installing asdf tools from ${zoekt_dir}/.tool-versions"
	@echo "${DIVIDER}"
	$(Q)cd ${zoekt_dir} && ASDF_DEFAULT_TOOL_VERSIONS_FILENAME="${zoekt_dir}/.tool-versions" asdf install
else ifeq ($(mise_enabled),true)
	@echo
	@echo "${DIVIDER}"
	@echo "Installing mise tools from ${zoekt_dir}/.tool-versions"
	@echo "${DIVIDER}"
	$(Q)cd ${zoekt_dir} && mise install -y
else
	@true
endif

zoekt/.git:
	$(Q)GIT_REVISION="${zoekt_version}" support/component-git-clone ${git_params} ${zoekt_repo} zoekt

zoekt/bin/%: zoekt/.git/pull zoekt-asdf-install
	@echo
	@echo "${DIVIDER}"
	@echo "Building $@ version ${zoekt_version}"
	@echo "${DIVIDER}"
	$(Q)support/asdf-exec zoekt go build -o bin/$(notdir $@) ./cmd/$(notdir $@)/

.PHONY: zoekt-clean-bin
zoekt-clean-bin:
	$(Q)rm -rf zoekt/bin

.PHONY: zoekt/.git/pull
zoekt/.git/pull: zoekt/.git
	@echo
	@echo "${DIVIDER}"
	@echo "Updating zoekt"
	@echo "${DIVIDER}"
	$(Q)support/component-git-update zoekt zoekt "${zoekt_version}" main
