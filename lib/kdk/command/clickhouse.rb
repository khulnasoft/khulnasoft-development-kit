# frozen_string_literal: true

module KDK
  module Command
    # Executes clickhouse client command with configured connection paras and any provided extra arguments
    class Clickhouse < BaseCommand
      def run(args = [])
        unless KDK.config.clickhouse.enabled?
          KDK::Output.error('ClickHouse is not enabled. Please check your kdk.yml configuration.')

          exit(-1)
        end

        exec(*KDK::Clickhouse.new.client_cmd(args), chdir: KDK.root)
      end
    end
  end
end
