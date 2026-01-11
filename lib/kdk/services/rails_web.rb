# frozen_string_literal: true

module KDK
  module Services
    # Rails web frontend server
    class RailsWeb < Base
      def name
        'rails-web'
      end

      def command
        %(support/exec-cd khulnasoft bin/web start_foreground)
      end

      def enabled?
        config.rails_web?
      end

      def env
        e = {
          CACHE_CLASSES: config.khulnasoft.cache_classes,
          BUNDLE_GEMFILE: config.khulnasoft.rails.bundle_gemfile,
          ENABLE_BOOTSNAP: config.khulnasoft.rails.bootsnap?,
          RAILS_RELATIVE_URL_ROOT: config.relative_url_root,
          ACTION_CABLE_IN_APP: 'true',
          ACTION_CABLE_WORKER_POOL_SIZE: config.action_cable.worker_pool_size,
          GITALY_DISABLE_REQUEST_LIMITS: config.khulnasoft.gitaly_disable_request_limits
        }

        e[:KDK_GEO_SECONDARY] = 1 if config.geo? && config.geo.secondary?

        e
      end

      def ready_message
        <<~MESSAGE
          KhulnaSoft available at #{uri}
            - Ruby: #{version_for('ruby')}.
            - Node.js: #{version_for('node')}.
        MESSAGE
      end

      def version_for(bin)
        KDK::Shellout.new(%W[#{bin} --version]).run
      rescue StandardError => e
        "Unknown (#{e.message})"
      end

      private

      def uri
        klass = config.khulnasoft.rails.https? ? URI::HTTPS : URI::HTTP

        klass.build(
          host: config.khulnasoft.rails.hostname,
          port: config.khulnasoft.rails.port,
          path: config.relative_url_root.gsub(%r{/+$}, '')
        )
      end
    end
  end
end
