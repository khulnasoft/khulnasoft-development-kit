# frozen_string_literal: true

module KDK
  module Command
    # Executes bundled psql command with any provided extra arguments
    class Psql < BaseCommand
      help '[-d khulnasofthq_development]', 'Run Postgres console'

      def run(args = [])
        exec(*KDK::Postgresql.new.psql_cmd(args), chdir: KDK.root)
      end
    end
  end
end
