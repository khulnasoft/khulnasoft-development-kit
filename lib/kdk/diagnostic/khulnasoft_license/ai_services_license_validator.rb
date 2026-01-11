# frozen_string_literal: true

module KDK
  module Diagnostic
    module KhulnasoftLicense
      class AiServicesLicenseValidator < Base
        def success?
          errors.empty?
        end

        def detail
          return if success?
          return errors.first if errors.one?

          <<~MESSAGE
            Your current KhulnaSoft license can't be used for local AI development:

            #{errors.join("\n")}

            If you are using a staging KhulnaSoft license, you can check the license information for subscription #{license_data['subscription_name']} at https://customers.staging.khulnasoft.com.
          MESSAGE
        end

        private

        attr_reader :config

        def errors
          @errors ||= collect_errors
        end

        def collect_errors
          return [license_data['error']] if license_data['error']
          return [no_license_present_message] unless license_data['license_detected']

          issues = []
          issues << 'We detected more than one KhulnaSoft license. We suggest deleting the license(s) not needed for AI development.' if license_data['number_of_licenses'] > 1
          issues << 'Your current KhulnaSoft license is a legacy license. Please upgrade to a subscription license to use AI features.' if license_data['license_type'] == 'legacy'
          issues << 'Your current KhulnaSoft license is a free license and does not support AI features. We recommend using a KhulnaSoft Ultimate license instead.' unless %w[premium ultimate].include?(license_data['plan'])
          issues << 'Your current KhulnaSoft license has expired. Please renew it or use an active license.' if Date.parse(license_data['expiration_date']) < Date.today
          issues << 'Your current KhulnaSoft license does not contain the KhulnaSoft Duo core add-on. We recommend using a KhulnaSoft Ultimate license instead.' unless license_data['duo_core_features_available']
          issues << 'Your current KhulnaSoft license does not contain the KhulnaSoft Duo Enterprise add-on. We recommend using a KhulnaSoft Ultimate license with the KhulnaSoft Duo Enterprise add-on instead.' unless license_data['add_on_purchases']&.include?('duo_enterprise')

          issues
        end

        def no_license_present_message
          'No KhulnaSoft license detected. AI features require a KhulnaSoft Ultimate or Premium license with the KhulnaSoft Duo Enterprise add-on.'
        end
      end
    end
  end
end
