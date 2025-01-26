# frozen_string_literal: true

RSpec.describe KDK::Diagnostic::GitMaintenance do
  include ShelloutHelper

  let(:maintenance_repos) { [] }

  subject { described_class.new }

  before do
    stub_kdk_yaml({})

    sh = kdk_shellout_double
    allow_kdk_shellout_command('git config --global --get-all maintenance.repo').once.and_return(sh)

    allow(sh).to receive(:execute).with(display_output: false, display_error: false).and_return(sh)
    allow(sh).to receive(:read_stdout).and_return(maintenance_repos.join("\n"))
  end

  describe '#success?' do
    describe 'when no repo has maintenance enabled' do
      it { expect(subject.success?).to be(false) }
    end

    describe 'when one repo has maintenance enabled' do
      let(:maintenance_repos) { [KDK.config.kdk_root] }

      it { expect(subject.success?).to be(false) }
    end

    describe 'when all repos have maintenance enabled' do
      let(:maintenance_repos) { [KDK.config.kdk_root, KDK.config.khulnasoft.dir] }

      it { expect(subject.success?).to be(true) }
    end
  end

  describe '#detail' do
    describe 'when no repo has maintenance enabled' do
      it 'returns a message' do
        expect(subject.detail).to eq(
          <<~MESSAGE
          We recommend enabling git-maintenance to avoid slowdowns of local git operations like fetch, pull, and checkout.

          To enable it, run `git maintenance start` in each repository:

          git -C #{KDK.config.kdk_root} maintenance start
          git -C #{KDK.config.khulnasoft.dir} maintenance start
          MESSAGE
        )
      end
    end

    describe 'when one repo has maintenance enabled' do
      let(:maintenance_repos) { [KDK.config.kdk_root] }

      it 'returns a message without that repo' do
        expect(subject.detail).to eq(
          <<~MESSAGE
          We recommend enabling git-maintenance to avoid slowdowns of local git operations like fetch, pull, and checkout.

          To enable it, run `git maintenance start` in each repository:

          git -C #{KDK.config.khulnasoft.dir} maintenance start
          MESSAGE
        )
      end
    end

    describe 'when all repos have maintenance enabled' do
      let(:maintenance_repos) { [KDK.config.kdk_root, KDK.config.khulnasoft.dir] }

      it { expect(subject.detail).to be_nil }
    end
  end
end
