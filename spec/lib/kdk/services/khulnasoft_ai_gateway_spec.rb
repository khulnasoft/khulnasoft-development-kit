# frozen_string_literal: true

RSpec.describe KDK::Services::KhulnasoftAiGateway do
  describe '#name' do
    it 'returns khulnasoft-ai-gateway' do
      expect(subject.name).to eq('khulnasoft-ai-gateway')
    end
  end

  describe '#command' do
    it 'returns the necessary command to run khulnasoft-ai-gateway' do
      expect(subject.command).to eq('support/exec-cd khulnasoft-ai-gateway poetry run ai_gateway')
    end
  end

  describe '#enabled?' do
    it 'is disabled by default' do
      expect(subject.enabled?).to be(false)
    end
  end

  describe '#ready_message' do
    subject { super().ready_message }

    describe 'available at' do
      it { is_expected.to include('KhulnaSoft AI Gateway is available at http://127.0.0.1:5052/docs') }
    end
  end
end
