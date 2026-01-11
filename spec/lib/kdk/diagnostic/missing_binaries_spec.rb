# frozen_string_literal: true

RSpec.describe KDK::Diagnostic::MissingBinaries do
  subject(:diagnostic) { described_class.new }

  let(:binary_config) { { download_paths: ['/path/to/binary'] } }
  let(:specific_binary_config) do
    {
      gitaly: { download_paths: ['/path/to/gitaly'] },
      khulnasoft_shell: { download_paths: ['/path/to/khulnasoft_shell'] },
      workhorse: { download_paths: ['/path/to/workhorse'] },
      graphql_schema: { download_paths: ['/path/to/graphql_schema'] }
    }
  end

  let(:expected_all_missing_message) do
    <<~MESSAGE
      The following KhulnaSoft binaries are missing from their expected paths:
        gitaly
        khulnasoft_shell
        workhorse
        kdk_preseeded_db

      Please ensure you download them by running:
        make gitaly-setup
        make khulnasoft-shell-setup
        make khulnasoft-workhorse-setup

      The following external binaries are missing from their expected paths:
        git
        nginx
        sshd
        postgresql

      Please ensure these are installed on your system by running:
        kdk update
    MESSAGE
  end

  let(:openbao_enabled_yaml) do
    <<~YAML
      openbao:
        enabled: true
    YAML
  end

  let(:openbao_disabled_yaml) do
    <<~YAML
      openbao:
        enabled: false
    YAML
  end

  before do
    allow(File).to receive_messages(exist?: true, executable?: true)

    allow(KDK::PackageConfig).to receive(:project).and_return(binary_config)
    stub_kdk_yaml(openbao_disabled_yaml)
  end

  shared_examples 'detects missing binary' do |binary_name, setup_command|
    it "detects missing #{binary_name} and suggests #{setup_command}" do
      expect(diagnostic.success?).to be false
      expect(diagnostic.detail).to include(binary_name.to_s)
      expect(diagnostic.detail).to include(setup_command)
    end
  end

  describe '#success?' do
    context 'when all required binaries exist and are executable' do
      before do
        mock_all_binaries_exist
      end

      it 'returns true' do
        expect(diagnostic.success?).to be true
      end
    end

    context 'when some binaries are missing' do
      before do
        mock_all_binaries_missing
      end

      it 'returns false' do
        expect(diagnostic.success?).to be false
      end
    end

    context 'when khulnasoft-workhorse file exists' do
      before do
        mock_specific_binary_paths
      end

      it 'returns true' do
        expect(diagnostic.success?).to be true
      end
    end

    context 'when no khulnasoft-* files found' do
      before do
        mock_specific_binary_paths
        allow(Dir).to receive(:glob).with('/path/to/workhorse/khulnasoft-*').and_return([])
      end

      it 'returns false' do
        expect(diagnostic.success?).to be false
      end
    end

    context 'when graphql_schema special handling' do
      before do
        mock_specific_binary_paths
      end

      it 'always returns true regardless of file existence' do
        allow(File).to receive(:exist?).with('/path/to/graphql_schema').and_return(false)
        allow(File).to receive(:executable?).with('/path/to/graphql_schema').and_return(false)

        expect(diagnostic.success?).to be true
      end
    end

    context 'when OpenBao is enabled' do
      before do
        stub_kdk_yaml(openbao_enabled_yaml)
        mock_all_binaries_exist
      end

      it 'returns false when OpenBao binary is missing' do
        allow(File).to receive(:exist?).with('/path/to/binary').and_return(false)

        expect(diagnostic.success?).to be false
      end
    end

    context 'when OpenBao is disabled' do
      before do
        stub_kdk_yaml(openbao_disabled_yaml)
        mock_all_binaries_exist
      end

      it 'returns true even when OpenBao binary would be missing' do
        expect(diagnostic.success?).to be true
      end
    end
  end

  describe '#detail' do
    context 'when all required binaries exist' do
      before do
        mock_all_binaries_exist
      end

      it 'returns nil' do
        expect(diagnostic.detail).to be_nil
      end
    end

    context 'when binaries are missing' do
      context 'when all binaries are missing' do
        before do
          mock_all_binaries_missing
        end

        it 'returns a message with missing binaries and setup instructions' do
          expect(diagnostic.detail.strip).to eq(expected_all_missing_message.strip)
        end
      end

      context 'when gitaly binary is missing' do
        before do
          mock_specific_binary_paths
          allow(File).to receive(:exist?).with('/path/to/gitaly').and_return(false)
          allow(File).to receive(:executable?).with('/path/to/gitaly').and_return(false)
        end

        include_examples 'detects missing binary', 'gitaly', 'make gitaly-setup'
      end

      context 'when khulnasoft_shell binary is missing' do
        before do
          mock_specific_binary_paths
          allow(File).to receive(:exist?).with('/path/to/khulnasoft_shell').and_return(false)
          allow(File).to receive(:executable?).with('/path/to/khulnasoft_shell').and_return(false)
        end

        include_examples 'detects missing binary', 'khulnasoft_shell', 'make khulnasoft-shell-setup'
      end

      context 'when workhorse binary is missing' do
        before do
          mock_specific_binary_paths
          allow(Dir).to receive(:glob).with('/path/to/workhorse/khulnasoft-*').and_return([])
        end

        include_examples 'detects missing binary', 'workhorse', 'make khulnasoft-workhorse-setup'
      end

      context 'when no khulnasoft-* files found' do
        before do
          mock_specific_binary_paths
          allow(Dir).to receive(:glob).with('/path/to/workhorse/khulnasoft-*').and_return([])
        end

        it 'includes workhorse in error message' do
          expect(diagnostic.detail).to include('workhorse')
        end
      end
    end

    context 'when graphql_schema special handling' do
      before do
        mock_specific_binary_paths
      end

      it 'always returns nil regardless of file existence' do
        allow(File).to receive(:exist?).with('/path/to/graphql_schema').and_return(false)
        allow(File).to receive(:executable?).with('/path/to/graphql_schema').and_return(false)

        expect(diagnostic.detail).to be_nil
      end
    end

    context 'when OpenBao is enabled and missing' do
      before do
        stub_kdk_yaml(openbao_enabled_yaml)
        mock_all_binaries_exist
      end

      it 'includes OpenBao in error message' do
        allow(File).to receive(:exist?).with('/path/to/binary').and_return(false)

        expect(diagnostic.detail).to include('openbao')
      end
    end

    context 'when OpenBao is disabled' do
      before do
        stub_kdk_yaml(openbao_disabled_yaml)
        mock_all_binaries_exist
      end

      it 'excludes OpenBao from error message' do
        allow(File).to receive(:exist?).with('/path/to/binary').and_return(false)

        expect(diagnostic.detail).not_to include('openbao')
      end
    end

    context 'when external binaries are missing' do
      let(:external_dependencies_yaml) do
        <<~YAML
          git:
            bin: "/usr/local/bin/git"
          nginx:
            enabled: true
            bin: "/usr/local/bin/nginx"
          postgresql:
            bin: "/usr/local/bin/postgres"
          sshd:
            enabled: true
            bin: "/usr/local/sbin/sshd"
        YAML
      end

      before do
        stub_kdk_yaml(external_dependencies_yaml)
        mock_all_binaries_exist
      end

      it 'includes external binaries in error message when missing' do
        git_path = Pathname.new('/usr/local/bin/git')
        allow(File).to receive(:exist?).with(git_path).and_return(false)

        expect(diagnostic.detail).to include('git')
        expect(diagnostic.detail).to include('external')
        expect(diagnostic.detail).to include('kdk update')
      end
    end
  end

  private

  def mock_all_binaries_exist
    mock_generic_binary_files
    mock_workhorse_files
  end

  def mock_all_binaries_missing
    allow(File).to receive_messages(exist?: false, executable?: false)
    allow(Dir).to receive(:glob).and_return([])
  end

  def mock_specific_binary_paths
    setup_specific_binary_configs
    setup_default_file_mocks
    setup_specific_workhorse_mocks
  end

  def mock_generic_binary_files
    allow(File).to receive(:exist?).with('/path/to/binary').and_return(true)
    allow(File).to receive(:executable?).with('/path/to/binary').and_return(true)
  end

  def mock_workhorse_files
    allow(Dir).to receive(:glob).with('/path/to/binary/khulnasoft-*')
                                .and_return(['/path/to/binary/khulnasoft-workhorse'])
    allow(File).to receive(:exist?)
      .with('/path/to/binary/khulnasoft-workhorse').and_return(true)
    allow(File).to receive(:executable?)
      .with('/path/to/binary/khulnasoft-workhorse').and_return(true)
  end

  def setup_specific_binary_configs
    specific_binary_config.each do |binary, config|
      allow(KDK::PackageConfig).to receive(:project).with(binary).and_return(config)
    end
  end

  def setup_default_file_mocks
    allow(File).to receive_messages(exist?: true, executable?: true)
  end

  def setup_specific_workhorse_mocks
    allow(Dir).to receive(:glob).with('/path/to/workhorse/khulnasoft-*')
                                .and_return(['/path/to/workhorse/khulnasoft-workhorse'])
    allow(File).to receive(:exist?)
      .with('/path/to/workhorse/khulnasoft-workhorse').and_return(true)
    allow(File).to receive(:executable?)
      .with('/path/to/workhorse/khulnasoft-workhorse').and_return(true)
  end
end
