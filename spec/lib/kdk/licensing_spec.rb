# frozen_string_literal: true

RSpec.describe KDK::Licensing do
  include ShelloutHelper

  # Default configuration values
  let(:license_expiration_date) { (Date.today + 180).iso8601 } # 6 months from now
  let(:license_edition) { 'self_managed' }
  let(:khulnasoft_license_tier) { 'ultimate' }
  let(:khulnasoft_config_tier) { 'ultimate' }
  let(:duo_license_tier) { '' }
  let(:license_file_path) { KDK.root.join('.khulnasoft_license') }
  let(:vault_activation_code) { 'ACTIVATION_CODE_FROM_VAULT' }
  let(:vault_expiration_date) { (Time.now + (365 * 24 * 60 * 60)).to_i.to_s } # 1 year from now

  before do
    stub_kdk_yaml({
      'kdk' => {
        'license_provisioning' => {
          'enabled' => true,
          'khulnasoft' => {
            'tier' => khulnasoft_config_tier
          },
          'duo' => {
            'tier' => duo_license_tier
          }
        }
      },
      'khulnasoft' => {
        'dir' => '/home/git/kdk/khulnasoft'
      }
    })

    allow(KDK).to receive(:root).and_return(Pathname.new('/home/git/kdk'))
    allow(File).to receive(:exist?).and_call_original
    allow(File).to receive(:write)
    allow(File).to receive(:read).and_call_original
  end

  describe '#initialize' do
    subject { described_class.new }

    it 'sets instance variables from config' do
      expect(subject.instance_variable_get(:@license_edition)).to eq(license_edition)
      expect(subject.instance_variable_get(:@khulnasoft_license_type)).to eq(khulnasoft_license_tier)
      expect(subject.instance_variable_get(:@duo_license_type)).to eq(duo_license_tier)
    end
  end

  describe '#activate' do
    subject(:activate) { described_class.new.activate }

    let(:new_license_json) do
      {
        activation_code: vault_activation_code,
        expiration_date: Time.at(vault_expiration_date.to_i).to_datetime.to_date.iso8601,
        edition: license_edition,
        khulnasoft_tier: khulnasoft_config_tier,
        duo_tier: duo_license_tier
      }
    end

    before do
      allow(File).to receive(:exist?).with(license_file_path).and_return(license_present)
    end

    shared_examples 'creates new license file with correct tier' do
      it 'creates new license file with correct tier' do
        expect(KDK::Output).to receive(:puts).with('Creating or updating the local KhulnaSoft license')

        activation_code_shellout = kdk_shellout_double(run: vault_activation_code)
        expiration_date_shellout = kdk_shellout_double(run: vault_expiration_date)

        vault_base_path = if duo_license_tier.empty?
                            "op read 'op://Engineering/KhulnaSoft_#{license_edition}_#{khulnasoft_config_tier}"
                          else
                            "op read 'op://Engineering/KhulnaSoft_#{license_edition}_#{khulnasoft_config_tier}_Duo_#{duo_license_tier}"
                          end

        expect_kdk_shellout_command("#{vault_base_path}/activation_code'").and_return(activation_code_shellout)
        expect_kdk_shellout_command("#{vault_base_path}/expiration_date'").and_return(expiration_date_shellout)

        expect(File).to receive(:write).with(license_file_path, new_license_json.to_json)
        expect(KDK::Output).to receive(:puts).with("Successfully updated the local KhulnaSoft license: #{license_file_path}")

        # Mock KhulnaSoft license activation
        activate_shellout = kdk_shellout_double(run: 'success')
        expect_kdk_shellout_command(
          "bin/rails r #{KDK.root.join('lib/support/activate_khulnasoft_license.rb')} #{license_file_path}",
          chdir: KDK.config.khulnasoft.dir
        ).and_return(activate_shellout)

        subject
      end
    end

    context 'when no local license file exists' do
      let(:license_present) { false }

      include_examples 'creates new license file with correct tier'

      context 'with Duo license tier configured' do
        let(:duo_license_tier) { 'pro' }

        include_examples 'creates new license file with correct tier'
      end

      context 'when license activation fails' do
        it 'raises an LicensingActivationError' do
          expect(KDK::Output).to receive(:puts).with('Creating or updating the local KhulnaSoft license')

          activation_code_shellout = kdk_shellout_double(run: vault_activation_code)
          expiration_date_shellout = kdk_shellout_double(run: vault_expiration_date)

          vault_base_path = "op read 'op://Engineering/KhulnaSoft_#{license_edition}_#{khulnasoft_config_tier}"

          expect_kdk_shellout_command("#{vault_base_path}/activation_code'").and_return(activation_code_shellout)
          expect_kdk_shellout_command("#{vault_base_path}/expiration_date'").and_return(expiration_date_shellout)

          expect(File).to receive(:write).with(license_file_path, new_license_json.to_json)
          expect(KDK::Output).to receive(:puts).with("Successfully updated the local KhulnaSoft license: #{license_file_path}")

          # Mock KhulnaSoft license activation
          activate_shellout = kdk_shellout_double(run: 'Error: Failed to activate KhulnaSoft license: Test error')
          expect_kdk_shellout_command(
            "bin/rails r #{KDK.root.join('lib/support/activate_khulnasoft_license.rb')} #{license_file_path}",
            chdir: KDK.config.khulnasoft.dir
          ).and_return(activate_shellout)

          expect { subject }.to raise_error(KDK::Licensing::LicensingActivationError, 'Error: Failed to activate KhulnaSoft license: Test error')
        end
      end
    end

    context 'when a local license file exists' do
      let(:license_present) { true }
      let(:existing_license_json) do
        {
          activation_code: 'OLD_ACTIVATION_CODE',
          expiration_date: license_expiration_date,
          edition: license_edition,
          khulnasoft_tier: khulnasoft_license_tier,
          duo_tier: duo_license_tier
        }
      end

      before do
        allow(File).to receive(:read).with(license_file_path).and_return(existing_license_json.to_json)
      end

      context 'when local license matches configuration' do
        it 'skips license creation but still activates' do
          expect(File).not_to receive(:write)
          expect(KDK::Output).to receive(:puts).with("Matching KhulnaSoft license file found: #{license_file_path}")

          # Mock KhulnaSoft license activation
          activate_shellout = kdk_shellout_double(run: 'success')
          expect_kdk_shellout_command(
            "bin/rails r #{KDK.root.join('lib/support/activate_khulnasoft_license.rb')} #{license_file_path}",
            chdir: KDK.config.khulnasoft.dir
          ).and_return(activate_shellout)

          subject
        end
      end

      context 'when local license is expired' do
        let(:license_expiration_date) { (Date.today - 1).iso8601 } # yesterday

        include_examples 'creates new license file with correct tier'
      end

      context 'when license tier does not match' do
        let(:khulnasoft_license_tier) { 'premium' }

        include_examples 'creates new license file with correct tier'
      end
    end
  end
end
