# frozen_string_literal: true

RSpec.describe Utils do
  include ShelloutHelper

  let(:tmp_path) { Dir.mktmpdir('kdk-path') }

  before do
    unstub_find_executable
    stub_env('PATH', tmp_path)
  end

  after do
    FileUtils.rm_rf(tmp_path)
  end

  describe '.find_executable' do
    it 'returns the full path of the executable' do
      executable = create_dummy_executable('dummy')

      expect(described_class.find_executable('dummy')).to eq(executable)
    end

    it 'returns nil when executable cant be found' do
      expect(described_class.find_executable('non-existent')).to be_nil
    end

    it 'also finds by absolute path' do
      executable = create_dummy_executable('dummy')

      expect(described_class.find_executable(executable)).to eq(executable)
    end
  end

  describe '.executable_exist?' do
    it 'returns true if an executable exists in the PATH' do
      create_dummy_executable('dummy')

      expect(described_class.executable_exist?('dummy')).to be_truthy
    end

    it 'returns false when no exectuable can be found' do
      expect(described_class.executable_exist?('non-existent')).to be_falsey
    end
  end

  describe '.executable_exist_via_tooling_manager?' do
    let(:binary_name) { "ruby" }

    context "when mise is available" do
      before do
        stub_kdk_yaml <<~YAML
            mise:
              enabled: true
            asdf:
              opt_out: true
        YAML

        allow(described_class).to receive(:executable_exist?).with('mise').and_return(true)
      end

      it 'returns the tooling manager path to the executable' do
        expect_kdk_shellout_command(%W[mise which #{binary_name}]).and_return(
          kdk_shellout_double(success?: true).tap { |sh| expect(sh).to receive(:execute).and_return(sh) }
        )

        expect(described_class.executable_exist_via_tooling_manager?(binary_name)).to be(true)
      end
    end

    context 'when no tooling manager is used' do
      before do
        stub_kdk_yaml <<~YAML
            mise:
              enabled: false
            asdf:
              opt_out: true
        YAML
      end

      it 'returns the result of `find_executable`' do
        expect(described_class.executable_exist_via_tooling_manager?(binary_name)).to eq(
          described_class.executable_exist?(binary_name)
        )
      end
    end
  end

  describe '.prefix_command' do
    let(:command) { %w[command arg1 arg2] }
    let(:mise_enabled) { tooling_manager == 'mise' }
    let(:asdf_opt_out) { tooling_manager == 'mise' }

    before do
      stub_kdk_yaml <<~YAML
          mise:
            enabled: #{mise_enabled}
          asdf:
            opt_out: #{asdf_opt_out}
      YAML

      allow(described_class).to receive(:executable_exist?).with(tooling_manager).and_return(true)
    end

    context 'when mise is used' do
      let(:tooling_manager) { 'mise' }

      it 'returns the command with mise prefix' do
        expect(described_class.prefix_command(*command)).to eq(%w[mise exec --] + command)
      end
    end

    context 'when mise is not used' do
      let(:tooling_manager) { nil }
      let(:mise_enabled) { false }
      let(:asdf_opt_out) { true }

      it 'returns the command without any prefix' do
        expect(described_class.prefix_command(*command)).to eq(command)
      end
    end
  end

  describe '.precompiled_ruby?' do
    before do
      allow(RbConfig::CONFIG).to receive(:[]).with('configure_args').and_return(configure_args)
    end

    context 'in a locally compiled ruby version' do
      let(:configure_args) { " '--prefix=/Users/kev/.local/share/mise/installs/ruby/3.3.8' '--with-openssl-dir=/opt/homebrew/opt/openssl@3' '--enable-shared' '--with-libyaml-dir=/opt/homebrew/opt/libyaml' '--with-gmp-dir=/opt/homebrew/opt/gmp' '--with-ext=openssl,psych,+' 'CC=clang'" }

      it 'returns false' do
        expect(described_class.precompiled_ruby?).to be(false)
      end
    end

    context 'in a precompiled ruby version' do
      let(:configure_args) { "'--prefix=/Users/khulnasoft/.local/share/mise/installs/ruby/3.3.9' '--with-openssl-dir=/opt/homebrew/opt/openssl@3' '--with-libyaml-dir=/opt/homebrew/opt/libyaml' '--with-gmp-dir=/opt/homebrew/opt/gmp' '--with-ext=openssl,psych,+' '--disable-shared' '--enable-load-relative' '--enable-yjit' 'KHULNASOFT_PRECOMPILED=1' 'CC=clang'" }

      it 'returns true' do
        expect(described_class.precompiled_ruby?).to be(true)
      end
    end
  end
end
