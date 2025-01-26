# frozen_string_literal: true

RSpec.describe KDK::Command::Telemetry do
  subject(:run) { described_class.new.run([]) }

  before do
    stub_kdk_yaml({})
  end

  it 'asks for a username and prints a message' do
    expect($stdin).to receive(:gets).and_return('.')
    expect(KDK::Telemetry).to receive(:update_settings).with('.')

    expect { run }.to output("#{KDK::Telemetry::PROMPT_TEXT}Error tracking and analytic data will not be collected.\n").to_stdout
  end

  context 'when the user interrupts the prompt' do
    it 'prints that the previous behavior is kept' do
      expect($stdin).to receive(:gets).and_raise(Interrupt)
      expect(KDK::Telemetry).not_to receive(:update_settings)
      expect { run }.to output("#{KDK::Telemetry::PROMPT_TEXT}\nKeeping previous behavior: Error tracking and analytic data will not be collected.\n").to_stdout
    end
  end
end
