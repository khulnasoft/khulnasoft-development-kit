# frozen_string_literal: true

require 'pathname'

module KDK
  module Services
    class SiphonProducerMainDb < Base
      def name
        'siphon-producer-main-db'
      end

      def command
        'siphon/cmd/cmd --configFile siphon/config.yml'
      end

      def ready_message
        "Siphon is listening on main DB for data from: #{config.siphon.tables.join(', ')}"
      end

      def validate!
        return unless config.siphon.enabled? && !config.clickhouse.enabled?

        raise KDK::ConfigSettings::UnsupportedConfiguration, <<~MSG.strip
          Running Siphon without ClickHouse is not possible.
          Enable ClickHouse in your KDK or disable Siphon to continue.
        MSG
      end

      def enabled?
        return false unless config.clickhouse.enabled?

        config.siphon.enabled?
      end
    end
  end
end
