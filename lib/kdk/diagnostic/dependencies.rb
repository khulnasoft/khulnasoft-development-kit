# frozen_string_literal: true

module KDK
  module Diagnostic
    class Dependencies < Base
      TITLE = 'KDK Dependencies'

      def success?
        checker.error_messages.empty?
      end

      def detail
        return if success?

        messages = checker.error_messages.join("\n").chomp

        <<~MESSAGE
          #{messages}

          For details on how to install, please visit:

          https://github.com/khulnasoft/khulnasoft-development-kit/blob/main/doc/index.md
        MESSAGE
      end

      private

      def checker
        @checker ||= KDK::Dependencies::Checker.new.tap(&:check_all)
      end
    end
  end
end
