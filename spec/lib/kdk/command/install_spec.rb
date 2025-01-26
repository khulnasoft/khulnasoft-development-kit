# frozen_string_literal: true

RSpec.describe KDK::Command::Install do
  include ShelloutHelper

  let(:args) { [] }

  before do
    allow(KDK).to receive(:make).with('install', *args).and_return(sh)
  end

  context 'when install fails' do
    let(:sh) { kdk_shellout_double(success?: false, stderr_str: nil) }

    it 'returns an error message' do
      expect { subject.run(args) }.to output(/Failed to install/).to_stderr.and output(/You can try the following that may be of assistance/).to_stdout
    end

    it 'does not render announcements', :hide_output do
      expect_any_instance_of(KDK::Announcements).not_to receive(:render_all)

      subject.run(args)
    end
  end

  context 'when install succeeds' do
    let(:sh) { kdk_shellout_double(success?: true) }

    it 'finishes without problem' do
      expect { subject.run(args) }.not_to raise_error
    end

    it 'renders announcements' do
      expect_any_instance_of(KDK::Announcements).to receive(:cache_all)

      subject.run(args)
    end
  end

  describe 'telemetry' do
    let(:sh) { kdk_shellout_double(success?: true) }

    context 'with telemetry_user set' do
      let(:args) { %w[telemetry_user=alice] }

      it 'updates telemetry with passed name' do
        expect(KDK::Telemetry).to receive(:update_settings).with('alice')

        subject.run(args)
      end
    end

    context 'with empty telemetry_user' do
      let(:args) { %w[telemetry_user=] }

      it 'updates telemetry with empty name' do
        expect(KDK::Telemetry).to receive(:update_settings).with('')

        subject.run(args)
      end
    end

    context 'without telemetry_user argument' do
      let(:args) { [] }

      it 'does not update telemetry settings' do
        expect(KDK::Telemetry).not_to receive(:update_settings)

        subject.run(args)
      end
    end
  end
end
