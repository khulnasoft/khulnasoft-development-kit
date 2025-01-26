# frozen_string_literal: true

module KDK
  module Diagnostic
    class MissingBinaries < Base
      TITLE = 'Missing Binaries'

      def success?
        missing_binaries.empty?
      end

      def detail
        return if success?

        setup_commands = {
          gitaly: 'make gitaly-setup',
          khulnasoft_shell: 'make khulnasoft-shell-setup',
          workhorse: 'make khulnasoft-workhorse-setup'
        }

        instructions = missing_binaries.filter_map { |binary| setup_commands[binary] }

        <<~MESSAGE
          The following binaries are missing from their expected paths:
            #{missing_binaries.join("\n  ")}

          Please ensure you download them by running:
            #{instructions.join("\n  ")}
        MESSAGE
      end

      private

      def required_binaries
        KDK::PackageConfig::PROJECTS.keys
      end

      def missing_binaries
        @missing_binaries ||= required_binaries.reject { |binary| binary_exists?(binary) }
      end

      def binary_exists?(binary)
        binary_config = KDK::PackageConfig.project(binary)
        binary_path = binary_config[:download_path]

        return true if binary == :graphql_schema

        if binary == :workhorse
          # Check if any file starting with 'khulnasoft-' exists and is executable
          Dir.glob(File.join(binary_path, 'khulnasoft-*')).any? do |file|
            File.exist?(file) && File.executable?(file)
          end
        else
          File.exist?(binary_path) && File.executable?(binary_path)
        end
      end
    end
  end
end
