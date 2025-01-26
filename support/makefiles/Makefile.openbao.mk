openbao_dir = ${khulnasoft_development_root}/openbao

.PHONY: openbao-setup
ifeq ($(openbao_enabled),true)
openbao-setup: openbao-setup-timed
else
openbao-setup:
	@true
endif

.PHONY: openbao-setup-run
openbao-setup-run: openbao/.git openbao-common-setup

openbao/.git:
	$(Q)rm -fr openbao/config.hcl
	$(Q)support/component-git-clone ${git_params} ${openbao_repo} openbao

.PHONY: openbao-common-setup
openbao-common-setup: openbao-install

.PHONY: openbao-install
openbao-install:
	@echo
	@echo "${DIVIDER}"
	@echo "Performing steps for ${openbao_dir}"
	@echo "${DIVIDER}"
	$(Q) cd ${openbao_dir} && make bootstrap && make dev

.PHONY: openbao-update
ifeq ($(openbao_enabled),true)
openbao-update: openbao-update-timed
else
openbao-update:
	@true
endif

.PHONY: openbao-update-run
openbao-update-run: openbao/bin/openbao

.PHONY: openbao/.git/pull
openbao/.git/pull: openbao/.git
	@echo
	@echo "${DIVIDER}"
	@echo "Updating openbao"
	@echo "${DIVIDER}"
	$(Q)support/component-git-update openbao openbao "${openbao_version}" main

.PHONY: openbao/bin/openbao
openbao/bin/openbao: openbao/.git/pull
	@echo
	@echo "${DIVIDER}"
	@echo "Compiling openbao"
	@echo "${DIVIDER}"
	$(Q)rm -f openbao/bin/bao
	$(Q)support/asdf-exec ${openbao_dir} $(MAKE) ${QQ}
