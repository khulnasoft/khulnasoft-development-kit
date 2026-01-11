# frozen_string_literal: true

require 'spec_helper'

RSpec.describe KDK::Diagnostic::Valkey do
  include ShelloutHelper

  before do
    redis_server_shellout = kdk_shellout_double(run: redis_server_version)
    expect_kdk_shellout_command('redis-server --version').and_return(redis_server_shellout)
  end

  subject(:diagnostic) { described_class.new }

  context 'when Redis is used' do
    let(:redis_server_version) { 'Redis server v=7.0.14 sha=00000000:0 malloc=libc bits=64 build=2f8db2e78a6df983' }
    let(:redis_cli_version) { 'redis-cli 7.0.14' }

    before do
      redis_cli_shellout = kdk_shellout_double(run: redis_cli_version)
      expect_kdk_shellout_command('redis-cli --version').and_return(redis_cli_shellout)
    end

    describe '#success?' do
      it { expect(diagnostic.success?).to be(true) }
    end

    describe '#detail' do
      it { expect(diagnostic.detail).to be_nil }
    end
  end

  context 'when Valkey server is used' do
    let(:redis_server_version) { 'Valkey server v=8.0.3 sha=00000000:0 malloc=jemalloc-5.3.0 bits=64 build=e80802904a2640cb' }

    describe '#success?' do
      it 'returns false' do
        expect(diagnostic.success?).to be(false)
      end
    end

    describe '#detail' do
      it 'returns a warning message' do
        expect(diagnostic.detail).to eq <<~WARNING
          KDK detected the use of Valkey instead of Redis.
          This may not be compatible with Redis and cause issues.

          See https://github.com/khulnasoft/khulnasoft-development-kit/-/issues/2820 for more information.
        WARNING
      end
    end
  end

  context 'when Valkey CLI is used' do
    let(:redis_server_version) { 'Redis server v=7.0.14 sha=00000000:0 malloc=libc bits=64 build=2f8db2e78a6df983' }
    let(:redis_cli_version) { 'valkey-cli 7.0.14' }

    before do
      redis_cli_shellout = kdk_shellout_double(run: redis_cli_version)
      expect_kdk_shellout_command('redis-cli --version').and_return(redis_cli_shellout)
    end

    describe '#success?' do
      it 'returns false' do
        expect(diagnostic.success?).to be(false)
      end
    end

    describe '#detail' do
      it 'returns a warning message' do
        expect(diagnostic.detail).to eq <<~WARNING
          KDK detected the use of Valkey instead of Redis.
          This may not be compatible with Redis and cause issues.

          See https://github.com/khulnasoft/khulnasoft-development-kit/-/issues/2820 for more information.
        WARNING
      end
    end
  end

  context 'when Redis versions are empty' do
    let(:redis_server_version) { '' }
    let(:redis_cli_version) { '' }

    before do
      redis_cli_shellout = kdk_shellout_double(run: redis_cli_version)
      expect_kdk_shellout_command('redis-cli --version').and_return(redis_cli_shellout)
    end

    describe '#success?' do
      it 'returns true' do
        expect(diagnostic.success?).to be(true)
      end
    end

    describe '#detail' do
      it 'returns nil' do
        expect(diagnostic.detail).to be_nil
      end
    end
  end
end
