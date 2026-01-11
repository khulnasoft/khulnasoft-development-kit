# frozen_string_literal: true

module KDK
  module Diagnostic
    class AiServicesSetup < Base
      TITLE = 'AI services setup'

      def success?
        return true unless ai_services_enabled?

        khulnasoft_license_diagnostic.success?
      end

      def detail
        return if success?

        khulnasoft_license_diagnostic.detail
      end

      private

      def khulnasoft_license_diagnostic
        @khulnasoft_license_diagnostic ||= KhulnasoftLicense::AiServicesLicenseValidator.new(config)
      end

      def ai_services_enabled?
        KDK.config.ai_services.enabled?
      end
    end
  end
end
