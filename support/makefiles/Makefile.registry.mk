registry_dir = ${khulnasoft_development_root}/container-registry

ifeq ($(registry_enabled),true)
registry-setup: registry/bin/registry registry/storage registry/config.yml localhost.crt registry-migrate
else
registry-setup:
	@true
endif

.PHONY: registry-update
registry-update:
ifeq ($(registry_enabled),true)
	@echo
	@echo "${DIVIDER}"
	@echo "Setting up container-registry ${registry_version}"
	@echo "${DIVIDER}"
	$(Q)$(MAKE) registry-update-timed
else
	@true
endif

.PHONY: registry-update-run
registry-update-run: container-registry/.git/pull registry-clean-bin registry/bin/registry registry-migrate

registry-clean-bin:
	$(Q)rm -rf container-registry/bin

container-registry/.git:
	@echo
	@echo "${DIVIDER}"
	@echo "Cloning container registry"
	@echo "${DIVIDER}"
	$(Q)support/component-git-clone ${git_params} ${registry_repo} ${registry_dir}

registry/bin/registry: container-registry/.git/pull registry-tool-install
	@echo
	@echo "${DIVIDER}"
	@echo "Building container-registry version ${registry_version}"
	@echo "${DIVIDER}"
	$(Q)support/tool-version-manager-exec container-registry $(MAKE) ${QQ}

.PHONY: container-registry/.git/pull
container-registry/.git/pull: container-registry/.git
	@echo
	@echo "${DIVIDER}"
	@echo "Updating container registry"
	@echo "${DIVIDER}"
	$(Q)support/component-git-update registry "${registry_dir}" "${registry_version}" master

registry-tool-install:
ifeq ($(tool_version_manager_enabled),true)
	@echo
	@echo "${DIVIDER}"
	@echo "Installing mise tools from ${registry_dir}/.tool-versions"
	@echo "${DIVIDER}"
	$(Q)cd ${registry_dir} && $(MISE_INSTALL)
else
	@true
endif

registry_host.crt: registry_host.key

registry_host.key:
	$(Q)${OPENSSL} req -new -subj "/CN=${registry_host}/" -x509 -days 365 -newkey rsa:2048 -nodes -keyout "registry_host.key" -out "registry_host.crt" -addext "subjectAltName=DNS:${registry_host}"
	$(Q)chmod 600 $@

registry/storage:
	$(Q)mkdir -p $@

.PHONY: trust-docker-registry
trust-docker-registry: registry_host.crt
	$(Q)mkdir -p "${HOME}/.docker/certs.d/${registry_host}:${registry_port}"
	$(Q)rm -f "${HOME}/.docker/certs.d/${registry_host}:${registry_port}/ca.crt"
	$(Q)cp registry_host.crt "${HOME}/.docker/certs.d/${registry_host}:${registry_port}/ca.crt"
	$(Q)echo "Certificates have been copied to ~/.docker/certs.d/"
	$(Q)echo "Don't forget to restart Docker!"


.PHONY: registry-migrate
registry-migrate:
ifeq ($(registry_database_enabled), true)
	@echo
	@echo "${DIVIDER}"
	@echo "Applying any pending migrations"
	@echo "${DIVIDER}"
	$(Q)support/migrate-registry
else
	@true
endif
