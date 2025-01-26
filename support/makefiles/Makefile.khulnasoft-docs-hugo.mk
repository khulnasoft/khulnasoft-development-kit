khulnasoft_docs_hugo_dir = ${khulnasoft_development_root}/khulnasoft-docs-hugo

make_docs_hugo = $(Q)make -C ${khulnasoft_docs_hugo_dir}

ifeq ($(khulnasoft_docs_hugo_enabled),true)
khulnasoft-docs-hugo-setup: khulnasoft-docs-hugo/.git khulnasoft-docs-hugo-deps khulnasoft-docs-hugo-migrate khulnasoft-docs-yarn-build
else
khulnasoft-docs-hugo-setup:
	@true
endif

khulnasoft-docs-hugo/.git:
	$(Q)support/component-git-clone ${git_params} ${khulnasoft_docs_hugo_repo} khulnasoft-docs-hugo

khulnasoft-docs-hugo/.git/pull: khulnasoft-docs-hugo/.git
	@echo
	@echo "${DIVIDER}"
	@echo "Updating khulnasoft-org/khulnasoft-docs-hugo"
	@echo "${DIVIDER}"
	$(Q)support/component-git-update khulnasoft_docs_hugo "${khulnasoft_docs_hugo_dir}" main main

.PHONY: khulnasoft-docs-hugo-deps
khulnasoft-docs-hugo-deps: khulnasoft-docs-hugo-asdf-mise-install khulnasoft-docs-hugo-yarn

khulnasoft-docs-hugo-asdf-mise-install:
	@echo
	@echo "${DIVIDER}"
	@echo "Installing tools from ${khulnasoft_docs_hugo_dir}/.tool-versions"
	@echo "${DIVIDER}"
	$(Q)cd ${khulnasoft_docs_hugo_dir} && ASDF_DEFAULT_TOOL_VERSIONS_FILENAME="${khulnasoft_docs_hugo_dir}/.tool-versions" make install-dependencies

khulnasoft-docs-hugo-yarn:
	$(Q)cd ${khulnasoft_docs_hugo_dir} && corepack enable && make install-nodejs-dependencies

ifeq ($(khulnasoft_docs_hugo_run_migration_scripts),true)
khulnasoft-docs-hugo-migrate:
	@echo
	@echo "${DIVIDER}"
	@echo "Running KhulnaSoft Docs Hugo migration scripts"
	@echo "${DIVIDER}"
	$(make_docs_hugo) clone-docs-projects
else ifeq ($(khulnasoft_docs_hugo_enabled),true)
khulnasoft-docs-hugo-migrate:
	@echo
	@echo "${DIVIDER}"
	@echo "Fetching files required by KhulnaSoft Docs Hugo"
	@echo "${DIVIDER}"
	$(Q)cd ${khulnasoft_docs_hugo_dir} && go run cmd/gldocs/main.go fetch
else
khulnasoft-docs-hugo-migrate:
	@true
endif

ifeq ($(khulnasoft_docs_hugo_enabled),true)
khulnasoft-docs-yarn-build:
	@echo
	@echo "${DIVIDER}"
	@echo "Running vite"
	@echo "${DIVIDER}"
	$(Q)cd ${khulnasoft_docs_hugo_dir} && yarn build
else
khulnasoft-docs-yarn-build:
	@true
endif

.PHONY: khulnasoft-docs-hugo-update
ifeq ($(khulnasoft_docs_hugo_enabled),true)
khulnasoft-docs-hugo-update: khulnasoft-docs-hugo-update-timed
else
khulnasoft-docs-hugo-update:
	@true
endif

.PHONY: khulnasoft-docs-hugo-update-run
khulnasoft-docs-hugo-update-run: khulnasoft-docs-hugo/.git/pull khulnasoft-docs-hugo-deps khulnasoft-docs-hugo-migrate khulnasoft-docs-yarn-build
