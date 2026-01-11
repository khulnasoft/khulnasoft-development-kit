# frozen_string_literal: true

RSpec.describe KDK::Command::Predictive do
  let(:kdk_predictive) { described_class.new }
  let(:predictive_rspec) { KDK::Predictive::Rspec.new }
  let(:predictive_jest) { KDK::Predictive::Jest.new }
  let(:args) { [] }

  subject { kdk_predictive.run(args) }

  describe '#run' do
    before do
      allow(KDK::Predictive::Rspec).to receive(:new).and_return(predictive_rspec)
      allow(KDK::Predictive::Jest).to receive(:new).and_return(predictive_jest)
    end

    context 'when no arguments are provided' do
      it 'runs both rspec and jest predictive tests' do
        expect(predictive_rspec).to receive(:execute).with(force: false).and_return(true)
        expect(predictive_jest).to receive(:execute).and_return(true)

        expect(subject).to be(true)
      end
    end

    context 'when --rspec argument is provided' do
      let(:args) { ['--rspec'] }

      it 'runs only rspec predictive tests' do
        expect(predictive_rspec).to receive(:execute).with(force: false).and_return(true)
        expect(predictive_jest).not_to receive(:execute)

        expect(subject).to be(true)
      end

      context 'when forcing execution' do
        let(:args) { ['--rspec', '--yes'] }

        it 'runs only rspec predictive tests with force flag' do
          expect(predictive_rspec).to receive(:execute).with(force: true).and_return(true)
          expect(predictive_jest).not_to receive(:execute)

          expect(subject).to be(true)
        end
      end
    end

    context 'when --jest argument is provided' do
      let(:args) { ['--jest'] }

      it 'runs only jest predictive tests' do
        expect(predictive_rspec).not_to receive(:execute)
        expect(predictive_jest).to receive(:execute).and_return(true)

        expect(subject).to be(true)
      end
    end

    context 'when only the rspec execution is forced' do
      let(:args) { ['--yes'] }

      it 'runs both rspec and jest predictive tests' do
        expect(predictive_rspec).to receive(:execute).with(force: true).and_return(true)
        expect(predictive_jest).to receive(:execute).and_return(true)

        expect(subject).to be(true)
      end
    end

    context 'when there is an execution error with rspec' do
      let(:error_message) { 'Failed to find RSpec tests' }
      let(:runtime_error) { RuntimeError.new(error_message) }

      before do
        allow(predictive_rspec).to receive(:execute).with(force: false).and_raise(runtime_error)
      end

      it 'outputs an error for rspec' do
        expect(KDK::Output).to receive(:error).with("RSpec test execution failed: #{error_message}", runtime_error, report_error: true)
        expect(predictive_jest).to receive(:execute).and_return(true)

        expect(subject).to be(false)
      end
    end

    context 'when there is an execution error with jest' do
      let(:error_message) { 'Failed to find Jest tests' }
      let(:runtime_error) { RuntimeError.new(error_message) }

      before do
        allow(predictive_jest).to receive(:execute).and_raise(runtime_error)
      end

      it 'outputs an error for jest' do
        expect(predictive_rspec).to receive(:execute).with(force: false).and_return(true)
        expect(KDK::Output).to receive(:error).with("Jest test execution failed: #{error_message}", runtime_error, report_error: true)

        expect(subject).to be(false)
      end
    end
  end
end
