# frozen_string_literal: true

module KDK
  module Diagnostic
    class MissingBinaries < Base
      TITLE = 'Missing Binaries'

      def success?
        missing_khulnasoft_binaries.empty? && missing_external_binaries.empty?
      end

      def detail
        return if success?

        message = []

        unless missing_khulnasoft_binaries.empty?
          setup_commands = {
            gitaly: 'make gitaly-setup',
            khulnasoft_shell: 'make khulnasoft-shell-setup',
            workhorse: 'make khulnasoft-workhorse-setup'
          }

          instructions = missing_khulnasoft_binaries.filter_map { |binary| setup_commands[binary] }

          message << <<~MESSAGE
            The following KhulnaSoft binaries are missing from their expected paths:
              #{missing_khulnasoft_binaries.join("\n  ")}

            Please ensure you download them by running:
              #{instructions.join("\n  ")}
          MESSAGE
        end

        unless missing_external_binaries.empty?
          message << <<~MESSAGE
            The following external binaries are missing from their expected paths:
              #{missing_external_binaries.join("\n  ")}

            Please ensure these are installed on your system by running:
              kdk update
          MESSAGE
        end

        message.join("\n")
      end

      private

      def required_khulnasoft_binaries
        projects = KDK::PackageConfig::PROJECTS.keys
        projects -= %i[openbao] unless config.openbao.enabled?
        projects
      end

      def missing_khulnasoft_binaries
        @missing_khulnasoft_binaries ||= required_khulnasoft_binaries.reject { |binary| khulnasoft_binary_exists?(binary) }
      end

      def missing_external_binaries
        @missing_external_binaries ||= begin
          missing = []

          missing << 'git' if config.git.bin && !executable_exists?(config.git.bin)
          missing << 'nginx' if config.nginx.bin && !executable_exists?(config.nginx.bin)
          missing << 'sshd' if config.sshd.bin && !executable_exists?(config.sshd.bin)

          postgres_path = if config.postgresql.bin
                            config.postgresql.bin
                          elsif config.postgresql.bin_dir
                            File.join(config.postgresql.bin_dir, 'postgres')
                          end

          missing << 'postgresql' if postgres_path && !executable_exists?(postgres_path)

          missing
        end
      end

      def khulnasoft_binary_exists?(binary)
        binary_config = KDK::PackageConfig.project(binary)
        binary_paths = binary_config[:download_paths]

        return true if binary == :graphql_schema

        if binary == :workhorse
          # Check if any file starting with 'khulnasoft-' exists and is executable in any of the paths
          binary_paths.any? do |path|
            Dir.glob(File.join(path, 'khulnasoft-*')).any? { |file| executable_exists?(file) }
          end
        else
          binary_paths.all? { |path| executable_exists?(path) }
        end
      end

      def executable_exists?(path)
        File.exist?(path) && File.executable?(path)
      end
    end
  end
end
