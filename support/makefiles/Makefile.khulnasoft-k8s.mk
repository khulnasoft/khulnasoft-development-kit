khulnasoft_k8s_agent_clone_dir = khulnasoft-k8s-agent
khulnasoft_k8s_agent_version = $(shell support/resolve-dependency-commitish "${khulnasoft_development_root}/khulnasoft/KHULNASOFT_KAS_VERSION")

ifeq ($(khulnasoft_k8s_agent_enabled),true)
khulnasoft-k8s-agent-setup: khulnasoft-k8s-agent/build/kdk/bin/kas_race khulnasoft-k8s-agent-config.yml khulnasoft-kas-websocket-token-secret
else
khulnasoft-k8s-agent-setup:
	@true
endif

.PHONY: khulnasoft-k8s-agent-update
ifeq ($(khulnasoft_k8s_agent_enabled),true)
khulnasoft-k8s-agent-update: khulnasoft-k8s-agent-update-timed
else
khulnasoft-k8s-agent-update:
	@true
endif

.PHONY: khulnasoft-k8s-agent-update-run
khulnasoft-k8s-agent-update-run: ${khulnasoft_k8s_agent_clone_dir}/.git khulnasoft-k8s-agent/.git/pull khulnasoft-k8s-agent/build/kdk/bin/kas_race


.PHONY: khulnasoft-k8s-agent-clean
khulnasoft-k8s-agent-clean:
	$(Q)rm -rf "${khulnasoft_k8s_agent_clone_dir}/build/kdk/bin"
	cd "${khulnasoft_k8s_agent_clone_dir}" && bazel clean

khulnasoft-k8s-agent/build/kdk/bin/kas_race: ${khulnasoft_k8s_agent_clone_dir}/.git khulnasoft-k8s-agent/bazel
	@echo
	@echo "${DIVIDER}"
	@echo "Installing khulnasoft-org/cluster-integration/khulnasoft-agent"
	@echo "${DIVIDER}"
	$(Q)mkdir -p "${khulnasoft_k8s_agent_clone_dir}/build/kdk/bin"
	$(Q)support/asdf-exec "${khulnasoft_k8s_agent_clone_dir}" $(MAKE) kdk-install TARGET_DIRECTORY="$(CURDIR)/${khulnasoft_k8s_agent_clone_dir}/build/kdk/bin" ${QQ}

ifeq ($(platform),darwin)
khulnasoft-k8s-agent/bazel: /usr/local/bin/bazelisk
	$(Q)touch $@
else
.PHONY: khulnasoft-k8s-agent/bazel
khulnasoft-k8s-agent/bazel:
	@echo "INFO: To install bazel, please consult the docs at https://github.com/khulnasoft/khulnasoft-development-kit/-/blob/main/doc/howto/kubernetes_agent.md"
endif

/usr/local/bin/bazelisk:
	$(Q)brew install bazelisk

${khulnasoft_k8s_agent_clone_dir}/.git:
	$(Q)GIT_REVISION="${khulnasoft_k8s_agent_version}" support/component-git-clone ${git_params} ${khulnasoft_k8s_agent_repo} ${khulnasoft_k8s_agent_clone_dir} ${QQ}

khulnasoft-k8s-agent/.git/pull:
	@echo
	@echo "${DIVIDER}"
	@echo "Updating khulnasoft-org/cluster-integration/khulnasoft-agent to ${khulnasoft_k8s_agent_version}"
	@echo "${DIVIDER}"
	$(Q)support/component-git-update khulnasoft_k8s_agent "${khulnasoft_k8s_agent_clone_dir}" "${khulnasoft_k8s_agent_version}" master
