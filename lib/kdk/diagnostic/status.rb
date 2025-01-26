# frozen_string_literal: true

module KDK
  module Diagnostic
    class Status < Base
      TITLE = 'KDK Status'

      def success?
        down_services.empty?
      end

      def detail
        return if success?

        <<~MESSAGE
          The following services are not running but should be:

          #{down_services.join("\n")}
        MESSAGE
      end

      private

      def kdk_status_command
        @kdk_status_command ||= Shellout.new('kdk status').execute(display_output: false, display_error: false)
      end

      def down_services
        @down_services ||= kdk_status_command.read_stdout.split("\n").grep(/\Adown: .+, want up;.+\z/)
      end
    end
  end
end
