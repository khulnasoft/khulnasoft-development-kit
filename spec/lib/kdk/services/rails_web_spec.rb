# frozen_string_literal: true

require 'spec_helper'

RSpec.describe KDK::Services::RailsWeb do
  let(:config) do
    {
      'hostname' => 'kdk.example.com',
      'https' => { 'enabled' => false }
    }
  end

  before do
    stub_kdk_yaml(config)
  end

  describe '#name' do
    it 'return rails-background-web' do
      expect(subject.name).to eq('rails-web')
    end
  end

  describe '#command' do
    it 'returns the necessary command to run KhulnaSoft Rails' do
      expect(subject.command).to eq(%(support/exec-cd khulnasoft bin/web start_foreground))
    end
  end

  describe '#enabled?' do
    it 'is enabled by default' do
      expect(subject).to be_enabled
    end
  end

  describe '#ready_message' do
    subject { super().ready_message }

    describe 'available at' do
      it { is_expected.to include('KhulnaSoft available at http://kdk.example.com:3000') }

      context 'with protocol' do
        before do
          config['https']['enabled'] = true
        end

        it { is_expected.to include('KhulnaSoft available at https://kdk.example.com:3000') }
      end

      context 'with overridden protocol' do
        before do
          config['khulnasoft'] = { 'rails' => { 'https' => { 'enabled' => true } } }
        end

        it { is_expected.to include('KhulnaSoft available at https://kdk.example.com:3000') }
      end

      context 'with hostname' do
        before do
          config['hostname'] = 'rails.example.com'
        end

        it { is_expected.to include('KhulnaSoft available at http://rails.example.com:3000') }
      end

      context 'with overridden hostname' do
        before do
          config['khulnasoft'] = { 'rails' => { 'hostname' => 'rails.example.com' } }
        end

        it { is_expected.to include('KhulnaSoft available at http://rails.example.com:3000') }
      end

      context 'with port' do
        before do
          config['port'] = 80
        end

        it { is_expected.to include('KhulnaSoft available at http://kdk.example.com') }
      end

      context 'with overridden port' do
        before do
          config['khulnasoft'] = { 'rails' => { 'port' => 80 } }
        end

        it { is_expected.to include('KhulnaSoft available at http://kdk.example.com') }
      end

      context 'with relative_url_root' do
        before do
          config['relative_url_root'] = '/foo/'
        end

        it { is_expected.to include('KhulnaSoft available at http://kdk.example.com:3000/foo') }
      end
    end
  end
end
