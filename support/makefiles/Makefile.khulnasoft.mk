khulnasoft_dir = ${khulnasoft_development_root}/khulnasoft
khulnasoft_rake_cmd = support/tool-version-manager-exec khulnasoft bundle exec rake
khulnasoft_git_cmd = git -C $(khulnasoft_dir)
default_branch ?= $(if $(khulnasoft_default_branch),$(khulnasoft_default_branch),master)

.PHONY: khulnasoft-setup
khulnasoft-setup: khulnasoft/.git khulnasoft-config khulnasoft-tool-install .khulnasoft-bundle .khulnasoft-lefthook .khulnasoft-yarn .khulnasoft-translations

khulnasoft/doc/api/graphql/reference/khulnasoft_schema.json: .khulnasoft-bundle
	@echo
	@echo "${DIVIDER}"
	@echo "Generating khulnasoft GraphQL schema files"
	@echo "${DIVIDER}"
	$(Q)$(khulnasoft_rake_cmd) khulnasoft:graphql:schema:dump ${QQ}

khulnasoft/.git:
	@echo
	@echo "${DIVIDER}"
	@echo "Cloning ${khulnasoft_repo}"
	@echo "${DIVIDER}"
	$(Q)support/component-git-clone ${git_params} $(if $(realpath ${khulnasoft_repo}),--shared) ${khulnasoft_repo} ${khulnasoft_dir}

khulnasoft-tool-install:
ifeq ($(tool_version_manager_enabled),true)
	@echo
	@echo "${DIVIDER}"
	@echo "Installing mise tools from ${khulnasoft_dir}/.tool-versions"
	@echo "${DIVIDER}"
	$(Q)cd ${khulnasoft_dir} && $(MISE_INSTALL)
else
	@true
endif

khulnasoft-config: touch-examples khulnasoft/public/uploads
	$(Q)rake \
		khulnasoft/config/khulnasoft.yml \
		khulnasoft/config/database.yml \
		khulnasoft/config/cable.yml \
		khulnasoft/config/resque.yml \
		khulnasoft/config/redis.cache.yml \
		khulnasoft/config/redis.repository_cache.yml \
		khulnasoft/config/redis.queues.yml \
		khulnasoft/config/redis.shared_state.yml \
		khulnasoft/config/redis.trace_chunks.yml \
		khulnasoft/config/redis.rate_limiting.yml \
		khulnasoft/config/redis.sessions.yml \
		khulnasoft/config/vite.kdk.json \
		khulnasoft/config/puma.rb

khulnasoft/public/uploads:
	$(Q)mkdir $@

.PHONY: khulnasoft-bundle-prepare
khulnasoft-bundle-prepare:
	@echo
	@echo "${DIVIDER}"
	@echo "Setting up Ruby bundler"
	@echo "${DIVIDER}"
	${Q}. ./support/bootstrap-common.sh ; configure_ruby_bundler_for_khulnasoft

.khulnasoft-bundle: khulnasoft-bundle-prepare
	@echo
	@echo "${DIVIDER}"
	@echo "Installing khulnasoft-org/khulnasoft Ruby gems"
	@echo "${DIVIDER}"
	${Q}$(support_bundle_install) $(khulnasoft_dir)
	$(Q)touch $@

ifeq ($(khulnasoft_lefthook_enabled),true)
.khulnasoft-lefthook:
	@echo
	@echo "${DIVIDER}"
	@echo "Enabling Lefthook for khulnasoft-org/khulnasoft"
	@echo "${DIVIDER}"
	$(Q)support/tool-version-manager-exec khulnasoft bundle exec lefthook install
	$(Q)touch $@
else
.khulnasoft-lefthook:
	@true
endif

.khulnasoft-yarn:
	@echo
	@echo "${DIVIDER}"
	@echo "Installing khulnasoft-org/khulnasoft Node.js packages"
	@echo "${DIVIDER}"
ifeq ($(vite_enabled),true)
	$(Q)echo "Deleting Vite cache"
	$(Q)rm -rf khulnasoft/tmp/cache/vite || echo "Warning: Failed to delete Vite cache directory"
endif
	$(Q)support/tool-version-manager-exec khulnasoft yarn install --pure-lockfile
	$(Q)touch $@

.PHONY: khulnasoft-translations-unlock
khulnasoft-translations-unlock:
	$(Q)rm -f .khulnasoft-translations

.PHONY: khulnasoft-translations
khulnasoft-translations: khulnasoft-translations-timed

.PHONY: khulnasoft-translations-run
khulnasoft-translations-run: .khulnasoft-translations

.khulnasoft-translations:
	@echo
	@echo "${DIVIDER}"
	@echo "Generating khulnasoft-org/khulnasoft Rails translations"
	@echo "${DIVIDER}"
	$(Q)rake khulnasoft:recompile_translations
	$(Q)$(khulnasoft_git_cmd) checkout locale/*/khulnasoft.po
	$(Q)touch $@
