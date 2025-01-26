# frozen_string_literal: true

require 'fileutils'

module Support
  module Rake
    class Reconfigure
      CORE_TARGETS = %w[
        Procfile
        jaeger-setup
        postgresql
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
        kdk-reconfigure-task
      ].freeze

      def self.make_tasks
        CORE_TARGETS.map { |target| make_task(target) }
      end

      def self.make_task(target, enabled: true)
        MakeTask.new(target: target, enabled: enabled)
      end
    end
  end
end
