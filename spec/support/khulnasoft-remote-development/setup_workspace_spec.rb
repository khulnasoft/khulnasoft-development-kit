# frozen_string_literal: true

require_relative '../../../support/khulnasoft-remote-development/setup_workspace'

RSpec.describe SetupWorkspace do
  include ShelloutHelper

  let(:hostname) { 'test-hostname' }
  let(:ip_address) { '10.1.2.3' }
  let(:port) { 3000 }

  let(:success) { true }
  let(:duration) { 10 }
  let(:username) { SecureRandom.hex }
  let(:prompt_message) { KDK::Telemetry::PROMPT_TEXT }

  let(:workspace) { described_class.new }
  let(:shellout_double) { kdk_shellout_double(success?: success) }

  before do
    stub_env('SERVICE_PORT_KDK', port)
    stub_env('GL_WORKSPACE_DOMAIN_TEMPLATE', '${PORT}.test.dev')
    allow(Socket).to receive_messages(gethostname: hostname, ip_address_list: [Addrinfo.ip(ip_address)])

    allow(SecureRandom).to receive(:hex).and_return(username)
    allow(Process).to receive(:clock_gettime).and_return(0, duration)

    allow_kdk_shellout_command('support/khulnasoft-remote-development/remote-development-kdk-bootstrap.sh').and_return(shellout_double)
    allow(shellout_double).to receive(:execute).and_return(shellout_double)

    allow(workspace).to receive_messages(execute_bootstrap: [success, duration], allow_sending_telemetry?: true)
    stub_prompt(username, prompt_message)

    allow(KDK.config).to receive(:bury!).with('telemetry.username', username)
    allow(KDK.config).to receive(:bury!).with('telemetry.enabled', true)
    allow(KDK.config).to receive(:save_yaml!)
    allow(KDK::Telemetry).to receive(:send_telemetry)
  end

  describe '#run', :hide_output do
    context "when we're not in a KhulnaSoft Workspace context" do
      it "doesn't run" do
        stub_khulnasoft_workspace_context(false)

        expect(KDK::Output).to receive(:info).with(%(Nothing to do as we're not a KhulnaSoft Workspace.\n\n))

        workspace.run
      end
    end

    context 'when we are in a KhulnaSoft Workspace context' do
      before do
        stub_khulnasoft_workspace_context(true)
      end

      context 'when KDK setup flag file does not exist' do
        before do
          allow(File).to receive(:exist?).and_call_original
          allow(File).to receive(:exist?).with(SetupWorkspace::KDK_SETUP_FLAG_FILE).and_return(false)
          allow(FileUtils).to receive(:mkdir_p)
          allow(FileUtils).to receive(:touch)
        end

        it 'executes the bootstrap script and creates KDK setup flag file' do
          expect(workspace).to receive(:execute_bootstrap)
          expect(FileUtils).to receive(:touch).with(SetupWorkspace::KDK_SETUP_FLAG_FILE)

          workspace.run
        end

        context 'when the bootstrap script fails' do
          let(:success) { false }

          it 'does not create KDK setup flag file' do
            expect(workspace).to receive(:execute_bootstrap)
            expect(FileUtils).not_to receive(:touch).with(SetupWorkspace::KDK_SETUP_FLAG_FILE)

            workspace.run
          end
        end

        context 'when telemetry is allowed' do
          it 'sends telemetry' do
            expect(KDK.config).to receive(:bury!).with('telemetry.username', username)
            expect(KDK.config).to receive(:bury!).with('telemetry.enabled', true)
            expect(workspace).to receive(:send_telemetry).with(success, duration)

            workspace.run
          end
        end

        context 'when telemetry is not allowed' do
          before do
            allow(workspace).to receive(:allow_sending_telemetry?).and_return(false)
            stub_prompt('.', prompt_message)
          end

          it 'does not send telemetry' do
            expect(KDK.config).to receive(:bury!).with('telemetry.username', '')
            expect(KDK.config).to receive(:bury!).with('telemetry.enabled', false)
            expect(workspace).not_to receive(:send_telemetry)

            workspace.run
          end
        end
      end

      context 'when KDK setup flag file exists' do
        before do
          allow(File).to receive(:exist?).with(SetupWorkspace::KDK_SETUP_FLAG_FILE).and_return(true)
        end

        it 'does not execute the bootstrap script and outputs information about KDK is already being bootstrapped' do
          expect(workspace).not_to receive(:execute_bootstrap)
          expect(KDK::Output).to receive(:info).with("#{SetupWorkspace::KDK_SETUP_FLAG_FILE} exists, KDK has already been bootstrapped.\n\nRemove the #{SetupWorkspace::KDK_SETUP_FLAG_FILE} to re-bootstrap.")

          workspace.run
        end
      end
    end
  end

  def stub_khulnasoft_workspace_context(is_a_khulnasoft_workspace)
    allow(ENV).to receive(:key?).and_call_original
    allow(ENV).to receive(:key?).with('GL_WORKSPACE_DOMAIN_TEMPLATE').and_return(is_a_khulnasoft_workspace)

    allow(Dir).to receive(:exist?).and_call_original
    allow(Dir).to receive(:exist?).with(described_class::ROOT_DIR).and_return(is_a_khulnasoft_workspace)
  end
end
