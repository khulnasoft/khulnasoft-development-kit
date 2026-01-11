khulnasoft_pages_dir = ${khulnasoft_development_root}/khulnasoft-pages

ifeq ($(khulnasoft_pages_enabled),true)
khulnasoft-pages-setup: khulnasoft-pages-update-timed
else
khulnasoft-pages-setup:
	@true
endif

ifeq ($(khulnasoft_pages_enabled),true)
khulnasoft-pages-update: khulnasoft-pages-update-timed
else
khulnasoft-pages-update:
	@true
endif

.PHONY: khulnasoft-pages-update-run
khulnasoft-pages-update-run: khulnasoft-pages-secret khulnasoft-pages/khulnasoft-pages.conf khulnasoft-pages/bin/khulnasoft-pages

khulnasoft-pages-tool-install:
ifeq ($(tool_version_manager_enabled),true)
	@echo
	@echo "${DIVIDER}"
	@echo "Installing mise tools from ${khulnasoft_pages_dir}/.tool-versions"
	@echo "${DIVIDER}"
	$(Q)cd ${khulnasoft_pages_dir} && $(MISE_INSTALL)
else
	@true
endif

.PHONY: khulnasoft-pages/bin/khulnasoft-pages
khulnasoft-pages/bin/khulnasoft-pages: khulnasoft-pages/.git/pull khulnasoft-pages-tool-install
	@echo
	@echo "${DIVIDER}"
	@echo "Compiling khulnasoft-org/khulnasoft-pages"
	@echo "${DIVIDER}"
	$(Q)rm -f khulnasoft-pages/bin/khulnasoft-pages
	$(Q)support/tool-version-manager-exec ${khulnasoft_pages_dir} $(MAKE) ${QQ}

khulnasoft-pages/.git:
	$(Q)GIT_REVISION="${khulnasoft_pages_version}" support/component-git-clone ${git_params} ${khulnasoft_pages_repo} ${khulnasoft_pages_dir} ${QQ}

khulnasoft-pages/.git/pull: khulnasoft-pages/.git
	@echo
	@echo "${DIVIDER}"
	@echo "Updating khulnasoft-org/khulnasoft-pages to ${khulnasoft_pages_version}"
	@echo "${DIVIDER}"
	$(Q)support/component-git-update khulnasoft_pages "${khulnasoft_pages_dir}" "${khulnasoft_pages_version}" master
