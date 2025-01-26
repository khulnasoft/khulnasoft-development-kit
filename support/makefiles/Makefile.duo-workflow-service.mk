duo_workflow_service_dir = ${khulnasoft_development_root}/duo-workflow-service

.PHONY: duo-workflow-service-setup
ifeq ($(duo_workflow_enabled),true)
duo-workflow-service-setup: duo-workflow-service/poetry-install duo-workflow-service/.env duo-workflow-service-llm-cache duo-workflow-service-cc-service-name
else
duo-workflow-service-setup:
	@true
endif

.PHONY: duo-workflow-service-update
ifeq ($(duo-workflow-service_enabled),true)
duo-workflow-service-update: duo-workflow-service-update-timed
else
duo-workflow-service-update:
	@true
endif

.PHONY: duo-workflow-service-update-run
duo-workflow-service-update-run: duo-workflow-service/.git/pull duo-workflow-service/poetry-install

duo-workflow-service-asdf-install:
ifeq ($(asdf_opt_out),false)
	@echo
	@echo "${DIVIDER}"
	@echo "Installing asdf tools from ${duo_workflow_service_dir}/.tool-versions"
	@echo "${DIVIDER}"
	$(Q)cd ${duo_workflow_service_dir} && ASDF_DEFAULT_TOOL_VERSIONS_FILENAME="${duo_workflow_service_dir}/.tool-versions" asdf install
else ifeq ($(mise_enabled),true)
	@echo
	@echo "${DIVIDER}"
	@echo "Installing mise tools from ${duo_workflow_service_dir}/.tool-versions"
	@echo "${DIVIDER}"
	$(Q)cd ${duo_workflow_service_dir} && mise install -y
else
	@true
endif

duo-workflow-service/.git:
	$(Q)GIT_REVISION="${duo_workflow_service_version}" CLONE_DIR=duo-workflow-service support/component-git-clone ${git_params} ${duo_workflow_service_repo} duo-workflow-service

duo-workflow-service/.env: duo-workflow-service/.env.example
	@echo
	@echo "${DIVIDER}"
	@echo "Replacing duo-workflow-service/.env file"
	@echo "${DIVIDER}"
	cp duo-workflow-service/.env.example duo-workflow-service/.env

.PHONY: duo-workflow-service-llm-cache
ifeq ($(duo_workflow_llm_cache),true)
duo-workflow-service-llm-cache: duo-workflow-service/.env
	# Add LLM_CACHE=true only if no LLM_CACHE line exists. Also add
	# newline just in case it does not end in a newline already
	grep -q 'LLM_CACHE' duo-workflow-service/.env || echo -e '\nLLM_CACHE=true' >> duo-workflow-service/.env
else
duo-workflow-service-llm-cache:
	# Remove the LLM_CACHE line from the file
	grep -v LLM_CACHE duo-workflow-service/.env > duo-workflow-service/.env.temp && mv duo-workflow-service/.env.temp duo-workflow-service/.env
endif

.PHONY: duo-workflow-service-cc-service-name
duo-workflow-service-cc-service-name:
	# Add CLOUD_CONNECTOR_SERVICE_NAME="khulnasoft-duo-workflow-service". Also add
	# newline just in case it does not end in a newline already
	grep -q 'CLOUD_CONNECTOR_SERVICE_NAME' duo-workflow-service/.env || echo -e '\nCLOUD_CONNECTOR_SERVICE_NAME="khulnasoft-duo-workflow-service"' >> duo-workflow-service/.env

.PHONY: duo-workflow-service/poetry-install
duo-workflow-service/poetry-install: duo-workflow-service/.git duo-workflow-service-asdf-install
	@echo
	@echo "${DIVIDER}"
	@echo "Building $@ version ${duo_workflow_service_version}"
	@echo "${DIVIDER}"
	$(Q)support/asdf-exec duo-workflow-service poetry install

.PHONY: duo-workflow-service/.git/pull
duo-workflow-service/.git/pull: duo-workflow-service/.git
	@echo
	@echo "${DIVIDER}"
	@echo "Updating duo-workflow-service"
	@echo "${DIVIDER}"
	$(Q)support/component-git-update duo_workflow duo-workflow-service "${duo_workflow_service_version}" main
