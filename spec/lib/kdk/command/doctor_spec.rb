# frozen_string_literal: true

require 'stringio'

RSpec.describe KDK::Command::Doctor, :hide_output do
  # rubocop:todo RSpec/VerifiedDoubles
  let(:successful_diagnostic) { double(KDK::Diagnostic, success?: true, diagnose: nil, message: nil) }
  let(:failing_diagnostic) { double(KDK::Diagnostic, success?: false, diagnose: 'error', message: 'check failed') }
  let(:shellout) { double(KDK::Shellout, run: nil) }
  # rubocop:enable RSpec/VerifiedDoubles
  let(:diagnostics) { [] }
  let(:warning_message) do
    <<~WARNING
      ================================================================================
      Please note these warning only exist for debugging purposes and can
      help you when you encounter issues with KDK.
      If your KDK is working fine, you can safely ignore them. Thanks!
      ================================================================================
    WARNING
  end

  subject { described_class.new(diagnostics: diagnostics) }

  before do
    allow(Runit).to receive(:start).with('postgresql', quiet: true).and_return(true)
    kdk_root_stub = double('KDK_ROOT') # rubocop:todo RSpec/VerifiedDoubles
    procfile_stub = double('Procfile', exist?: true) # rubocop:todo RSpec/VerifiedDoubles
    allow(KDK).to receive(:root).and_return(kdk_root_stub)
    allow(kdk_root_stub).to receive(:join).with('Procfile').and_return(procfile_stub)
    allow(subject).to receive(:sleep).with(2)
  end

  it 'starts necessary services' do
    expect(Runit).to receive(:start).with('postgresql', quiet: true)
    expect(subject).to receive(:sleep).with(2)

    expect(subject.run).to be(true)
  end

  context 'with passing diagnostics' do
    let(:diagnostics) { [successful_diagnostic, successful_diagnostic] }

    it 'runs all diagnosis' do
      expect(successful_diagnostic).to receive(:success?).twice

      expect(subject.run).to be(true)
    end

    it 'prints KDK is ready.' do
      expect(KDK::Output).to receive(:success).with('Your KDK is healthy.')

      expect(subject.run).to be(true)
    end
  end

  context 'with failing diagnostics' do
    let(:diagnostics) { [failing_diagnostic, failing_diagnostic] }

    it 'runs all diagnosis' do
      expect(failing_diagnostic).to receive(:success?).twice

      expect(subject.run).to be(false)
    end

    it 'prints a warning' do
      expect(KDK::Output).to receive(:puts).with("\n").ordered
      expect(KDK::Output).to receive(:warn).with('Your KDK may need attention.').ordered
      expect(KDK::Output).to receive(:puts).with('check failed').ordered.twice

      expect(subject.run).to be(false)
    end
  end

  context 'with partial failing diagnostics' do
    let(:diagnostics) { [failing_diagnostic, successful_diagnostic, failing_diagnostic] }

    it 'runs all diagnosis' do
      expect(failing_diagnostic).to receive(:success?).twice
      expect(successful_diagnostic).to receive(:success?).once

      expect(subject.run).to be(false)
    end

    it 'prints a message from failed diagnostics' do
      expect(failing_diagnostic).to receive(:message).twice
      expect(KDK::Output).to receive(:puts).with("\n").ordered
      expect(KDK::Output).to receive(:warn).with('Your KDK may need attention.').ordered
      expect(KDK::Output).to receive(:puts).with('check failed').ordered.twice

      expect(subject.run).to be(false)
    end

    it 'does not print a message from successful diagnostics' do
      expect(successful_diagnostic).not_to receive(:message)

      expect(subject.run).to be(false)
    end
  end

  context 'with diagnostic that raises an unexpected error' do
    let(:diagnostics) { [successful_diagnostic, failing_diagnostic] }

    it 'prints a message from failed diagnostics' do
      expect(failing_diagnostic).to receive(:success?).and_raise(StandardError, 'some error occurred')
      expect(KDK::Output).to receive(:puts).with("\n").ordered
      expect(KDK::Output).to receive(:warn).with('Your KDK may need attention.').ordered
      expect(KDK::Output).to receive(:puts).with('check failed').ordered.once
      expect(failing_diagnostic).to receive(:message).with(/some error occurred/).once

      expect(subject.run).to be(2)
    end

    it 'returns code 2' do
      expect(failing_diagnostic).to receive(:success?).and_raise(StandardError, 'some error occurred')

      expect(subject.run).to be(2)
    end
  end
end
