# frozen_string_literal: true

module KDK
  module Diagnostic
    class AiGateway < Base
      TITLE = 'AI Gateway'
      STAGING_URL = 'https://cloud.staging.khulnasoft.com'

      def success?
        @success ||= !ai_gateway_enabled? || !using_staging_url?
      end

      def detail
        return if success?

        <<~MESSAGE
          Self-Hosted AI Gateway URL is set to staging (#{STAGING_URL}) in the database. This is not the correct way to configure the staging AI Gateway URL.

          If you want to connect to staging AI Gateway:
              1. Set environment: kdk config set khulnasoft_ai_gateway.environment staging
              2. Run: kdk reconfigure

            If you want to use self-hosted models:
              Change the URL: kdk rails runner "::Ai::Setting.instance.update!(ai_gateway_url: 'http://localhost:5052')"
        MESSAGE
      end

      def correct!
        return false unless using_staging_url?

        switch_to_environment('staging')
      end

      private

      def ai_gateway_enabled?
        config.khulnasoft_ai_gateway.enabled
      end

      def ai_gateway_url
        @ai_gateway_url ||= fetch_url_from_database
      end

      def clear_ai_gateway_url
        args = ['--no-align', '--tuples-only', '--command', 'UPDATE ai_settings SET ai_gateway_url = NULL']
        command = *KDK::Postgresql.new.psql_cmd(args, database: 'khulnasofthq_development')

        sh = KDK::Shellout.new(command).execute(display_output: false)
        raise 'Failed to clear AI Gateway URL from database' unless sh.success?
      end

      def fetch_url_from_database
        args = ['--no-align', '--tuples-only', '--command', 'SELECT ai_gateway_url FROM ai_settings LIMIT 1']
        command = *KDK::Postgresql.new.psql_cmd(args, database: 'khulnasofthq_development')

        sh = KDK::Shellout.new(command).execute(display_output: false)
        return unless sh.success?

        url = sh.read_stdout.strip
        url.empty? ? nil : url
      end

      def using_staging_url?
        ai_gateway_url&.start_with?(STAGING_URL)
      end

      def switch_to_environment(env)
        clear_ai_gateway_url if env == 'staging'

        config.bury!('khulnasoft_ai_gateway.environment', env)
        config.save_yaml!
      end
    end
  end
end
