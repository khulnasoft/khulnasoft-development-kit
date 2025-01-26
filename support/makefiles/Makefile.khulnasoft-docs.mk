khulnasoft_docs_dir = ${khulnasoft_development_root}/khulnasoft-docs
khulnasoft_runner_clone_dir = khulnasoft-runner
omnibus_khulnasoft_clone_dir = omnibus-khulnasoft
charts_khulnasoft_clone_dir = charts-khulnasoft
khulnasoft_operator_clone_dir = khulnasoft-operator

# Silence Rollup when building KhulnaSoft Docs with nanoc
export ROLLUP_OPTIONS = --silent

make_docs = $(Q)make -C ${khulnasoft_docs_dir}

ifeq ($(khulnasoft_docs_enabled),true)
khulnasoft-docs-setup: khulnasoft-docs/.git khulnasoft-runner-setup omnibus-khulnasoft charts-khulnasoft khulnasoft-operator khulnasoft-docs-deps
else
khulnasoft-docs-setup:
	@true
endif

ifeq ($(omnibus_khulnasoft_enabled),true)
omnibus-khulnasoft: omnibus-khulnasoft/.git
else
omnibus-khulnasoft:
	@true
endif

ifeq ($(omnibus_khulnasoft_enabled),true)
omnibus-khulnasoft-pull: omnibus-khulnasoft/.git/pull
else
omnibus-khulnasoft-pull:
	@true
endif

ifeq ($(charts_khulnasoft_enabled),true)
charts-khulnasoft: charts-khulnasoft/.git
else
charts-khulnasoft:
	@true
endif

ifeq ($(charts_khulnasoft_enabled),true)
charts-khulnasoft-pull: charts-khulnasoft/.git/pull
else
charts-khulnasoft-pull:
	@true
endif

ifeq ($(khulnasoft_operator_enabled),true)
khulnasoft-operator: khulnasoft-operator/.git
else
khulnasoft-operator:
	@true
endif

ifeq ($(khulnasoft_operator_enabled),true)
khulnasoft-operator-pull: khulnasoft-operator/.git/pull
else
khulnasoft-operator-pull:
	@true
endif

khulnasoft-docs/.git:
	$(Q)support/component-git-clone ${git_params} ${khulnasoft_docs_repo} khulnasoft-docs

khulnasoft-docs/.git/pull: khulnasoft-docs/.git
	@echo
	@echo "${DIVIDER}"
	@echo "Updating khulnasoft-org/khulnasoft-docs"
	@echo "${DIVIDER}"
	$(Q)support/component-git-update khulnasoft_docs "${khulnasoft_docs_dir}" main main

omnibus-khulnasoft/.git:
	$(Q)support/component-git-clone ${git_params} ${omnibus_khulnasoft_repo} omnibus-khulnasoft

omnibus-khulnasoft/.git/pull: omnibus-khulnasoft/.git
	@echo
	@echo "${DIVIDER}"
	@echo "Updating khulnasoft-org/omnibus-khulnasoft"
	@echo "${DIVIDER}"
	$(Q)support/component-git-update omnibus_khulnasoft "${omnibus_khulnasoft_clone_dir}" master master

charts-khulnasoft/.git:
	$(Q)support/component-git-clone ${git_params} ${charts_khulnasoft_repo} charts-khulnasoft

charts-khulnasoft/.git/pull: charts-khulnasoft/.git
	@echo
	@echo "${DIVIDER}"
	@echo "Updating khulnasoft-org/charts/khulnasoft"
	@echo "${DIVIDER}"
	$(Q)support/component-git-update charts_khulnasoft "${charts_khulnasoft_clone_dir}" master master

khulnasoft-operator/.git:
	$(Q)support/component-git-clone ${git_params} ${khulnasoft_operator_repo} khulnasoft-operator

khulnasoft-operator/.git/pull: khulnasoft-operator/.git
	@echo
	@echo "${DIVIDER}"
	@echo "Updating khulnasoft-org/cloud-native/khulnasoft-operator"
	@echo "${DIVIDER}"
	$(Q)support/component-git-update khulnasoft_operator "${khulnasoft_operator_clone_dir}" master master

.PHONY: khulnasoft-docs-deps
khulnasoft-docs-deps: khulnasoft-docs-asdf-install khulnasoft-docs-bundle khulnasoft-docs-yarn

khulnasoft-docs-asdf-install:
ifeq ($(asdf_opt_out),false)
	@echo
	@echo "${DIVIDER}"
	@echo "Installing asdf tools from ${khulnasoft_docs_dir}/.tool-versions"
	@echo "${DIVIDER}"
	$(Q)cd ${khulnasoft_docs_dir} && ASDF_DEFAULT_TOOL_VERSIONS_FILENAME="${khulnasoft_docs_dir}/.tool-versions" make install-asdf-dependencies
else ifeq ($(mise_enabled),true)
	@echo
	@echo "${DIVIDER}"
	@echo "Installing mise tools from ${khulnasoft_docs_dir}/.tool-versions"
	@echo "${DIVIDER}"
	$(Q)cd ${khulnasoft_docs_dir} && mise install -y
else
	@true
endif

khulnasoft-docs-bundle:
	@echo
	@echo "${DIVIDER}"
	@echo "Installing khulnasoft-org/khulnasoft-docs Ruby gems"
	@echo "${DIVIDER}"
	${Q}$(support_bundle_install) $(khulnasoft_docs_dir)

khulnasoft-docs-yarn:
	$(Q)cd ${khulnasoft_docs_dir} && make install-nodejs-dependencies

khulnasoft-docs-clean:
	$(Q)cd ${khulnasoft_docs_dir} && rm -rf tmp

khulnasoft-docs-build:
	$(make_docs) compile

.PHONY: khulnasoft-docs-update
ifeq ($(khulnasoft_docs_enabled),true)
khulnasoft-docs-update: khulnasoft-docs-update-timed
else
khulnasoft-docs-update:
	@true
endif

.PHONY: khulnasoft-docs-update-run
khulnasoft-docs-update-run: khulnasoft-docs/.git/pull khulnasoft-runner-update omnibus-khulnasoft-pull charts-khulnasoft-pull khulnasoft-operator-pull khulnasoft-docs-deps khulnasoft-docs-build

# Internal links and anchors checks for documentation
ifeq ($(khulnasoft_docs_enabled),true)
khulnasoft-docs-check: khulnasoft-runner-docs-check omnibus-khulnasoft-docs-check charts-khulnasoft-docs-check khulnasoft-operator-docs-check khulnasoft-docs-build
	$(make_docs) internal-links-and-anchors-check
else
khulnasoft-docs-check:
	@echo "ERROR: khulnasoft_docs is not enabled. See doc/howto/khulnasoft_docs.md"
	@false
endif

ifneq ($(khulnasoft_runner_enabled),true)
khulnasoft-runner-docs-check:
	@echo "ERROR: khulnasoft_runner is not enabled. See doc/howto/khulnasoft_docs.md"
	@false
else
khulnasoft-runner-docs-check:
	@true
endif

ifneq ($(omnibus_khulnasoft_enabled),true)
omnibus-khulnasoft-docs-check:
	@echo "ERROR: omnibus_khulnasoft is not enabled. See doc/howto/khulnasoft_docs.md"
	@false
else
omnibus-khulnasoft-docs-check:
	@true
endif

ifneq ($(charts_khulnasoft_enabled),true)
charts-khulnasoft-docs-check:
	@echo "ERROR: charts_khulnasoft is not enabled. See doc/howto/khulnasoft_docs.md"
	@false
else
charts-khulnasoft-docs-check:
	@true
endif

ifneq ($(khulnasoft_operator_enabled),true)
khulnasoft-operator-docs-check:
	@echo "ERROR: khulnasoft_operator is not enabled. See doc/howto/khulnasoft_docs.md"
	@false
else
khulnasoft-operator-docs-check:
	@true
endif

