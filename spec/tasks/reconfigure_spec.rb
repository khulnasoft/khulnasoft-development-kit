# frozen_string_literal: true

RSpec.describe 'rake reconfigure:provision_license' do
  let(:kdk_licensing) { instance_double(KDK::Licensing) }

  before(:all) do
    # Load the main Rakefile first to get spinner_task and other DSL methods
    load File.expand_path('../../Rakefile', __dir__)
    Rake.application.rake_require('tasks/reconfigure')
  end

  before do
    allow(KDK::Licensing).to receive(:new).and_return(kdk_licensing)
    allow(kdk_licensing).to receive(:activate)

    Rake::Task['reconfigure:provision_license'].reenable
  end

  context 'when license_provisioning is enabled' do
    before do
      stub_kdk_yaml({
        'kdk' => {
          'license_provisioning' => {
            'enabled' => true
          }
        }
      })
    end

    context 'when user is a team_member' do
      before do
        allow(KDK::Telemetry).to receive(:team_member?).and_return(true)
      end

      it 'provisions the desired license' do
        expect(kdk_licensing).to receive(:activate)

        Rake::Task['reconfigure:provision_license'].invoke
      end
    end

    context 'when user is not a team_member' do
      before do
        allow(KDK::Telemetry).to receive(:team_member?).and_return(false)
      end

      it 'skips the license provisioning' do
        expect(kdk_licensing).not_to receive(:activate)

        Rake::Task['reconfigure:provision_license'].invoke
      end
    end
  end

  context 'when license_provisioning is disabled' do
    before do
      stub_kdk_yaml({
        'kdk' => {
          'license_provisioning' => {
            'enabled' => false
          }
        }
      })

      allow(KDK::Telemetry).to receive(:team_member?).and_return(true)
    end

    it 'skips the license provisioning' do
      expect(kdk_licensing).not_to receive(:activate)

      Rake::Task['reconfigure:provision_license'].invoke
    end
  end
end
