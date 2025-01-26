# frozen_string_literal: true

require 'fileutils'
require 'khulnasoft-sdk'
require 'sentry-ruby'
require 'snowplow-tracker'

# rubocop:disable RSpec/ExpectInHook
RSpec.describe KDK::Telemetry, :with_telemetry do
  include ShelloutHelper

  let(:git_email) { 'cool-contributor@gmail.com' }

  before do
    sh = kdk_shellout_double(run: git_email)
    allow_kdk_shellout_command(%w[git config --get user.email], chdir: KDK.config.kdk_root).and_return(sh)
  end

  describe '.with_telemetry' do
    let(:command) { 'test_command' }
    let(:args) { %w[arg1 arg2] }
    let(:telemetry_enabled) { true }
    let(:asdf?) { true }
    let(:mise?) { false }

    let(:client) { double('Client') } # rubocop:todo RSpec/VerifiedDoubles

    before do
      expect(described_class).to receive_messages(telemetry_enabled?: telemetry_enabled)
      expect(described_class).to receive(:with_telemetry).and_call_original

      allow(KDK).to receive_message_chain(:config, :telemetry, :username).and_return('testuser')
      allow(KDK).to receive_message_chain(:config, :telemetry, :environment).and_return('native')
      allow(KDK).to receive_message_chain(:config, :asdf, :opt_out?).and_return(!asdf?)
      allow(KDK).to receive_message_chain(:config, :mise, :enabled?).and_return(mise?)
      allow(described_class).to receive_messages(client: client)

      stub_const('ARGV', args)
    end

    context 'when telemetry is not enabled' do
      let(:telemetry_enabled) { false }

      it 'does not track telemetry and directly yields the block' do
        expect { |b| described_class.with_telemetry(command, &b) }.to yield_control
      end
    end

    it 'tracks the finish of the command' do
      expect(client).to receive(:identify).with('testuser')
      expect(client).to receive(:track).with(a_string_starting_with('Finish'), hash_including(:duration, :environment, :platform, :architecture, :version_manager, :team_member))

      described_class.with_telemetry(command) { true }
    end

    context 'when the block returns false' do
      it 'tracks the failure of the command' do
        expect(client).to receive(:identify).with('testuser')
        expect(client).to receive(:track).with(a_string_starting_with('Failed'), hash_including(:duration, :environment, :platform, :architecture, :version_manager, :team_member))

        described_class.with_telemetry(command) { false }
      end
    end

    describe 'payload' do
      let(:payload) do
        payload = nil
        allow(client).to receive(:identify).with('testuser')
        allow(client).to receive(:track) do |_, received|
          payload = received
          nil
        end

        described_class.with_telemetry(command) { false }

        payload
      end

      describe 'version_manager' do
        it { expect(payload[:version_manager]).to eq('asdf') }

        context 'when opting out of asdf' do
          let(:asdf?) { false }

          it { expect(payload[:version_manager]).to eq('none') }
        end

        context 'when mise is enabled' do
          let(:asdf?) { false }
          let(:mise?) { true }

          it { expect(payload[:version_manager]).to eq('mise') }
        end
      end
    end
  end

  describe '.client' do
    before do
      described_class.instance_variable_set(:@client, nil)

      stub_env('KHULNASOFT_SDK_APP_ID', 'app_id')
      stub_env('KHULNASOFT_SDK_HOST', 'https://collector')

      allow(KhulnasoftSDK::Client).to receive_messages(new: mocked_client)
    end

    after do
      described_class.instance_variable_set(:@client, nil)
    end

    let(:mocked_client) { instance_double(KhulnasoftSDK::Client) }

    it 'initializes the khulnasoft sdk client with the correct configuration' do
      expect(SnowplowTracker::LOGGER).to receive(:level=).with(Logger::WARN)
      expect(KhulnasoftSDK::Client).to receive(:new).with(app_id: 'app_id', host: 'https://collector').and_return(mocked_client)

      described_class.client
    end

    context 'when client is already initialized' do
      before do
        described_class.instance_variable_set(:@client, mocked_client)
      end

      it 'returns the existing client without reinitializing' do
        expect(KhulnasoftSDK::Client).not_to receive(:new)
        expect(described_class.client).to eq(mocked_client)
      end
    end
  end

  describe '.init_sentry' do
    let(:config) { instance_double(Sentry::Configuration) }

    it 'initializes the sentry client with expected values' do
      allow(Sentry).to receive(:init).and_yield(config)
      allow(Sentry).to receive(:set_user)
      allow(KDK).to receive_message_chain(:config, :telemetry, :username).and_return('testuser')

      expect(config).to receive(:dsn=).with('https://4e771163209528e15a6a66a6e674ddc3@new-sentry.khulnasoft.net/38')
      expect(config).to receive(:breadcrumbs_logger=).with([:sentry_logger])
      expect(config).to receive(:traces_sample_rate=).with(1.0)
      expect(config).to receive_message_chain(:logger, :level=).with(Logger::WARN)
      expect(config).to receive(:before_send=).with(kind_of(Proc))
      expect(Sentry).to receive(:set_user).with({ username: 'testuser' })

      described_class.init_sentry
    end
  end

  describe '.telemetry_enabled?' do
    [true, false].each do |value|
      context "when #{value}" do
        it "returns #{value}" do
          expect(KDK).to receive_message_chain(:config, :telemetry, :enabled).and_return(value)

          expect(described_class.telemetry_enabled?).to eq(value)
        end
      end
    end
  end

  describe '.team_member?' do
    it { expect(described_class.team_member?).to be(false) }

    context 'when using an @khulnasoft.com email in Git' do
      let(:git_email) { 'tanuki@khulnasoft.com' }

      it { expect(described_class.team_member?).to be(true) }
    end
  end

  describe '.update_settings' do
    before do
      expect(KDK.config).to receive(:save_yaml!)
    end

    context 'when username is not .' do
      let(:username) { 'testuser' }

      it 'updates the settings with the provided username and enables telemetry' do
        expect(KDK.config).to receive(:bury!).with('telemetry.enabled', true)
        expect(KDK.config).to receive(:bury!).with('telemetry.username', username)

        described_class.update_settings(username)
      end
    end

    context 'when username is .' do
      let(:username) { '.' }

      it 'updates the settings with an empty username and disables telemetry' do
        expect(KDK.config).to receive(:bury!).with('telemetry.enabled', false)
        expect(KDK.config).to receive(:bury!).with('telemetry.username', '')

        described_class.update_settings(username)
      end
    end

    context 'when username is empty' do
      let(:username) { '' }
      let(:set_username) { SecureRandom.hex }

      before do
        allow(SecureRandom).to receive(:hex).and_return(set_username)
      end

      it 'updates the settings with an generated username and enables telemetry' do
        expect(KDK.config).to receive(:bury!).with('telemetry.enabled', true)
        expect(KDK.config).to receive(:bury!).with('telemetry.username', set_username)

        described_class.update_settings(username)
      end
    end
  end

  describe '.capture_exception' do
    let(:telemetry_enabled) { true }

    before do
      KDK.config.bury!('telemetry.enabled', telemetry_enabled)

      allow(described_class).to receive(:init_sentry)
      allow(Sentry).to receive(:capture_exception)
    end

    context 'when telemetry is not enabled' do
      let(:telemetry_enabled) { false }

      it 'does not capture the exception' do
        described_class.capture_exception('Test error')

        expect(Sentry).not_to have_received(:capture_exception)
      end
    end

    context 'when given an exception' do
      let(:raised) do
        raise 'boom'
      rescue RuntimeError => e
        e.freeze
      end

      it 'captures the given exception' do
        described_class.capture_exception(raised)

        expect(Sentry).to have_received(:capture_exception) do |exception, options|
          expect(exception).to be_a(RuntimeError)
          expect(exception.message).to eq(raised.message)
          expect(exception.backtrace.first).not_to include(__FILE__)
          expect(options[:extra]).to include(:environment, :platform, :architecture, :version_manager, :team_member)
        end
      end
    end

    context 'when given a string' do
      let(:message) { 'Test error message' }

      it 'captures a new exception with the given message' do
        described_class.capture_exception(message)

        expect(Sentry).to have_received(:capture_exception) do |exception, options|
          expect(exception).to be_a(StandardError)
          expect(exception.message).to eq(message)
          expect(exception.backtrace.first).not_to include(__FILE__)
          expect(options[:extra]).to include(:environment, :platform, :architecture, :version_manager, :team_member)
        end
      end
    end
  end
end
# rubocop:enable RSpec/ExpectInHook
