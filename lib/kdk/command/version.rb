# frozen_string_literal: true

module KDK
  module Command
    # Handles `kdk version` command execution
    class Version < BaseCommand
      # Allow invalid kdk.yml.
      def self.validate_config?
        false
      end

      def run(_ = [])
        KDK::Output.puts("#{KDK::VERSION} (#{git_revision})")

        true
      end

      private

      def git_revision
        Shellout.new('git rev-parse --short HEAD', chdir: KDK.root).run
      end
    end
  end
end
