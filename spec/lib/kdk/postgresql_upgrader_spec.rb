# frozen_string_literal: true

require 'kdk/postgresql_upgrader'

RSpec.describe KDK::PostgresqlUpgrader do
  include ShelloutHelper

  let(:target_version) { 16 }

  subject { described_class.new(target_version) }

  describe '#initialize' do
    it 'initializes with a target version' do
      expect(subject.instance_variable_get(:@target_version)).to eq(target_version)
    end
  end

  describe '#upgrade!' do
    before do
      allow(subject).to receive_messages(
        upgrade_needed?: true,
        current_version: 14,
        kdk_stop: true,
        init_db_in_target_path: true,
        rename_current_data_dir: true,
        pg_upgrade: true,
        promote_new_db: true,
        kdk_reconfigure: true,
        pg_replica_upgrade: true,
        rename_current_data_dir_back: true
      )
    end

    context 'with mise' do
      let(:versions) { %w[13.12 13.9 14.8 14.9 15.1 15.2 15.3 16.1 16.8 16.11] }
      let(:result) do
        versions.map do |version|
          {
            version: version,
            requested_version: version,
            install_path: "/home/.local/share/mise/installs/postgres/#{version}",
            source: {
              type: '.tool-versions',
              path: '/home/kdk/.tool-versions'
            },
            installed: true,
            active: true
          }
        end.to_json
      end

      let(:version_list_double) { kdk_shellout_double(try_run: result) }

      before do
        allow(KDK::Dependencies).to receive_messages(tool_version_manager_available?: true, tool_version_manager_available_versions: [13, 14, 15])

        shellout_double = kdk_shellout_double(try_run: '', exit_code: 0)

        allow_kdk_shellout_command(anything).and_return(shellout_double)
        allow_kdk_shellout_command(%w[mise list --current --installed --json postgres]).and_return(version_list_double)
      end

      describe '#bin_path' do
        it 'returns latest version' do
          expect(subject.bin_path).to eq('/home/.local/share/mise/installs/postgres/16.11/bin')
        end
      end

      describe '#bin_path_or_fallback' do
        it 'returns latest version' do
          expect(subject.bin_path_or_fallback).to eq('/home/.local/share/mise/installs/postgres/16.11/bin')
        end
      end

      context 'when upgrade is needed' do
        it 'performs a successful upgrade' do
          expect { subject.upgrade! }.to output(/Upgraded/).to_stdout
        end
      end

      context 'when upgrade is not needed' do
        before do
          allow(subject).to receive(:upgrade_needed?).and_return(false)
        end

        it 'does not perform an upgrade' do
          expect { subject.upgrade! }.to output(/already compatible/).to_stdout
        end
      end
    end
  end
end
