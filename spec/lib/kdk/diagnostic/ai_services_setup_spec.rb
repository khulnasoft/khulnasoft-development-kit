# frozen_string_literal: true

RSpec.describe KDK::Diagnostic::AiServicesSetup do
  include ShelloutHelper

  let(:add_on_purchases) { %w[duo_core duo_enterprise] }
  let(:duo_core_features_available) { true }
  let(:expiration_date) { (Date.today + 1).iso8601 }
  let(:license_detected) { true }
  let(:license_type) { 'online_cloud' }
  let(:number_of_licenses) { 1 }
  let(:plan) { 'ultimate' }
  let(:subscription_name) { 'A-S12345678' }
  let(:license_data) do
    {
      add_on_purchases: add_on_purchases,
      duo_core_features_available: duo_core_features_available,
      expiration_date: expiration_date,
      license_detected: license_detected,
      license_type: license_type,
      number_of_licenses: number_of_licenses,
      plan: plan,
      subscription_name: subscription_name
    }.to_json
  end

  describe 'success?' do
    context 'when ai_services are disabled' do
      before do
        stub_kdk_yaml({
          'ai_services' => {
            'enabled' => false
          }
        })
      end

      it 'returns true and does not validate the license' do
        expect(KDK::Diagnostic::KhulnasoftLicense::AiServicesLicenseValidator).not_to receive(:new)

        expect(subject.success?).to be(true)
      end
    end

    context 'when ai_services are enabled' do
      before do
        stub_kdk_yaml({
          'ai_services' => {
            'enabled' => true
          }
        })
      end

      shared_context 'fetches invalid khulnasoft license' do
        it 'returns false' do
          fetch_khulnasoft_license_shellout = kdk_shellout_double(run: license_data)
          expect_kdk_shellout_command(
            "bin/rails r #{KDK.root.join('lib/support/fetch_khulnasoft_license.rb')}",
            chdir: KDK.config.khulnasoft.dir
          ).and_return(fetch_khulnasoft_license_shellout)

          expect(subject.success?).to be(false)
        end
      end

      context 'when the license is valid' do
        it 'returns true' do
          fetch_khulnasoft_license_shellout = kdk_shellout_double(run: license_data)
          expect_kdk_shellout_command(
            "bin/rails r #{KDK.root.join('lib/support/fetch_khulnasoft_license.rb')}",
            chdir: KDK.config.khulnasoft.dir
          ).and_return(fetch_khulnasoft_license_shellout)

          expect(subject.success?).to be(true)
        end
      end

      context 'when duo enterprise was not purchased' do
        let(:add_on_purchases) { %w[duo_core] }

        include_examples 'fetches invalid khulnasoft license'
      end

      context 'when duo core features are not available' do
        let(:duo_core_features_available) { false }

        include_examples 'fetches invalid khulnasoft license'
      end

      context 'when the license is expired' do
        let(:expiration_date) { (Date.today - 1).iso8601 }

        include_examples 'fetches invalid khulnasoft license'
      end

      context 'when no license is detected' do
        let(:license_detected) { false }

        include_examples 'fetches invalid khulnasoft license'
      end

      context 'when the license_type is legacy' do
        let(:license_type) { 'legacy' }

        include_examples 'fetches invalid khulnasoft license'
      end

      context 'when there are multiple licenses' do
        let(:number_of_licenses) { 2 }

        include_examples 'fetches invalid khulnasoft license'
      end

      context 'when the current plan is not premium or ultimate' do
        let(:plan) { 'starter' }

        include_examples 'fetches invalid khulnasoft license'
      end
    end
  end

  describe '#detail' do
    context 'when ai_services are disabled' do
      before do
        stub_kdk_yaml({
          'ai_services' => {
            'enabled' => false
          }
        })
      end

      it 'returns nil and does not validate the license' do
        expect(KDK::Diagnostic::KhulnasoftLicense::AiServicesLicenseValidator).not_to receive(:new)

        expect(subject.detail).to be_nil
      end
    end

    context 'when ai_services are enabled' do
      before do
        stub_kdk_yaml({
          'ai_services' => {
            'enabled' => true
          }
        })
      end

      shared_examples 'fetches khulnasoft license and provides detailed message' do |message|
        before do
          fetch_khulnasoft_license_shellout = kdk_shellout_double(run: license_data)
          expect_kdk_shellout_command(
            "bin/rails r #{KDK.root.join('lib/support/fetch_khulnasoft_license.rb')}",
            chdir: KDK.config.khulnasoft.dir
          ).and_return(fetch_khulnasoft_license_shellout)
        end

        it 'returns the message' do
          expect(subject.detail).to eq(message)
        end
      end

      context 'when the license is valid' do
        include_examples 'fetches khulnasoft license and provides detailed message', nil
      end

      context 'when duo enterprise was not purchased' do
        let(:add_on_purchases) { %w[duo_core] }

        include_examples 'fetches khulnasoft license and provides detailed message',
          'Your current KhulnaSoft license does not contain the KhulnaSoft Duo Enterprise add-on. We recommend using a KhulnaSoft Ultimate license with the KhulnaSoft Duo Enterprise add-on instead.'
      end

      context 'when duo core features are not available' do
        let(:duo_core_features_available) { false }

        include_examples 'fetches khulnasoft license and provides detailed message',
          'Your current KhulnaSoft license does not contain the KhulnaSoft Duo core add-on. We recommend using a KhulnaSoft Ultimate license instead.'
      end

      context 'when the license is expired' do
        let(:expiration_date) { (Date.today - 1).iso8601 }

        include_examples 'fetches khulnasoft license and provides detailed message',
          'Your current KhulnaSoft license has expired. Please renew it or use an active license.'
      end

      context 'when the license_type is legacy' do
        let(:license_type) { 'legacy' }

        include_examples 'fetches khulnasoft license and provides detailed message',
          'Your current KhulnaSoft license is a legacy license. Please upgrade to a subscription license to use AI features.'
      end

      context 'when there are multiple licenses' do
        let(:number_of_licenses) { 2 }

        include_examples 'fetches khulnasoft license and provides detailed message',
          'We detected more than one KhulnaSoft license. We suggest deleting the license(s) not needed for AI development.'
      end

      context 'when the current plan is not premium or ultimate' do
        let(:plan) { 'starter' }

        include_examples 'fetches khulnasoft license and provides detailed message',
          'Your current KhulnaSoft license is a free license and does not support AI features. We recommend using a KhulnaSoft Ultimate license instead.'
      end

      context 'when license has multiple issues' do
        let(:license_type) { 'legacy' }
        let(:expiration_date) { (Date.today - 1).iso8601 }

        include_examples 'fetches khulnasoft license and provides detailed message', <<~DETAIL
          Your current KhulnaSoft license can't be used for local AI development:

          Your current KhulnaSoft license is a legacy license. Please upgrade to a subscription license to use AI features.
          Your current KhulnaSoft license has expired. Please renew it or use an active license.

          If you are using a staging KhulnaSoft license, you can check the license information for subscription A-S12345678 at https://customers.staging.khulnasoft.com.
        DETAIL
      end
    end
  end
end
