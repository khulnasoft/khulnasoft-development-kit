# frozen_string_literal: true

require 'spec_helper'

RSpec.describe KDK::Services::Prometheus do
  describe '#name' do
    it 'returns corrent name' do
      expect(subject.name).to eq('prometheus')
    end
  end

  describe '#enabled?' do
    it 'is disabled by default' do
      expect(subject.enabled?).to be(false)
    end
  end

  describe '#ready_message' do
    it 'returns the default ready message' do
      expect(subject.ready_message).to eq('Prometheus available at http://127.0.0.1:9090')
    end
  end
end
