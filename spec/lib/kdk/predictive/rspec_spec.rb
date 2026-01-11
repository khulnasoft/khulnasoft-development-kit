# frozen_string_literal: true

RSpec.describe KDK::Predictive::Rspec do
  include ShelloutHelper

  let(:force) { false }
  let(:all_changed_files) { [] }
  let(:predictive_rspec) { described_class.new }

  subject { predictive_rspec.execute(force: force) }

  describe '#execute' do
    before do
      allow(predictive_rspec).to receive(:all_changed_files).and_return(all_changed_files)
    end

    context 'when changed files are empty' do
      it 'prints the no changes found message' do
        expect_output(:info, message: 'No changes detected. No tests will be run.')

        expect(subject).to be(true)
      end
    end

    context 'when changed files are present' do
      let(:all_changed_files) { ['app/models/user.rb'] }
      let(:changed_files) { all_changed_files.uniq.join("\n") }

      before do
        allow(predictive_rspec).to receive_messages(
          retrieve_static_test_mapping: static_test_mapping,
          retrieve_crystalball_described_class_mapping: crystalball_described_class_mapping
        )
      end

      context 'when test mappings are empty' do
        let(:static_test_mapping) { '' }
        let(:crystalball_described_class_mapping) { '' }

        it 'warns about not finding related tests' do
          expect_output(:warn, message: "No tests related to the following changes were found:\n#{changed_files}")

          expect(subject).to be(true)
        end
      end

      context 'when test mappings contain tests' do
        let(:static_test_mapping) { 'spec/models/user_spec.rb' }
        let(:crystalball_described_class_mapping) { 'spec/models/every_model_spec.rb spec/models/user_spec.rb' }
        let(:test_mapping) { ([static_test_mapping] | crystalball_described_class_mapping.split).join("\n") }
        let(:knapsack_report) { { 'spec/models/user_spec.rb' => 0.05, 'spec/models/every_model_spec.rb' => 0.1 } }

        before do
          allow(predictive_rspec).to receive_messages(
            knapsack_report: knapsack_report,
            run_predicted_tests: true
          )
        end

        context 'with confirmation' do
          it 'prompts for confirmation before running the tests' do
            expect_output(:puts, message: "Testing against\n#{test_mapping}\nbased on the changes detected in the following files:\n#{changed_files}")
            expect_output(:puts, message: 'The estimated runtime of the tests is: 150ms.')
            expect_output(:warn, message: 'If you are running tests for the first time, the setup might take a while.')
            stub_prompt('y', "Are you sure you want to continue? [y/N]")
            expect_output(:puts, message: 'Running predicted tests ...')

            expect(subject).to be(true)
          end
        end

        context 'when confirmation is skipped' do
          let(:force) { true }

          it 'skips the confirmation before running the tests' do
            expect_output(:puts, message: "Testing against\n#{test_mapping}\nbased on the changes detected in the following files:\n#{changed_files}")
            expect_output(:puts, message: 'The estimated runtime of the tests is: 150ms.')
            expect_output(:warn, message: 'If you are running tests for the first time, the setup might take a while.')
            expect_output(:puts, message: 'Running predicted tests ...')

            expect(subject).to be(true)
          end
        end

        context 'when expected runtime is under the threshold' do
          let(:knapsack_report) { { 'spec/models/user_spec.rb' => 0.05 } }

          it 'skips the confirmation before running the tests' do
            expect_output(:puts, message: "Testing against\n#{test_mapping}\nbased on the changes detected in the following files:\n#{changed_files}")
            expect_output(:puts, message: 'The estimated runtime of the tests is: 50ms.')
            expect_output(:warn, message: 'If you are running tests for the first time, the setup might take a while.')
            expect_output(:puts, message: 'Running predicted tests ...')

            expect(subject).to be(true)
          end
        end
      end
    end
  end

  def expect_output(level, message: nil)
    expect(KDK::Output).to receive(level).with(message || no_args)
  end
end
