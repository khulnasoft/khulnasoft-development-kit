# frozen_string_literal: true

module KDK
  module Services
    class RailsBackgroundJobs < Base
      def name
        'rails-background-jobs'
      end

      def command
        %(support/exec-cd khulnasoft bin/background_jobs start_foreground --timeout #{config.khulnasoft.rails_background_jobs.timeout})
      end

      def enabled?
        config.khulnasoft.rails_background_jobs.enabled?
      end

      def env
        e = {
          SIDEKIQ_VERBOSE: config.khulnasoft.rails_background_jobs.verbose?,
          SIDEKIQ_QUEUES: %w[
            default mailers email_receiver
            hashed_storage:hashed_storage_migrator
            hashed_storage:hashed_storage_project_migrate
            hashed_storage:hashed_storage_project_rollback
            hashed_storage:hashed_storage_rollbacker
            project_import_schedule
            service_desk_email_receiver
          ].join(','),
          CACHE_CLASSES: config.khulnasoft.cache_classes,
          BUNDLE_GEMFILE: config.khulnasoft.rails.bundle_gemfile,
          SIDEKIQ_WORKERS: 1,
          ENABLE_BOOTSNAP: config.khulnasoft.rails.bootsnap?,
          RAILS_RELATIVE_URL_ROOT: config.relative_url_root,
          GITALY_DISABLE_REQUEST_LIMITS: config.khulnasoft.gitaly_disable_request_limits
        }

        e[:KDK_GEO_SECONDARY] = 1 if config.geo? && config.geo.secondary?

        e
      end
    end
  end
end
