# frozen_string_literal: true

RSpec.describe KDK::Command::Removed do
  subject(:command) { removed_command_class.new }

  let(:removed_command_class) { described_class.new('Use Y instead.') }

  describe '#run' do
    it 'shows removed warning and message info' do
      expect(KDK::Output).to receive(:warn).with('This command was removed!')
      expect(KDK::Output).to receive(:info).with('Use Y instead.')

      expect(command.run).to be(false)
    end
  end
end
