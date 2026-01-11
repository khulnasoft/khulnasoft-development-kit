# frozen_string_literal: true

RSpec.describe KDK::DuoConnector do
  let(:khulnasoft_chat_completions_url) { 'https://khulnasoft.com/api/v4/chat/completions' }
  let(:prompt) { 'Explain how to resolve the following diagnostics found by my local KDK:' }
  let(:issues) { ['Your KhulnaSoft log directory is 2700MB. Try to truncate it.'] }
  let(:out) { KDK::Output }

  subject { described_class.new(out).call(prompt, issues) }

  before do
    stub_env('KHULNASOFT_AUTH_TOKEN', khulnasoft_auth_token)
  end

  describe 'call' do
    let(:khulnasoft_auth_token) { '<your-khulnasoft-auth-token>' }
    let(:content) { "Try this.\n" }
    let(:mock_api_response) { content }

    context 'when asking KhulnaSoft Duo for help' do
      before do
        stub_request(:post, khulnasoft_chat_completions_url).to_return(body: mock_api_response.to_json)
      end

      it 'returns a helpful message' do
        expect(KDK::Output).to receive(:puts).with(content)
        expect(KDK::Output).to receive(:puts)

        subject
      end

      context 'when issue message is too long' do
        let(:issues) { ['A' * 1001] }

        it 'reports the issue to be too long for KhulnaSoft Duo' do
          expect(KDK::Output).to receive(:puts).with(
            "This issue is too long to be reported to KhulnaSoft Duo: #{issues.first[0, 50]}"
          )

          subject
        end
      end
    end

    context 'when no Auth token is provided' do
      let(:khulnasoft_auth_token) { '' }

      it 'indicates the missing auth token' do
        expect(KDK::Output).to receive(:warn).with('AI assistance for troubleshooting is missing the KhulnaSoft auth token.')
        expect(KDK::Output).to receive(:info).with("Set one of the following environment variables: #{described_class::AUTH_TOKEN_ENV_VARS.join(', ')}")
        expect(KDK::Output).to receive(:info).with('Example: export KHULNASOFT_TOKEN=<your-khulnasoft-auth-token>')

        subject
      end
    end

    context 'when request returns an error' do
      before do
        stub_request(:post, khulnasoft_chat_completions_url).to_return(body: { 'error' => 'Something went wrong.' }.to_json)
      end

      it 'indicates the error' do
        expect { subject }.to raise_error(KDK::DuoConnector::DuoConnectorError)
      end
    end

    context 'when request returns a non-200 status code' do
      before do
        stub_request(:post, khulnasoft_chat_completions_url).to_return(
          status: 401,
          body: { 'error' => 'Unauthorized' }.to_json
        )
      end

      it 'raises an error with the status code and message' do
        expect { subject }.to raise_error(
          KDK::DuoConnector::DuoConnectorError,
          /KhulnaSoft Duo API request failed with status 401.*Unauthorized/
        )
      end
    end

    context 'when request returns a non-200 status code with non-JSON body' do
      before do
        stub_request(:post, khulnasoft_chat_completions_url).to_return(
          status: 500,
          body: 'Internal Server Error'
        )
      end

      it 'raises an error with the status code and raw body' do
        expect { subject }.to raise_error(
          KDK::DuoConnector::DuoConnectorError,
          /KhulnaSoft Duo API request failed with status 500.*Internal Server Error/
        )
      end
    end

    context 'when using alternative auth token environment variables' do
      let(:khulnasoft_auth_token) { '' }

      context 'with KHULNASOFT_TOKEN' do
        before do
          stub_env('KHULNASOFT_TOKEN', 'khulnasoft-token-value')
          stub_request(:post, khulnasoft_chat_completions_url).to_return(body: content.to_json)
        end

        it 'uses KHULNASOFT_TOKEN for authentication' do
          expect(KDK::Output).to receive(:puts).with(content)
          expect(KDK::Output).to receive(:puts)

          subject
        end
      end

      context 'with KHULNASOFT_API_PRIVATE_TOKEN' do
        before do
          stub_env('KHULNASOFT_API_PRIVATE_TOKEN', 'api-private-token-value')
          stub_request(:post, khulnasoft_chat_completions_url).to_return(body: content.to_json)
        end

        it 'uses KHULNASOFT_API_PRIVATE_TOKEN for authentication' do
          expect(KDK::Output).to receive(:puts).with(content)
          expect(KDK::Output).to receive(:puts)

          subject
        end
      end

      context 'when KHULNASOFT_AUTH_TOKEN takes precedence' do
        before do
          stub_env('KHULNASOFT_AUTH_TOKEN', 'auth-token-value')
          stub_env('KHULNASOFT_TOKEN', 'khulnasoft-token-value')
          stub_request(:post, khulnasoft_chat_completions_url).to_return(body: content.to_json)
        end

        it 'uses KHULNASOFT_AUTH_TOKEN over other tokens' do
          expect(KDK::Output).to receive(:puts).with(content)
          expect(KDK::Output).to receive(:puts)

          subject
        end
      end
    end
  end
end
