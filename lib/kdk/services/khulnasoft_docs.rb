# frozen_string_literal: true

module KDK
  module Services
    class KhulnasoftDocs < Base
      def name
        'khulnasoft-docs'
      end

      def enabled?
        config.khulnasoft_docs.enabled?
      end

      def command
        %(support/khulnasoft-docs/start-nanoc)
      end
    end
  end
end
