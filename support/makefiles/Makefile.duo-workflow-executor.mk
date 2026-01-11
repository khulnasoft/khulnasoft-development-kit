duo_workflow_executor_dir =  ${khulnasoft_development_root}/duo-workflow-executor

ifeq ($(duo_workflow_enabled),true)
duo-workflow-executor-setup: khulnasoft/public/assets/duo-workflow-executor/bin/duo-workflow-executor.tar.gz
else
duo-workflow-executor-setup:
	@true
endif

.PHONY: duo-workflow-executor-update
ifeq ($(duo_workflow_enabled),true)
duo-workflow-executor-update: duo-workflow-executor-update-timed
else
duo-workflow-executor-update:
	@true
endif

.PHONY: duo-workflow-executor-update-run
duo-workflow-executor-update-run: duo-workflow-executor/.git/pull duo-workflow-executor-clean-bin duo-workflow-executor/bin/duo-workflow-executor

duo-workflow-executor-clean-bin:
	$(Q)rm -rf duo-workflow-executor/bin

duo-workflow-executor/.git:
	$(Q)GIT_REVISION="${duo_workflow_executor_version}" support/component-git-clone ${git_params} ${duo_workflow_executor_repo} duo-workflow-executor

duo-workflow-executor/bin/duo-workflow-executor: duo-workflow-executor/.git/pull duo-workflow-executor-tool-install
	@echo
	@echo "${DIVIDER}"
	@echo "Building duo-workflow-executor version ${duo_workflow_executor_version}"
	@echo "${DIVIDER}"
	$(Q)GOOS=$(duo_workflow_executor_build_os) GOARCH=$(duo_workflow_executor_build_arch) support/tool-version-manager-exec duo-workflow-executor $(MAKE) build ${QQ}

duo-workflow-executor/bin/duo-workflow-executor.tar.gz: duo-workflow-executor/bin/duo-workflow-executor
	tar --no-xattrs -C duo-workflow-executor/bin -czvf duo-workflow-executor/bin/duo-workflow-executor.tar.gz duo-workflow-executor

khulnasoft/public/assets/duo-workflow-executor/bin/duo-workflow-executor.tar.gz: duo-workflow-executor/bin/duo-workflow-executor.tar.gz
	mkdir -p khulnasoft/public/assets
	mv duo-workflow-executor/bin/duo-workflow-executor.tar.gz khulnasoft/public/assets/

.PHONY: duo-workflow-executor/.git/pull
duo-workflow-executor/.git/pull: duo-workflow-executor/.git
	@echo
	@echo "${DIVIDER}"
	@echo "Updating duo-workflow-executor"
	@echo "${DIVIDER}"
	$(Q)support/component-git-update duo_workflow duo-workflow-executor "${duo_workflow_executor_version}" main

duo-workflow-executor-tool-install:
ifeq ($(tool_version_manager_enabled),true)
	@echo
	@echo "${DIVIDER}"
	@echo "Installing mise tools from ${duo_workflow_executor_dir}/.tool-versions"
	@echo "${DIVIDER}"
	$(Q)cd ${duo_workflow_executor_dir} && $(MISE_INSTALL)
else
	@true
endif
