# frozen_string_literal: true

RSpec.describe KDK::Diagnostic::Hostname do
  subject(:diagnostic) { described_class.new }

  describe '#success?' do
    subject { diagnostic.success? }

    context 'the IP is part of the resolved IPs v4' do
      before do
        stub_universe(%w[::1 127.0.0.1], 'localhost', '127.0.0.1')
      end

      it { is_expected.to be true }
    end

    context 'with invalid IP' do
      before do
        stub_universe(%w[], 'localhost', 'foo')
      end

      it { is_expected.to be false }
    end

    context 'when hosts contains multiple entry for hostname' do
      context 'for ipv4' do
        before do
          stub_universe(%w[::1 127.0.0.1 127.0.0.2], 'localhost', '127.0.0.1')
        end

        it { is_expected.to be false }
      end

      context 'for ipv6' do
        before do
          stub_universe(%w[::1 ::2 127.0.0.1], 'localhost', '::1')
        end

        it { is_expected.to be false }
      end
    end

    context 'the IP is part of the resolved IPs v6' do
      before do
        stub_universe(%w[::1 127.0.0.1], 'localhost', '::1')
      end

      it { is_expected.to be true }
    end

    context 'the IP is not part of the resolved IPs' do
      before do
        stub_universe(%w[::1 127.0.0.1], 'kdk.test', '192.168.1.1')
      end

      it { is_expected.to be false }
    end

    context 'the hostname does not resolve to an IP' do
      before do
        stub_universe([], 'kdk.test', '127.0.0.1')
      end

      it { is_expected.to be false }
    end

    context 'the hostname is an IP itself' do
      before do
        stub_universe(%w[127.0.0.1], '127.0.0.1', '127.0.0.1')
      end

      it { is_expected.to be true }
    end
  end

  describe '#detail' do
    subject { diagnostic.detail }

    context 'if successful' do
      before do
        stub_universe(%w[127.0.0.1], '127.0.0.1', '127.0.0.1')
      end

      it { is_expected.to be_nil }
    end

    context 'if no hosts found' do
      before do
        stub_universe(%w[], 'kdk.test', '127.0.0.1')
      end

      it { is_expected.to match 'Could not resolve IP address for the KDK hostname' }
    end

    context 'if IPs do not match' do
      context 'for ipv4' do
        before do
          stub_universe(%w[127.0.0.1 ::1], 'kdk.test', '192.168.12.1')
        end

        it { is_expected.to match 'You should make sure that the two match.' }
      end

      context 'for ipv6' do
        before do
          stub_universe(%w[127.0.0.1 ::1], 'kdk.test', '::2')
        end

        it { is_expected.to match 'You should make sure that the two match.' }
      end
    end

    context 'with invalid IP' do
      before do
        stub_universe(%w[], 'localhost', 'foo')
      end

      it { is_expected.to match 'Provided `listen_address` `foo` is invalid.' }
    end
  end

  def stub_universe(resolved_ips, hostname, listen_address)
    allow_any_instance_of(Resolv).to receive(:getaddresses).and_return(resolved_ips)
    allow_any_instance_of(KDK::Config).to receive(:hostname).and_return(hostname)
    allow_any_instance_of(KDK::Config).to receive(:listen_address).and_return(listen_address)
  end
end
