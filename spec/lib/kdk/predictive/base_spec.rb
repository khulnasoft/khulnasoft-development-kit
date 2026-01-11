# frozen_string_literal: true

RSpec.describe KDK::Predictive::Base do
  include ShelloutHelper

  let(:predictive_base) { described_class.new }

  describe '.out' do
    it 'returns KDK::Output' do
      expect(predictive_base.out).to be(KDK::Output)
    end
  end

  describe '.all_changed_files' do
    let(:local_changes_shellout_double) { kdk_shellout_double(run: "local_changed_file.rb") }
    let(:comitted_changes_shellout_double) { kdk_shellout_double(run: "comitted_changed_file.rb") }

    before do
      allow_kdk_shellout_command('git diff --name-only -z', chdir: KDK.config.khulnasoft.dir)
        .and_return(local_changes_shellout_double)
      allow_kdk_shellout_command('git diff origin/master...HEAD --name-only -z', chdir: KDK.config.khulnasoft.dir)
        .and_return(comitted_changes_shellout_double)
    end

    it 'returns an array of changed files' do
      expect(predictive_base.all_changed_files).to eq(%w[local_changed_file.rb comitted_changed_file.rb])
    end
  end

  describe '.khulnasoft_dir' do
    it 'returns the KhulnaSoft directory' do
      expect(predictive_base.khulnasoft_dir).to eq(KDK.config.khulnasoft.dir)
    end
  end

  describe '.shellout' do
    let(:cmd) { 'example command' }

    before do
      allow_kdk_shellout_command(cmd, any_args).and_raise('halt and catch fire')
    end

    it 'displays the error message and continues' do
      expect { predictive_base.shellout(cmd) }.to raise_error('Failed to execute shell command: halt and catch fire')
    end
  end
end
