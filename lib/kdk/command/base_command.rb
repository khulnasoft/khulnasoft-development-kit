# frozen_string_literal: true

module KDK
  module Command
    # Base interface for KDK commands
    class BaseCommand
      # Services order in which ready messages are printed.
      # Messages for missing services are printed alphabetically.
      READY_MESSAGE_ORDER = [
        KDK::Services::RailsWeb # Rails goes on top
      ].freeze

      # Ensure that kdk.yml is valid by default.
      def self.validate_config?
        true
      end

      def initialize(out: Output)
        @out = out
      end

      def run(args = [])
        raise NotImplementedError
      end

      def help
        raise NotImplementedError
      end

      protected

      def config
        KDK.config
      end

      def print_help(args)
        return false unless args.intersect?(['-h', '--help'])

        out.puts(help)

        true
      end

      def display_help_message
        out.divider(length: 55)
        out.puts <<~HELP_MESSAGE
          You can try the following that may be of assistance:

          - Run 'kdk doctor'.

          - Visit the troubleshooting documentation:
            https://github.com/khulnasoft/khulnasoft-development-kit/-/blob/main/doc/troubleshooting/index.md.
          - Visit https://github.com/khulnasoft/khulnasoft-development-kit/-/issues to
            see if there are known issues.

          - Run 'kdk reset-data' if appropriate.
          - Run 'kdk pristine' to reinstall dependencies, remove temporary files, and clear caches.
        HELP_MESSAGE
        out.divider(length: 55)
      end

      def print_ready_message
        notices = ready_messages
        return if notices.empty?

        out.puts
        notices.each { |msg| out.notice(msg) }
      end

      def ready_messages
        services = KDK::Services
          .enabled
          .sort_by { |service| READY_MESSAGE_ORDER.index(service.class) || READY_MESSAGE_ORDER.size }
        notices = services
          .filter_map(&:ready_message)
          .flat_map { |message| message.split("\n") }

        notices << "KhulnaSoft Docs available at #{config.khulnasoft_docs.__uri}." if config.khulnasoft_docs?

        if config.khulnasoft_k8s_agent?
          notices << "KhulnaSoft Agent Server (KAS) available at #{config.khulnasoft_k8s_agent.__url_for_agentk}."
          notices << "Kubernetes proxy (via KAS) available at #{config.khulnasoft_k8s_agent.__k8s_api_url}."
        end

        notices << "Prometheus available at #{config.prometheus.__uri}." if config.prometheus?
        notices << "Grafana available at #{config.grafana.__uri}." if config.grafana?
        notices << "A container registry is available at #{config.registry.__listen}." if config.registry?

        notices
      end

      private

      attr_reader :out
    end
  end
end
