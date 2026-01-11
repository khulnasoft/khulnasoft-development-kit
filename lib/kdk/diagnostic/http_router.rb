# frozen_string_literal: true

module KDK
  module Diagnostic
    class HttpRouter < Base
      TITLE = 'HTTP Router Logs'
      HTTP_ROUTER_LOG_SIZE_NOT_OK_MB = 100
      BYTES_TO_MEGABYTES = 1_048_576

      def success?
        return true unless config.khulnasoft_http_router.enabled?
        return true unless http_router_log_file.exist?

        http_router_log_size <= HTTP_ROUTER_LOG_SIZE_NOT_OK_MB
      end

      def detail
        return if success?

        <<~LOG_SIZE_NOT_OK
          Your HTTP Router log file is #{http_router_log_size}MB. You can truncate the log file if you wish
          by running:

            kdk rake khulnasoft:truncate_http_router_logs
        LOG_SIZE_NOT_OK
      end

      private

      def http_router_log_file
        config.kdk_root.join(KDK::Services::KhulnasoftHttpRouter::LOG_PATH)
      end

      def http_router_log_size
        @http_router_log_size ||= http_router_log_file.size / BYTES_TO_MEGABYTES
      end
    end
  end
end
