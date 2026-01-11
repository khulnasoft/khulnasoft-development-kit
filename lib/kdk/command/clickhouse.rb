# frozen_string_literal: true

module KDK
  module Command
    # Executes clickhouse client command with configured connection paras and any provided extra arguments
    class Clickhouse < BaseCommand
      def run(args = [])
        unless KDK.config.clickhouse.enabled?
          raise UserInteractionRequired.new(
            'ClickHouse is not enabled.'
          )
        end

        exec(*command(args), chdir: KDK.root)
      end

      private

      def command(args = [])
        clickhouse = config.clickhouse

        base = %W[#{clickhouse.bin} client --port=#{clickhouse.tcp_port}]
        (base + args).flatten
      end
    end
  end
end
