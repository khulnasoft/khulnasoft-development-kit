# frozen_string_literal: true

require 'spec_helper'

RSpec.describe KDK::Services::DuoWorkflowService do
  let(:config) { KDK.config }

  describe '#name' do
    it 'returns duo-workflow-service' do
      expect(subject.name).to eq('duo-workflow-service')
    end
  end

  describe '#command' do
    it 'returns the necessary command to run Duo Workflow Service' do
      expect(subject.command).to eq('support/exec-cd khulnasoft-ai-gateway poetry run duo-workflow-service')
    end
  end

  describe '#enabled?' do
    it 'is disabled by default' do
      expect(subject.enabled?).to be(false)
    end
  end

  describe '#ready_message' do
    it 'returns the default ready message' do
      expect(subject.ready_message).to eq('Duo Workflow Service is available at 127.0.0.1:50052')
    end
  end
end
