# frozen_string_literal: true

desc 'Reconfigure your KDK'
spinner_task reconfigure:  %w[
  reconfigure:make:Procfile
  reconfigure:make:postgresql
  reconfigure:subprojects
  reconfigure:make:kdk-reconfigure-task
].freeze

namespace :reconfigure do
  Support::Rake::Reconfigure.make_tasks.each do |make_task|
    desc "Run `make #{make_task.target}`"
    task "make:#{make_task.target}" do |t|
      t.skip! if make_task.skip?

      success = KDK.make(make_task.target).success?
      raise "make #{make_task.target} failed" unless success
    end
  end

  subprojects = %w[
    openssh-setup
    nginx-setup
    registry-setup
    elasticsearch-setup
    khulnasoft-runner-setup
    runner-setup
    geo-config
    khulnasoft-topology-service-setup
    khulnasoft-http-router-setup
    khulnasoft-docs-setup
    khulnasoft-docs-hugo-setup
    khulnasoft-observability-backend-setup
    khulnasoft-elasticsearch-indexer-setup
    khulnasoft-k8s-agent-setup
    khulnasoft-pages-setup
    khulnasoft-ui-setup
    khulnasoft-zoekt-indexer-setup
    grafana-setup
    object-storage-setup
    openldap-setup
    pgvector-setup
    prom-setup
    snowplow-micro-setup
    zoekt-setup
    duo-workflow-service-setup
    duo-workflow-executor-setup
    postgresql-replica-setup
    postgresql-replica-2-setup
    openbao-setup
    siphon-setup
  ].map { |task| "make:#{task}" }

  desc nil
  multitask subprojects: subprojects
end
