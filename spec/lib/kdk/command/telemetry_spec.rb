# frozen_string_literal: true

RSpec.describe KDK::Command::Telemetry do
  subject(:run) { described_class.new.run([]) }

  let(:team_member) { false }

  before do
    stub_kdk_yaml({})
    allow(KDK::Telemetry).to receive(:team_member?).and_return(team_member)
  end

  context 'when user chooses to disable telemetry' do
    it 'disables telemetry and inform the user' do
      expect($stdin).to receive(:gets).and_return('n')
      expect(KDK::Telemetry).to receive(:update_settings).with('n')

      expect do
        run
      end.to output("#{KDK::Telemetry::PROMPT_TEXT}Telemetry is disabled. No data will be collected.\n").to_stdout
    end
  end

  context 'when user interrupts the prompt' do
    it 'keeps the previous telemetry setting and inform the user' do
      expect($stdin).to receive(:gets).and_raise(Interrupt)
      expect(KDK::Telemetry).not_to receive(:update_settings)

      expect do
        run
      end.to output("#{KDK::Telemetry::PROMPT_TEXT}\nKeeping previous behavior: Telemetry is disabled. No data will be collected.\n").to_stdout
    end
  end

  context 'when the user is a team member' do
    let(:team_member) { true }

    it 'tells them that telemetry is always enabled' do
      expect { run }.to output(/KDK has detected that you are a KhulnaSoft team member\..+Telemetry is always enabled for team members\./m).to_stdout
    end
  end
end
