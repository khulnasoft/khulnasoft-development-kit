# frozen_string_literal: true

RSpec.describe KDK::Diagnostic::AiGateway do
  include ShelloutHelper

  subject(:diagnostic) { described_class.new }

  def stub_ai_gateway_url(url)
    postgresql_double = instance_double(KDK::Postgresql)
    allow(KDK::Postgresql).to receive(:new).and_return(postgresql_double)
    allow(postgresql_double).to receive(:psql_cmd).and_return(%w[psql command])

    shellout_double = kdk_shellout_double(success?: true, read_stdout: url)
    allow(KDK::Shellout).to receive(:new).with(%w[psql command]).and_return(shellout_double)
    allow(shellout_double).to receive(:execute).with(display_output: false).and_return(shellout_double)
  end

  before do
    allow(KDK.config).to receive_message_chain(:khulnasoft_ai_gateway, :enabled).and_return(true)
  end

  describe '#success?' do
    context 'when AI Gateway is not enabled' do
      before do
        allow(KDK.config).to receive_message_chain(:khulnasoft_ai_gateway, :enabled).and_return(false)
      end

      it 'returns true' do
        expect(diagnostic.success?).to be true
      end
    end

    context 'when AI Gateway URL is not set' do
      before do
        stub_ai_gateway_url('')
      end

      it 'returns true' do
        expect(diagnostic.success?).to be true
      end
    end

    context 'when URL is local' do
      before do
        stub_ai_gateway_url('http://localhost:5052')
      end

      it 'returns true' do
        expect(diagnostic.success?).to be true
      end
    end

    context 'when URL is staging' do
      before do
        stub_ai_gateway_url('https://cloud.staging.khulnasoft.com')
      end

      it 'returns false' do
        expect(diagnostic.success?).to be false
      end
    end
  end

  describe '#detail' do
    context 'when AI Gateway is not enabled' do
      before do
        allow(KDK.config).to receive_message_chain(:khulnasoft_ai_gateway, :enabled).and_return(false)
      end

      it 'returns nil' do
        expect(diagnostic.detail).to be_nil
      end
    end

    context 'when AI Gateway URL is not set' do
      before do
        stub_ai_gateway_url('')
      end

      it 'returns nil' do
        expect(diagnostic.detail).to be_nil
      end
    end

    context 'when URL is local' do
      before do
        stub_ai_gateway_url('http://localhost:5052')
      end

      it 'returns nil' do
        expect(diagnostic.detail).to be_nil
      end
    end

    context 'when URL is staging' do
      before do
        stub_ai_gateway_url('https://cloud.staging.khulnasoft.com')
      end

      it 'returns warning message' do
        detail = diagnostic.detail

        expect(detail).to include('Self-Hosted AI Gateway URL is set to staging (https://cloud.staging.khulnasoft.com) in the database.')
      end
    end
  end

  describe '#correct!' do
    before do
      allow(KDK.config).to receive_messages(bury!: true, save_yaml!: true)
    end

    context 'when AI Gateway URL is not set' do
      before do
        stub_ai_gateway_url('')
      end

      it 'returns false' do
        expect(diagnostic.correct!).to be false
      end
    end

    context 'when URL is local' do
      before do
        stub_ai_gateway_url('http://localhost:5052')
      end

      it 'returns false' do
        expect(diagnostic.correct!).to be false
      end
    end

    context 'when URL is staging' do
      before do
        stub_ai_gateway_url('https://cloud.staging.khulnasoft.com')
      end

      it 'switches to staging environment' do
        expect(KDK.config).to receive(:bury!).with('khulnasoft_ai_gateway.environment', 'staging')
        expect(KDK.config).to receive(:save_yaml!).and_return(true)

        expect(diagnostic.correct!).to be_truthy
      end

      it 'clears AI Gateway URL before switching environment' do
        expect(diagnostic).to receive(:clear_ai_gateway_url).ordered
        expect(KDK.config).to receive(:bury!).ordered

        expect(diagnostic.correct!).to be_truthy
      end

      context 'when clearing AI Gateway URL' do
        before do
          allow(diagnostic).to receive(:using_staging_url?).and_return(true)
        end

        it 'executes UPDATE command to clear the URL from database' do
          postgresql_double = instance_double(KDK::Postgresql)
          allow(KDK::Postgresql).to receive(:new).and_return(postgresql_double)
          expect(postgresql_double).to receive(:psql_cmd).with(['--no-align', '--tuples-only', '--command', 'UPDATE ai_settings SET ai_gateway_url = NULL'], database: 'khulnasofthq_development').and_return(%w[psql update command])

          update_shellout = kdk_shellout_double(success?: true)
          expect(KDK::Shellout).to receive(:new).with(%w[psql update command]).and_return(update_shellout)
          expect(update_shellout).to receive(:execute).with(display_output: false).and_return(update_shellout)

          diagnostic.correct!
        end
      end
    end
  end

  describe '#fetch_url_from_database' do
    context 'when database query succeeds' do
      before do
        stub_ai_gateway_url('http://localhost:5052')
      end

      it 'returns the URL' do
        expect(diagnostic.send(:fetch_url_from_database)).to eq('http://localhost:5052')
      end
    end

    context 'when database query returns empty string' do
      before do
        stub_ai_gateway_url('')
      end

      it 'returns nil' do
        expect(diagnostic.send(:fetch_url_from_database)).to be_nil
      end
    end

    context 'when database query fails' do
      before do
        postgresql_double = instance_double(KDK::Postgresql)
        allow(KDK::Postgresql).to receive(:new).and_return(postgresql_double)
        allow(postgresql_double).to receive(:psql_cmd).and_return(%w[psql command])

        shellout_double = kdk_shellout_double(success?: false)
        allow(KDK::Shellout).to receive(:new).with(%w[psql command]).and_return(shellout_double)
        allow(shellout_double).to receive(:execute).with(display_output: false).and_return(shellout_double)
      end

      it 'returns nil' do
        expect(diagnostic.send(:fetch_url_from_database)).to be_nil
      end
    end
  end
end
