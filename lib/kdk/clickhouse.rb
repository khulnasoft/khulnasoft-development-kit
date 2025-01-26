# frozen_string_literal: true

module KDK
  # Provides ClickHouse utility methods
  class Clickhouse
    def client_cmd(args = [])
      config = KDK.config.clickhouse

      cmd = [config.bin.to_s]
      cmd << 'client'
      cmd << "--port=#{config.tcp_port}"
      (cmd + args).flatten
    end
  end
end
