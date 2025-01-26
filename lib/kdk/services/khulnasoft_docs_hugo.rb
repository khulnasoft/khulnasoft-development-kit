# frozen_string_literal: true

module KDK
  module Services
    class KhulnasoftDocsHugo < Base
      BASE_COMMAND = "support/exec-cd khulnasoft-docs-hugo hugo serve --cleanDestinationDir --baseURL %{protocol}://%{hostname} --port %{port} --bind %{hostname}"
      HTTPS_COMMAND = ' --tlsAuto'

      def name
        'khulnasoft-docs-hugo'
      end

      def command
        base_command = format(BASE_COMMAND, { protocol: protocol, hostname: config.hostname, port: config.khulnasoft_docs_hugo.port })

        return base_command unless config.https?

        base_command << HTTPS_COMMAND
      end

      def protocol
        config.https? ? :https : :http
      end

      def ready_message
        "KhulnaSoft Docs Hugo is available at #{protocol}://#{config.hostname}:#{config.khulnasoft_docs_hugo.port}."
      end

      def enabled?
        config.khulnasoft_docs_hugo.enabled?
      end
    end
  end
end
