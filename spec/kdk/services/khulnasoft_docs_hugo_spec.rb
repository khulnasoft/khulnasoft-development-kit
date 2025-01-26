# frozen_string_literal: true

RSpec.describe KDK::Services::KhulnasoftDocsHugo do
  describe '#name' do
    it 'returns khulnasoft-docs-hugo' do
      expect(subject.name).to eq('khulnasoft-docs-hugo')
    end
  end

  describe '#command' do
    it 'returns non-TLS command if HTTPS is not set' do
      expect(subject.command).to eq("support/exec-cd khulnasoft-docs-hugo hugo serve --cleanDestinationDir --baseURL http://127.0.0.1 --port 1313 --bind 127.0.0.1")
    end

    context 'when HTTPS is enabled' do
      before do
        config = {
          'https' => {
            'enabled' => true
          }
        }

        stub_kdk_yaml(config)
      end

      it 'returns TLS-enabled command' do
        expect(subject.command).to eq("support/exec-cd khulnasoft-docs-hugo hugo serve --cleanDestinationDir --baseURL https://127.0.0.1 --port 1313 --bind 127.0.0.1 --tlsAuto")
      end
    end
  end

  describe '#enabled?' do
    it 'returns true if set `enabled: true` in the config file' do
      config = {
        'khulnasoft_docs_hugo' => {
          'enabled' => true
        }
      }

      stub_kdk_yaml(config)

      expect(subject.enabled?).to be(true)
    end

    it 'returns false if set `enabled: false` in the config file' do
      config = {
        'khulnasoft_docs_hugo' => {
          'enabled' => false
        }
      }

      stub_kdk_yaml(config)

      expect(subject.enabled?).to be(false)
    end
  end
end
