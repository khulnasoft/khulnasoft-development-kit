# frozen_string_literal: true

module KDK
  module Diagnostic
    # This checks if ValKey is used instead of Redis and warns users.
    # See https://github.com/khulnasoft/khulnasoft-development-kit/-/issues/2820.
    class Valkey < Base
      TITLE = 'Valkey'

      def success?
        !valkey_used?
      end

      def detail
        return if success?

        valkey_used_warning_message
      end

      private

      def valkey_used?
        Shellout.new('redis-server --version').run.include?('Valkey server') ||
          Shellout.new('redis-cli --version').run.include?('valkey-cli')
      end

      def valkey_used_warning_message
        <<~WARNING
          KDK detected the use of Valkey instead of Redis.
          This may not be compatible with Redis and cause issues.

          See https://github.com/khulnasoft/khulnasoft-development-kit/-/issues/2820 for more information.
        WARNING
      end
    end
  end
end
