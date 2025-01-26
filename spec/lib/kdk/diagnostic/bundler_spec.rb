# frozen_string_literal: true

RSpec.describe KDK::Diagnostic::Bundler do
  include ShelloutHelper

  let(:khulnasoft_dir) { Pathname.new('/home/git/kdk/khulnasoft') }

  describe '#success?' do
    context "when khulnasoft doesn't have BUNDLE_PATH configured" do
      it 'returns true' do
        expect_bundle_path_not_set(khulnasoft_dir)

        expect(subject).to be_success
      end
    end
  end

  describe '#detail' do
    context "when khulnasoft doesn't have BUNDLE_PATH configured" do
      it 'returns no message' do
        expect_bundle_path_not_set(khulnasoft_dir)

        expect(subject.detail).to be_nil
      end
    end
  end

  def expect_bundle_path_not_set(chdir)
    expect_shellout(chdir, stdout: 'You have not configured a value for `PATH`')
  end

  def expect_bundle_path_set(chdir)
    expect_shellout(chdir, stdout: 'Set for your local app (<path>/.bundle/config): "vendor/bundle"')
  end

  def expect_shellout(chdir, success: true, stdout: '', stderr: '')
    # rubocop:todo RSpec/VerifiedDoubles
    shellout = double('KDK::Shellout', try_run: nil, read_stdout: stdout, read_stderr: stderr, success?: success)
    # rubocop:enable RSpec/VerifiedDoubles
    expect_kdk_shellout_command('bundle config get PATH', chdir: chdir).and_return(shellout)
    expect(shellout).to receive(:execute).with(display_output: false).and_return(shellout)
  end
end
