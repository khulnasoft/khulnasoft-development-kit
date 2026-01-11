# frozen_string_literal: true

module KDK
  module Diagnostic
    module KhulnasoftLicense
      class Base
        def initialize(config)
          @config = config
        end

        def success?
          raise NotImplementedError
        end

        def detail
          ''
        end

        private

        def license_data
          @license_data ||= fetch_license_data
        end

        def fetch_license_data
          JSON.parse(KDK::Shellout.new(
            "bin/rails r #{KDK.root.join('lib/support/fetch_khulnasoft_license.rb')}",
            chdir: config.khulnasoft.dir
          ).run)
        rescue StandardError => e
          { 'error' => "Failed to fetch KhulnaSoft license: #{e.message}" }
        end
      end
    end
  end
end
