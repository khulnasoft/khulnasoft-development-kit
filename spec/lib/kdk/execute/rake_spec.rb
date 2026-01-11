# frozen_string_literal: true

RSpec.describe KDK::Execute::Rake do
  include ShelloutHelper

  let(:shellout_mock) { kdk_shellout_double }

  subject(:rake) { described_class.new('list:of:tasks', 'other:task') }

  describe '#execute_in_kdk' do
    context 'with mocked shellout' do
      before do
        allow_kdk_shellout.and_return(shellout_mock)
        allow(shellout_mock).to receive(:execute).and_return(shellout_mock)
      end

      context 'when mise is available' do
        it "rake command starts with 'mise exec --'" do
          allow(KDK::Dependencies).to receive(:tool_version_manager_available?).and_return(true)

          expect_kdk_shellout.with(start_with('mise', 'exec', '--'), any_args).and_return(shellout_mock)

          rake.execute_in_kdk
        end
      end

      context 'when mise is not available' do
        it "rake command does not start with 'mise exec --'" do
          allow(KDK::Dependencies).to receive(:tool_version_manager_available?).and_return(false)

          expect_kdk_shellout.with(array_including('bundle', 'exec'), any_args).and_return(shellout_mock)

          rake.execute_in_kdk
        end
      end

      it 'runs rake command with the defined tasks' do
        expect_kdk_shellout
          .with(array_including('bundle', 'exec', 'rake', 'list:of:tasks', 'other:task'), any_args)
          .and_return(shellout_mock)

        rake.execute_in_kdk
      end
    end

    context 'with integration test' do
      subject(:rake) { described_class.new('--version') } # valid command that has no side-effect

      it 'allows passing extra parameters to shellout and runs with success' do
        allow(KDK::Dependencies).to receive(:asdf_available?).and_return(false)
        rake.execute_in_kdk(display_output: false)

        expect(rake.success?).to be_truthy
      end
    end
  end

  describe '#execute_in_khulnasoft' do
    context 'with mocked shellout' do
      before do
        allow_kdk_shellout.and_return(shellout_mock)
        allow(shellout_mock).to receive(:execute).and_return(shellout_mock)
      end

      context 'when Bundler is loaded' do
        it 'clears out bundler environment' do
          expect(KDK::Dependencies).to receive(:bundler_loaded?).and_return(true)

          expect(Bundler).to receive(:with_unbundled_env).and_yield

          rake.execute_in_khulnasoft
        end
      end

      context 'when Bundler is not loaded' do
        it 'does not clear out bundler environment' do
          expect(KDK::Dependencies).to receive(:bundler_loaded?).and_return(false)

          expect(Bundler).not_to receive(:with_unbundled_env)

          rake.execute_in_khulnasoft
        end
      end

      context 'when mise is available' do
        it "rake command starts with 'mise exec --'" do
          allow(KDK::Dependencies).to receive(:tool_version_manager_available?).and_return(true)

          expect_kdk_shellout.with(start_with('mise', 'exec', '--'), any_args).and_return(shellout_mock)

          rake.execute_in_khulnasoft
        end
      end

      context 'when mise is not available' do
        it "rake command does not start with 'mise exec --'" do
          allow(KDK::Dependencies).to receive(:tool_version_manager_available?).and_return(false)

          expect_kdk_shellout.with(array_including('bundle', 'exec'), any_args).and_return(shellout_mock)

          rake.execute_in_khulnasoft
        end
      end

      it 'runs rake command with the defined tasks' do
        expect_kdk_shellout
          .with(array_including('bundle', 'exec', 'rake', 'list:of:tasks', 'other:task'), any_args)
          .and_return(shellout_mock)

        rake.execute_in_khulnasoft
      end
    end

    context 'with integration test' do
      subject(:rake) { described_class.new('some', 'tasks') } # valid command that has no side-effect

      it 'allows passing extra parameters to shellout and runs with success' do
        allow(rake).to receive(:rake_command).and_return(%w[echo rake some tasks])
        stub_kdk_yaml({
          'khulnasoft' => {
            'dir' => KDK.root
          }
        })

        rake.execute_in_khulnasoft(display_output: false)

        expect(rake.success?).to be_truthy
      end
    end

    context 'with environment variables' do
      subject(:rake_with_env) { described_class.new('khulnasoft:duo:setup', env: { 'KHULNASOFT_SIMULATE_SAAS' => '1' }) }

      before do
        allow_kdk_shellout.and_return(shellout_mock)
        allow(shellout_mock).to receive(:execute).and_return(shellout_mock)
      end

      it 'passes environment variables to shellout' do
        expect_kdk_shellout.with(array_including('bundle', 'exec', 'rake', 'khulnasoft:duo:setup'), hash_including(env: { 'KHULNASOFT_SIMULATE_SAAS' => '1' })).and_return(shellout_mock)

        rake_with_env.execute_in_khulnasoft
      end
    end
  end

  describe '#success?' do
    subject(:rake) { described_class.new('--version') } # valid command that has no side-effect

    context 'with a successful rake execution' do
      it 'returns true' do
        allow(KDK::Dependencies).to receive(:asdf_available?).and_return(false)
        allow(shellout_mock).to receive(:success?).and_return(true)

        rake.execute_in_kdk(display_output: false)

        expect(rake.success?).to be_truthy
      end
    end

    context 'with a failed rake execution', :hide_output do
      subject(:rake) { described_class.new('--invalid') } # valid command that has no side-effect

      it 'returns false when a previous execution failed' do
        allow(shellout_mock).to receive(:success?).and_return(false)

        rake.execute_in_kdk(display_output: false)

        expect(rake.success?).to be_falsey
      end
    end

    it 'returns false when no execution was done before' do
      expect(rake.success?).to be_falsey
    end
  end

  describe '#stderr_output' do
    let(:stderr_content) { 'Error: Something went wrong' }

    before do
      allow_kdk_shellout.and_return(shellout_mock)
      allow(shellout_mock).to receive_messages(execute: shellout_mock, read_stderr: stderr_content)
    end

    context 'after executing in KDK' do
      it 'returns stderr content from the shellout instance' do
        rake.execute_in_kdk

        expect(rake.stderr_output).to eq(stderr_content)
      end
    end

    context 'after executing in KhulnaSoft' do
      it 'returns stderr content from the shellout instance' do
        rake.execute_in_khulnasoft

        expect(rake.stderr_output).to eq(stderr_content)
      end
    end

    context 'when no execution was done before' do
      it 'returns nil' do
        expect(rake.stderr_output).to be_nil
      end
    end

    context 'when shellout instance is nil' do
      before do
        allow_kdk_shellout.and_return(shellout_mock)
      end

      it 'returns nil' do
        expect(rake.stderr_output).to be_nil
      end
    end
  end
end
