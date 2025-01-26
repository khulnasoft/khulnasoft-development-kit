# frozen_string_literal: true

RSpec.describe KDK::Clickhouse do
  describe '#client_cmd' do
    let(:config) do
      {
        'clickhouse' => {
          'bin' => '/tmp/clickhouse123',
          'tcp_port' => 9898
        }
      }
    end

    before do
      stub_kdk_yaml(config)
    end

    it 'specifies clickhouse client command based on configured bin path' do
      expect(subject.client_cmd).to include('/tmp/clickhouse123', 'client')
    end

    it 'includes --port flag pointing to configured flag' do
      expect(subject.client_cmd).to include('--port=9898')
    end
  end
end
