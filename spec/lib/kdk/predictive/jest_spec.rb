# frozen_string_literal: true

RSpec.describe KDK::Predictive::Jest do
  include ShelloutHelper

  let(:args) { [] }
  let(:all_changed_files) { [] }
  let(:predictive_jest) { described_class.new }

  subject { predictive_jest.execute(args) }

  describe '#execute' do
    before do
      allow(predictive_jest).to receive(:all_changed_files).and_return(all_changed_files)
    end

    context 'when changed files are empty' do
      it 'prints the no changes found message' do
        expect_output(:info, message: 'No changes were detected in JavaScript files. Nothing to do.')

        expect(subject).to be(true)
      end
    end

    context 'when changed files are present' do
      let(:all_changed_files) { ['app/models/user.rb', 'app/assets/javascripts/components/example.vue'] }
      let(:tests_finished_message) { 'Tests run successfully!' }
      let(:download_and_extract_fixtures_message) { 'Downloaded and extracted frontend fixtures.' }
      let(:changed_js_files) do
        all_changed_files.select { |file| file.end_with?('.js', '.cjs', '.mjs', '.vue', '.graphql') }.uniq
      end

      before do
        allow(predictive_jest).to receive_messages(
          download_and_extract_fixtures: download_and_extract_fixtures_message,
          run_jest_related_tests: true
        )
      end

      it 'downloads fixtures and runs tests' do
        expect_output(:info, message: "Detected changes in JavaScript files:\n#{changed_js_files}")

        expect(subject).to be(true)
      end
    end
  end

  def expect_output(level, message: nil)
    expect(KDK::Output).to receive(level).with(message || no_args)
  end
end
