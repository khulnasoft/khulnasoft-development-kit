# frozen_string_literal: true

require 'spec_helper'

RSpec.describe KDK::ToolVersionsUpdater do
  subject(:updater) { described_class.new }

  describe '.enabled_services' do
    subject(:enabled_services) { described_class.enabled_services }

    it { is_expected.to include('rails-web') }

    it 'returns a dup each time' do
      expect(enabled_services.object_id).not_to eq(described_class.enabled_services.object_id)
    end
  end

  describe '#run' do
    let(:khulnasoft_branch) { 'master' }
    let(:khulnasoft_shell_version) { 'v1.0.0' }
    let(:gitaly_version) { 'a' * 40 }
    let(:khulnasoft_url) { "https://github.com/khulnasoft/khulnasoft/-/raw/#{khulnasoft_branch}/.tool-versions" }
    let(:khulnasoft_shell_url) { "https://github.com/khulnasoft/khulnasoft-shell/-/raw/#{khulnasoft_shell_version}/.tool-versions" }
    let(:gitaly_url) { "https://gitlab.com/gitlab-org/gitaly/-/raw/#{gitaly_version}/.tool-versions" }

    before do
      allow(KDK.config).to receive_message_chain(:khulnasoft, :default_branch).and_return(khulnasoft_branch)
      allow(KDK.config).to receive_message_chain(:khulnasoft_shell, :__version).and_return(khulnasoft_shell_version)
      allow(KDK.config).to receive_message_chain(:gitaly, :__version).and_return(gitaly_version)

      allow(described_class).to receive(:enabled_services).and_return(%w[gitaly])

      allow(updater).to receive(:git_fetch_version_files)
      allow(updater).to receive(:install_tools)
      allow(updater).to receive(:cleanup)

      allow(updater).to receive(:http_get).with(khulnasoft_url).and_return("nodejs 22.12.0\nruby 3.3.7 3.2.4\nrust 1.73.0")
      allow(updater).to receive(:http_get).with(khulnasoft_shell_url).and_return("ruby 3.3.0\ngolang 1.24.1")
      allow(updater).to receive(:http_get).with(gitaly_url).and_return("# Tool versions used by Gitaly\ngolang 1.23.6\nruby 3.3.7")

      allow(updater).to receive(:root_tool_versions).and_return([
        ['markdownlint-cli2', '0.17.1'],
        ['vale', '3.9.3']
      ])

      allow(KDK::Output).to receive(:info)
      allow(KDK::Output).to receive(:debug)
      allow(KDK::Output).to receive(:success)

      stub_const('KDK::ToolVersionsUpdater::MINIMUM_MISE_VERSION', '2019.0.0')
    end

    context 'when mise is enabled' do
      before do
        allow(KDK).to receive_message_chain(:config, :mise, :enabled?).and_return(true)
        allow(KDK).to receive_message_chain(:config, :asdf, :opt_out?).and_return(true)
        allow(KDK::Dependencies).to receive(:tool_version_manager_available?).and_return(true)
        allow(updater).to receive(:expected_mise_version).and_return('2025.8.4')
      end

      it 'writes correct tool versions to combined file and sets mise env vars' do
        expected_content = <<~CONTENT
          golang 1.23.6 1.24.1
          ruby 3.3.7 3.2.4 3.3.0
          nodejs 22.12.0
          rust 1.73.0
          markdownlint-cli2 0.17.1
          vale 3.9.3
        CONTENT

        expect(File).to receive(:write).with(described_class::COMBINED_TOOL_VERSIONS_FILE, expected_content)

        updater.run

        expect(ENV.fetch('MISE_OVERRIDE_TOOL_VERSIONS_FILENAMES')).to eq(described_class::COMBINED_TOOL_VERSIONS_FILE)
        expect(ENV.fetch('MISE_RUST_VERSION')).to eq('1.73.0')
        expect(ENV.fetch('RUST_WITHOUT')).to eq('rust-docs')
      end

      context 'when mise is at expected version' do
        before do
          stub_mise_version("{\"version\":\"2025.8.8 macos-arm64 (2025-08-11)\"}")
        end

        it 'skips mise update' do
          expect(KDK::Shellout).not_to receive(:new).with(%w[mise self-update -y])

          updater.run
        end
      end

      context 'when mise needs update' do
        before do
          stub_mise_version("{\"version\":\"2025.6.8 macos-arm64 (2025-06-11)\"}")
        end

        it 'updates mise using self-update' do
          update_shellout = instance_double(KDK::Shellout)
          allow(update_shellout).to receive_messages(execute: update_shellout, success?: true)

          expect(KDK::Shellout).to receive(:new).with(%w[mise self-update -y]).and_return(update_shellout)
          updater.run
        end

        context 'when self-update fails on macOS' do
          before do
            allow(KDK::Machine).to receive_messages(macos?: true, linux?: false)
          end

          it 'falls back to brew update' do
            self_update_shellout = instance_double(KDK::Shellout)
            brew_update_shellout = instance_double(KDK::Shellout)

            allow(self_update_shellout).to receive_messages(execute: self_update_shellout, success?: false)
            allow(brew_update_shellout).to receive_messages(execute: brew_update_shellout, success?: true)

            expect(KDK::Shellout).to receive(:new).with(%w[mise self-update -y]).and_return(self_update_shellout)
            expect(KDK::Shellout).to receive(:new).with('brew update && brew upgrade mise').and_return(brew_update_shellout)

            updater.run
          end
        end

        context 'when self-update fails on Linux' do
          before do
            allow(KDK::Machine).to receive_messages(macos?: false, linux?: true)
          end

          it 'falls back to apt update' do
            self_update_shellout = instance_double(KDK::Shellout)
            apt_update_shellout = instance_double(KDK::Shellout)

            allow(self_update_shellout).to receive_messages(execute: self_update_shellout, success?: false)
            allow(apt_update_shellout).to receive_messages(execute: apt_update_shellout, success?: true)

            expect(KDK::Shellout).to receive(:new).with(%w[mise self-update -y]).and_return(self_update_shellout)
            expect(KDK::Shellout).to receive(:new).with('apt update && apt upgrade mise').and_return(apt_update_shellout)

            updater.run
          end
        end

        context 'when all update methods fail' do
          it 'logs unsuccessful update message' do
            self_update_shellout = instance_double(KDK::Shellout)
            system_update_shellout = instance_double(KDK::Shellout)

            allow(self_update_shellout).to receive_messages(execute: self_update_shellout, success?: false)
            allow(system_update_shellout).to receive_messages(execute: system_update_shellout, success?: false)

            allow(KDK::Shellout).to receive(:new).with(%w[mise self-update -y]).and_return(self_update_shellout)
            allow(KDK::Shellout).to receive(:new).with('brew update && brew upgrade mise').and_return(system_update_shellout)
            allow(KDK::Shellout).to receive(:new).with('apt update && apt upgrade mise').and_return(system_update_shellout)

            expect(KDK::Output).to receive(:info).with("mise update unsuccessful. Please manually update mise to the latest version")

            updater.run
          end
        end
      end

      context 'when mise version has invalid format' do
        before do
          stub_mise_version("{\"version\":\"invalid-version-format\"}")
        end

        it 'handles ArgumentError and skips update' do
          expect(KDK::Shellout).not_to receive(:new).with(%w[mise self-update -y])
          expect(KDK::Output).to receive(:info).with("mise is already at version invalid-version-format, skipping update")

          updater.run
        end
      end

      context 'when mise version command fails' do
        before do
          allow(KDK::Shellout).to receive(:new).with(%w[mise version --json]).and_raise(Errno::ENOENT)
        end

        it 'handles missing mise gracefully' do
          expect { updater.run }.not_to raise_error
        end
      end

      context 'when mise version output is invalid JSON' do
        let(:mise_version_output) { 'invalid json' }

        it 'handles JSON parse errors gracefully' do
          expect { updater.run }.not_to raise_error
        end
      end

      context 'when mise version is below minimum required version' do
        before do
          stub_const('KDK::ToolVersionsUpdater::MINIMUM_MISE_VERSION', '2025.1.1')
          stub_mise_version("{\"version\":\"2024.8.4 macos-arm64 (2024-08-11)\"}")
          allow(updater).to receive(:update_mise!)
        end

        it 'raises UserInteractionRequired error' do
          expect { updater.run }.to raise_error(KDK::UserInteractionRequired, /You're running an old version of mise/)
        end
      end
    end

    context 'when should_update? returns false' do
      before do
        allow(updater).to receive(:should_update?).and_return(false)
      end

      it 'skips the update and returns a message' do
        expect(updater).to receive(:skip_message)
        expect(updater).not_to receive(:collect_tool_versions)

        updater.run
      end
    end
  end

  describe '#default_version_for' do
    context 'when a .tool-versions file is in the root directory' do
      it 'returns postgres version 16.11' do
        expect(subject.default_version_for('postgres')).to eq('16.11')
      end
    end

    context 'when a .tool-versions file is one level deep' do
      let(:first_level_file) { KDK.root.join('level1/.tool-versions') }

      before do
        allow(KDK.root).to receive(:glob).with('{.tool-versions,{*,*/*}/.tool-versions}').and_return([first_level_file])
        allow(File).to receive(:readlines).with(first_level_file).and_return(['gitleaks 8.18.2'])
      end

      it 'retrieves the correct version' do
        expect(subject.default_version_for('gitleaks')).to eq('8.18.2')
      end
    end

    context 'when a .tool-versions file is more than one level deep' do
      let(:second_level_file) { KDK.root.join('level1/level2/.tool-versions') }

      before do
        allow(KDK.root).to receive(:glob).with('{.tool-versions,{*,*/*}/.tool-versions}').and_return([])
        allow(File).to receive(:readlines).with(second_level_file).and_return(['nonexistent 1.2.3'])
      end

      it 'does not retrieve versions' do
        expect(subject.default_version_for('nonexistent')).to be_nil
      end
    end
  end

  def stub_mise_version(version_output)
    shellout_double = instance_double(KDK::Shellout)
    allow(KDK::Shellout).to receive(:new).with(%w[mise version --json]).and_return(shellout_double)
    allow(shellout_double).to receive(:execute).with(display_output: false).and_return(shellout_double)
    allow(shellout_double).to receive(:read_stdout).and_return(version_output)
  end
end
