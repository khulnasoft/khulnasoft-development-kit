# frozen_string_literal: true

require 'rake'

module KDK
  module Command
    class Cleanup < BaseCommand
      help 'Truncate log files and remove any unnecessarily installed dependencies'

      def run(_ = [])
        return true unless continue?

        execute
      end

      private

      def continue?
        KDK::Output.warn('About to perform the following actions:')
        KDK::Output.puts(stderr: true)
        KDK::Output.puts('- Truncate khulnasoft/log/* files', stderr: true)
        KDK::Output.puts("- Truncate #{KDK::Services::KhulnaSoftHttpRouter::LOG_PATH} file", stderr: true)

        KDK::Output.puts(stderr: true)

        return true if ENV.fetch('KDK_CLEANUP_CONFIRM', 'false') == 'true' || !KDK::Output.interactive?

        result = KDK::Output.prompt('Are you sure? [y/N]').match?(/\Ay(?:es)*\z/i)
        KDK::Output.puts(stderr: true)

        result
      end

      def execute
        truncate_log_files
        truncate_http_router_log_files
      rescue StandardError => e
        KDK::Output.error(e)
        false
      end

      def truncate_log_files
        run_rake('khulnasoft:truncate_logs', 'false')
      end

      def truncate_http_router_log_files
        run_rake('khulnasoft:truncate_http_router_logs', 'false')
      end
    end
  end
end
