# frozen_string_literal: true

require 'fileutils'
require 'net/http'

desc 'Update your KDK'
spinner_task update: %w[
  update:kdk_bundle_install
  update:khulnasoft
  update:platform
  preflight-checks
  preflight-update-checks
  update:subprojects
  update:make:unlock-dependency-installers
].freeze

namespace :update do
  Support::Rake::Update.make_tasks.each do |make_task|
    desc "Run `make #{make_task.target}`"
    task "make:#{make_task.target}" do |t|
      t.skip! if make_task.skip?

      success = KDK.make(make_task.target).success?
      raise "make #{make_task.target} failed" unless success
    end
  end

  desc 'Install gems for KDK'
  task :kdk_bundle_install do
    sh = KDK::Shellout.new(%w[bundle install], chdir: KDK.config.kdk_root).execute
    raise StandardError, 'bundle install failed to succeed' unless sh.success?
  end

  desc 'Download GraphQL schema'
  task 'graphql' do
    KDK::PackageHelper.new(
      package: :graphql_schema,
      project_id: 278964 # khulnasoft-org/khulnasoft
    ).download_package
  end

  desc 'Platform update'
  task 'platform' do
    sh = KDK::Shellout.new('support/platform-update', chdir: KDK.config.kdk_root).execute
    raise StandardError, 'support/platform-update failed to succeed' unless sh.success?
  end

  desc nil
  task 'khulnasoft' => %w[
    make:khulnasoft-git-pull
    make:khulnasoft-setup
    make:postgresql
  ]

  desc nil
  multitask 'subprojects' => %w[
    make:khulnasoft-db-migrate
    update:graphql
    make:khulnasoft-translations-unlock
    make:gitaly-update
    make:ensure-databases-setup
    make:khulnasoft-shell-update
    make:khulnasoft-http-router-update
    make:khulnasoft-topology-service-update
    make:khulnasoft-docs-update
    make:khulnasoft-docs-hugo-update
    make:khulnasoft-elasticsearch-indexer-update
    make:khulnasoft-k8s-agent-update
    make:khulnasoft-pages-update
    make:khulnasoft-ui-update
    make:khulnasoft-workhorse-update
    make:khulnasoft-zoekt-indexer-update
    make:khulnasoft-ai-gateway-update
    make:grafana-update
    make:jaeger-update
    make:object-storage-update
    make:pgvector-update
    make:zoekt-update
    make:openbao-update
    make:khulnasoft-runner-update
    make:duo-workflow-service-update
    make:siphon-update
  ]
end
