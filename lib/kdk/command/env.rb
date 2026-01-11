# frozen_string_literal: true

require 'shellwords'

module KDK
  module Command
    class Env < BaseCommand
      help 'Print environment variables for the current project'

      def help
        <<~HELP
          Usage: kdk env [<command>]

            -h, --help  Display help

          When run without arguments, prints the environment variables for the
          current project in a format suitable for shell evaluation.

          When run with a command, executes the command with the project-specific
          environment variables set.

          Supported projects:
            gitaly  Sets PGHOST and PGPORT for PostgreSQL access
        HELP
      end

      def run(args = [])
        return true if print_help(args)

        if args.empty?
          print_env

          return true
        end

        exec(env, *args, chdir: KDK.pwd)
      end

      private

      def print_env
        env.each do |k, v|
          puts "export #{Shellwords.shellescape(k)}=#{Shellwords.shellescape(v)}"
        end
      end

      def env
        case get_project
        when 'gitaly'
          {
            'PGHOST' => config.postgresql.dir.to_s,
            'PGPORT' => config.postgresql.port.to_s
          }
        else
          {}
        end
      end

      def get_project
        relative_path = Pathname.new(KDK.pwd).relative_path_from(KDK.root).to_s
        relative_path.split('/').first
      end
    end
  end
end
