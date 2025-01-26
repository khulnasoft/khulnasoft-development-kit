# frozen_string_literal: true

RSpec.describe KDK::Command::Version do
  include ShelloutHelper

  describe '#run' do
    it 'returns KhulnaSoft Development Kit 0.2.12 (abc123)' do
      stub_const('KDK::VERSION', 'KhulnaSoft Development Kit 0.2.12')
      shellout_double = kdk_shellout_double(run: 'abc123')
      allow_kdk_shellout_command('git rev-parse --short HEAD', chdir: KDK.root).and_return(shellout_double)

      expect { subject.run }.to output("KhulnaSoft Development Kit 0.2.12 (abc123)\n").to_stdout
    end
  end
end
