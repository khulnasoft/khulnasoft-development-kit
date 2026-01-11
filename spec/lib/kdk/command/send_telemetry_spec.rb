# frozen_string_literal: true

require 'spec_helper'

RSpec.describe KDK::Command::SendTelemetry do
  subject(:command) { described_class.new }

  let(:metric) { 'rspec_setup_duration' }
  let(:value) { '12.3' }

  before do
    allow(KDK::Output).to receive(:puts)
    allow(KDK::Output).to receive(:warn)
    allow(KDK::Telemetry).to receive(:send_custom_event)
  end

  describe '#run' do
    it 'sends telemetry when metric and value are given' do
      result = command.run([metric, value])

      expect(KDK::Telemetry).to have_received(:send_custom_event).with(metric, value, extras: {})
      expect(result).to be(true)
    end

    it 'sends telemetry with extras when extra arguments are given' do
      result = command.run([metric, value, '--extra=foo:bar', '--extra=bar:baz'])

      expect(KDK::Telemetry).to have_received(:send_custom_event).with(metric, value, extras: { 'foo' => 'bar', 'bar' => 'baz' })
      expect(result).to be(true)
    end

    it 'warns and ignores invalid extra arguments' do
      result = command.run([metric, value, '--extra=invalid', '--extra=foo:bar'])

      expect(KDK::Telemetry).to have_received(:send_custom_event).with(metric, value, extras: { 'foo' => 'bar' })
      expect(KDK::Output).to have_received(:warn).with('Invalid --extra format: --extra=invalid')
      expect(result).to be(true)
    end

    it 'raises UserInteractionRequired when arguments are missing' do
      expect { command.run([]) }.to raise_error(KDK::UserInteractionRequired, 'Usage: kdk send-telemetry <metric> <value>')
    end

    it 'raises UserInteractionRequired when only metric is given' do
      expect { command.run([metric]) }.to raise_error(KDK::UserInteractionRequired, 'Usage: kdk send-telemetry <metric> <value>')
    end
  end
end
