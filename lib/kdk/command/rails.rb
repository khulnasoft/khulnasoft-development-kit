# frozen_string_literal: true

module KDK
  module Command
    # Handles `kdk rails <command> [<args>]` command execution
    class Rails < BaseCommand
      help '<command> [<args>]', 'Execute <command> with Rails command'

      def run(args = [])
        KDK::Output.abort('Usage: kdk rails <command> [<args>]', report_error: false) if args.empty?

        execute_command!(args)
      end

      private

      def execute_command!(args)
        exec(
          KDK.config.env,
          *generate_command(args)
        )
      end

      def generate_command(args)
        %w[support/tool-version-manager-exec khulnasoft bundle exec bin/rails] + args
      end
    end
  end
end
