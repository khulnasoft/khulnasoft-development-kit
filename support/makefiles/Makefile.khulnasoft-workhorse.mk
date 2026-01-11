workhorse_dir = ${khulnasoft_development_root}/khulnasoft/workhorse

.PHONY: khulnasoft-workhorse-setup
khulnasoft-workhorse-setup:
ifeq ($(workhorse_skip_setup),true)
	@echo
	@echo "${DIVIDER}"
	@echo "Skipping khulnasoft-workhorse setup due to workhorse.skip_setup set to true"
	@echo "${DIVIDER}"
else
	$(Q)$(MAKE) khulnasoft-workhorse-tool-install khulnasoft/workhorse/khulnasoft-workhorse khulnasoft/workhorse/config.toml
endif

.PHONY: khulnasoft-workhorse-update
khulnasoft-workhorse-update: khulnasoft-workhorse-update-timed

.PHONY: khulnasoft-workhorse-update-run
khulnasoft-workhorse-update-run: khulnasoft-workhorse-setup

.PHONY: khulnasoft-workhorse-tool-install
khulnasoft-workhorse-tool-install:
ifeq ($(tool_version_manager_enabled),true)
	@echo
	@echo "${DIVIDER}"
	@echo "Installing tools from ${workhorse_dir}/.tool-versions"
	@echo "${DIVIDER}"
	$(Q)cd ${workhorse_dir} && $(MISE_INSTALL)
else
	@true
endif

.PHONY: khulnasoft-workhorse-clean-bin
khulnasoft-workhorse-clean-bin:
	$(Q)support/tool-version-manager-exec khulnasoft/workhorse $(MAKE) clean

.PHONY: khulnasoft/workhorse/khulnasoft-workhorse
khulnasoft/workhorse/khulnasoft-workhorse:
ifeq ($(workhorse_skip_compile),true)
	@echo
	@echo "${DIVIDER}"
	@echo "Downloading khulnasoft-workhorse binaries (workhorse.skip_compile set to true)"
	@echo "${DIVIDER}"
	$(Q)support/package-helper workhorse download
# WORKHORSE_TREE is needed in khulnasoft/tmp/tests/khulnasoft-workhorse so RSpec can detect the Workhorse version.
# We remove it from khulnasoft/workhorse to avoid it showing up as untracked, which would
# cause RSpec to rebuild KhulnaSoft Workhorse unnecessarily.
	$(Q)rm -f khulnasoft/workhorse/WORKHORSE_TREE
else
	$(Q)$(MAKE) khulnasoft-workhorse-clean-bin
	@echo
	@echo "${DIVIDER}"
	@echo "Compiling khulnasoft/workhorse/khulnasoft-workhorse"
	@echo "${DIVIDER}"
	$(Q)support/tool-version-manager-exec khulnasoft/workhorse $(MAKE) ${QQ}
endif
