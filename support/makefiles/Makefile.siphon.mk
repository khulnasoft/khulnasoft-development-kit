khulnasoft_siphon_dir = ${khulnasoft_development_root}/siphon

.PHONY: siphon-setup
ifeq ($(siphon_enabled),true)
siphon-setup: siphon-setup-timed siphon-setup-run
else
siphon-setup:
	@true
endif

.PHONY: siphon-setup-run
siphon-setup-run: siphon/.git siphon-common-setup

siphon/.git:
	$(Q)support/component-git-clone ${git_params} ${siphon_repo} siphon

.PHONY: siphon-common-setup
siphon-common-setup: siphon-tool-install siphon-build

.PHONY: siphon-tool-install
siphon-tool-install:
ifeq ($(tool_version_manager_enabled),true)
	@echo
	@echo "${DIVIDER}"
	@echo "Installing mise tools from ${khulnasoft_siphon_dir}/.tool-versions"
	@echo "${DIVIDER}"
	$(Q)cd ${khulnasoft_siphon_dir} && $(MISE_INSTALL)
else
	@true
endif

.PHONY: siphon-build
siphon-build:
	@echo
	@echo "${DIVIDER}"
	@echo "Building Siphon producer and ClickHouse consumer"
	@echo "${DIVIDER}"
	$(Q)cd ${khulnasoft_siphon_dir}/cmd && go build . && cd ${khulnasoft_siphon_dir}/cmd/clickhouse_consumer && go build .

.PHONY: siphon-update
ifeq ($(siphon_enabled),true)
siphon-update: siphon-update-timed
else
siphon-update:
	@true
endif

.PHONY: siphon-update-run
siphon-update-run: siphon/.git/pull siphon-common-setup

.PHONY: siphon/.git/pull
siphon/.git/pull: siphon/.git
	@echo
	@echo "${DIVIDER}"
	@echo "Updating Siphon"
	@echo "${DIVIDER}"
	$(Q)support/component-git-update siphon siphon main main
